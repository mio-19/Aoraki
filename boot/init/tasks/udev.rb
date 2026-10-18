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
    udevadm("trigger", "--action=add")
    begin
      udevadm("settle", "--timeout=10")
    rescue System::CommandError => e
      $logger.warn("udevadm settle non-fatal timeout (proceeding): #{e.message}")
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
