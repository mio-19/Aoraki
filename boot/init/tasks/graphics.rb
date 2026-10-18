# Ensures graphics have been initialized and are ready to be used.
# Supports both legacy fbdev (/sys/class/graphics/fb0, /dev/fb0) and modern DRM (/dev/dri/card0).
class Tasks::Graphics < SingletonTask
  def initialize()
    add_dependency(
      :Any,
      Dependencies::Files.new("/sys/class/graphics/fb0"),
      Dependencies::Files.new("/dev/fb0"),
      Dependencies::Files.new("/dev/dri/card0"),
    )
    add_dependency(:Mount, "/dev")
    add_dependency(:Mount, "/sys")

    # Make the Graphics target depend on this task.
    Targets[:Graphics].add_dependency(:Task, self)
  end

  def run()
    # no-op
  end

  def ux_priority()
    -100
  end
end

