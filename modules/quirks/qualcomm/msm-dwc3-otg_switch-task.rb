class Tasks::MsmDwc3OtgSwitch < SingletonTask
  def initialize()
    Targets[:SwitchRoot].add_dependency(:Task, self)
    add_dependency(:Mount, "/sys")
  end

  def run()
    path = "/sys/module/dwc3_msm/parameters/otg_switch"
    System.write(path, "1") if File.exist?(path)
  end
end
