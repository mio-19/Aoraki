class Tasks::MsmFbNotify < SingletonTask
  def initialize()
    Targets[:SwitchRoot].add_dependency(:Task, self)
    add_dependency(:Mount, "/sys")
  end

  def run()
    path = "/sys/class/graphics/fb0/blank"
    System.write(path, "0") if File.exist?(path)
  end
end
