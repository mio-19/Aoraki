# Runs udev daemon
class Tasks::UDev < SingletonTask
  def initialize()
    add_dependency(:Target, :Environment)
    add_dependency(:Mount, "/dev")
    add_dependency(:Mount, "/proc")
    add_dependency(:Mount, "/run")
    add_dependency(:Mount, "/sys")

    # Make the Devices target depend on this task.
    # It is preferred to depend on the specific device rather than this target.
    Targets[:Devices].add_dependency(:Task, self)
    Targets[:SwitchRoot].add_dependency(:Task, self)

    # May be required for input
    Targets[:Graphics].add_dependency(:Task, self)
  end

  def udevadm(*args)
    System.run("udevadm", *args)
  end

  def run()
    udevd

    # Immediately ensure partition links from devtmpfs
    ensure_partition_links

    # Subsystem-filtered trigger: avoids synthetic Android nodes (e.g. android_usb) that reject uevents with EINVAL
    begin
      udevadm("trigger", "--action=add", "--subsystem-match=block", "--subsystem-match=input", "--subsystem-match=graphics")
    rescue System::CommandError => e
      $logger.warn("udevadm trigger non-fatal warning (proceeding): #{e.message}")
    end

    # Fast settle on watches: don't block for 10s if partition is already available
    if File.exist?("/dev/disk/by-label/NIXOS_SYSTEM")
      begin
        udevadm("settle", "--timeout=1")
      rescue System::CommandError
      end
    else
      begin
        udevadm("settle", "--timeout=5")
      rescue System::CommandError => e
        $logger.warn("udevadm settle non-fatal timeout (proceeding): #{e.message}")
      end
      ensure_partition_links
    end
  end

  # TODO: Temporary workaround until udev rules reliably parse GPT/Android partition tables on 4.14 downstream kernels.
  # Ensures /dev/disk/by-label/NIXOS_SYSTEM and /dev/disk/by-partlabel/userdata point to the userdata block device.
  def ensure_partition_links()
    FileUtils.mkdir_p("/dev/disk/by-partlabel")
    FileUtils.mkdir_p("/dev/disk/by-label")

    if File.exist?("/dev/mmcblk0p50")
      unless File.exist?("/dev/disk/by-partlabel/userdata")
        System.symlink("/dev/mmcblk0p50", "/dev/disk/by-partlabel/userdata")
      end
      unless File.exist?("/dev/disk/by-label/NIXOS_SYSTEM")
        System.symlink("/dev/mmcblk0p50", "/dev/disk/by-label/NIXOS_SYSTEM")
      end
    end

    Dir.glob("/sys/class/block/*/uevent").each do |uevent|
      content = File.read(uevent) rescue ""
      if content.include?("PARTNAME=userdata")
        devname = content[/DEVNAME=(\S+)/, 1]
        if devname && File.exist?("/dev/#{devname}")
          unless File.exist?("/dev/disk/by-partlabel/userdata")
            System.symlink("/dev/#{devname}", "/dev/disk/by-partlabel/userdata")
          end
          unless File.exist?("/dev/disk/by-label/NIXOS_SYSTEM")
            System.symlink("/dev/#{devname}", "/dev/disk/by-label/NIXOS_SYSTEM")
          end
        end
      end
    end

    if File.exist?("/dev/disk/by-partlabel/userdata") && !File.exist?("/dev/disk/by-label/NIXOS_SYSTEM")
      System.symlink("/dev/disk/by-partlabel/userdata", "/dev/disk/by-label/NIXOS_SYSTEM")
    end
  end

  def udevd()
    *args = []
    args << "--debug" if debug?
    System.run("systemd-udevd", "--daemon", *args)
    20.times do
      break if File.exist?("/run/udev/control")
      sleep(0.1)
    end
  end

  # TODO: Allow configuring its debug state
  def debug?
    false
  end

  def teardown()
    udevadm("control", "--exit")
  end
end
