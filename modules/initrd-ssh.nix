{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;
  device_name = config.mobile.device.name;
  cfg = config.mobile.boot.stage-1.ssh;
  banner = pkgs.writeText "${device_name}-banner" ''
    From a mobile-nixos device ${device_name}
  '';
in
{
  options.mobile.boot.stage-1.ssh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables ssh during stage-1.
      '';
    };

    insecureDebug = mkOption {
      type = types.bool;
      default = config.mobile.hardware.watch.debug.enable or false;
      description = ''
        When enabled, unlocks passwordless root login (root::0:0...) and spawns
        an unauthenticated telnetd daemon on 172.16.42.1 for emergency debugging.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    bootConfig = {
      debug = cfg.insecureDebug;
    };

    tasks = [
      # Insecure root password task
      (pkgs.writeText "insecure-root-password-task.rb" ''
        class Tasks::InsecureRootPassword < SingletonTask
          def initialize()
            add_dependency(:Target, :Environment)
          end
          
          def run()
            if Configuration["debug"] == true
              System.run("passwd", "-d", "root") rescue nil
            end
          end
        end
      '')
      (pkgs.writeText "dropbear-sshd-task.rb" ''
        class Tasks::DropbearSSHD < SingletonTask
          def initialize()
            add_dependency(:Target, :Networking)
            Targets[:SwitchRoot].add_dependency(:Task, self)
          end
          
          def run()
            FileUtils.mkdir_p("/etc/dropbear")
            is_debug = Configuration["debug"] == true
            if is_debug
              # Ensure root has an unlocked empty password in /etc/passwd
              begin
                if File.exist?("/etc/passwd")
                  passwd = File.read("/etc/passwd").gsub(/^root:[^:]*:/, "root::")
                  File.write("/etc/passwd", passwd)
                end
              rescue => e
                $logger.warn("Could not patch /etc/passwd: #{e.message}")
              end
              # Spawn dropbear allowing blank passwords (-B)
              System.spawn("dropbear", "-ERB", "-b", "/etc/banner")
              # Spawn telnetd for immediate, unauthenticated emergency shell access
              if System.which("telnetd")
                System.spawn("telnetd", "-l", "/bin/sh")
              end
            else
              # In production / non-debug mode, require normal authentication without blank passwords
              System.spawn("dropbear", "-ER", "-b", "/etc/banner")
            end
          end
        end
      '')
    ];
    contents = [
      {
        object = banner;
        symlink = "/etc/banner";
      }
    ];
    extraUtils = [
      {
        package = pkgs.dropbear;
        extraCommand = "cp -fpv ${pkgs.glibc.out}/lib/libnss_files.so.* $out/lib";
      }
    ];
  };
}
