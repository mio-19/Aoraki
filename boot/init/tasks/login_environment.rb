# Adds a minimal set of files required for logging-in.
class Tasks::LoginEnvironment < SingletonTask
  def initialize()
  end

  def run()
    # Basic stuff expected by shells and logins
    FileUtils.mkdir_p(
      "/etc",
      "/var/log",
    )
    System.write("/var/log/lastlog", "")
    return if File.exist?("/etc/passwd")

    System.write("/etc/shells", "/bin/sh\n")
    is_debug = Configuration["debug"] == true
    root_hash = "$6$wearroot$RYEJMmyL0CBIaGRy54AUS9B3AWgIjMOeiamag/f.9PQAgfyG8MUsQNJ.pOP77SWdlL9pjf9vZXtc2iQnYRYRm/"
    root_passwd = is_debug ? "root:#{root_hash}:0:0:root:/root:/bin/sh\n" : "root:*:0:0:root:/root:/bin/sh\n"
    System.write("/etc/passwd", root_passwd)
    System.write("/etc/nsswitch.conf", "passwd: files\n")
  end
end


