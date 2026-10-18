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
    begin
      udevadm("trigger", "--action=add", "--wait-daemon")
    rescue System::CommandError => e
      $logger.warn("udevadm trigger non-fatal warning (ignored): #{e.message}")
    end
    begin
      udevadm("settle", "--timeout=10")
    rescue System::CommandError => e
      $logger.warn("udevadm settle non-fatal warning (ignored): #{e.message}")
    end
  end

  def udevd()
    *args = []
    args << "--debug" if debug?
    System.run("systemd-udevd", "--daemon", *args)
  end

  # TODO: Allow configuring its debug state
  def debug?
    false
  end

  def teardown()
    begin
      udevadm("control", "--exit")
    rescue System::CommandError => e
      $logger.warn("udevadm exit non-fatal warning (ignored): #{e.message}")
    end
  end
end
