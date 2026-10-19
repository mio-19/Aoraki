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
  gitRev =
    let
      headPath = ../.git/HEAD;
    in
    if builtins.pathExists headPath then
      let
        head = builtins.readFile headPath;
        refMatch = builtins.match "ref: (.*)\n" head;
      in
      if refMatch != null then
        let
          ref = builtins.head refMatch;
          refPath = ../.git + ("/" + ref);
        in
        if builtins.pathExists refPath then
          builtins.substring 0 8 (builtins.readFile refPath)
        else
          "unknown"
      else
        builtins.substring 0 8 head
    else
      "unknown";

  banner = pkgs.writeText "${device_name}-banner" ''
    From a mobile-nixos device ${device_name} (rev ${gitRev})
  '';
  rootHash = "$6$wearroot$RYEJMmyL0CBIaGRy54AUS9B3AWgIjMOeiamag/f.9PQAgfyG8MUsQNJ.pOP77SWdlL9pjf9vZXtc2iQnYRYRm/";

  passwdFile = pkgs.writeText "passwd" ''
    root:${if cfg.insecureDebug then rootHash else "*"}:0:0:root:/root:/bin/sh
  '';

  groupFile = pkgs.writeText "group" ''
    root:x:0:
  '';

  shadowFile = pkgs.writeText "shadow" ''
    root:${if cfg.insecureDebug then rootHash else "*"}:19000:0:99999:7:::
  '';

  shellsFile = pkgs.writeText "shells" ''
    /bin/sh
  '';

  nsswitchFile = pkgs.writeText "nsswitch.conf" ''
    passwd: files
    group: files
    shadow: files
  '';
  inherit (config.mobile.outputs) extraUtils;

  profileFile = pkgs.writeText "profile" ''
    export PATH="${extraUtils}/bin:/bin:/sbin:$PATH"
    export LD_LIBRARY_PATH="${extraUtils}/lib:$LD_LIBRARY_PATH"
    alias ll='ls -la'
  '';

  continueBootScript = pkgs.writeScript "continue-boot" ''
    #!/bin/sh
    echo "Resuming boot to Stage-2..."
    touch /run/continue-boot
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
        When enabled, sets predefined root password 'root' and spawns
        an unauthenticated telnetd daemon on 172.16.42.1 for emergency debugging.
      '';
    };

    holdBeforeSwitchRoot = mkOption {
      type = types.bool;
      default = cfg.insecureDebug;
      description = ''
        When enabled, pauses stage-1 execution right before unlinking the initrd
        and switching root to stage-2. To resume, execute 'continue-boot'.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    bootConfig = {
      debug = cfg.insecureDebug;
      holdBeforeSwitchRoot = cfg.holdBeforeSwitchRoot;
    };

    tasks = [
      (pkgs.writeText "dropbear-sshd-task.rb" ''
        class Tasks::DropbearSSHD < SingletonTask
          def initialize()
            add_dependency(:Target, :Networking)
            Targets[:SwitchRoot].add_dependency(:Task, self)
          end
          
          def run()
            FileUtils.mkdir_p("/etc/dropbear")
            # Ensure /dev/pts is mounted so telnetd and dropbear can allocate pseudo-terminals
            FileUtils.mkdir_p("/dev/pts")
            System.run("mount", "-t", "devpts", "-o", "ptmxmode=0666,mode=620", "devpts", "/dev/pts") rescue nil
            FileUtils.ln_sf("/dev/pts/ptmx", "/dev/ptmx") rescue nil

            # Ensure busybox symlinks exist in /bin for shell commands
            System.run("busybox", "--install", "-s", "/bin") rescue nil

            is_debug = Configuration["debug"] == true
            if is_debug
              # Spawn dropbear (with predefined password 'root', allowing blank fallback)
              System.spawn("dropbear", "-ERB", "-b", "/etc/banner")

              # Spawn telnetd for immediate, unauthenticated emergency shell access
              if System.which("telnetd")
                System.spawn("telnetd", "-F", "-l", "/bin/sh")
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
      {
        object = profileFile;
        symlink = "/etc/profile";
      }
      {
        object = continueBootScript;
        symlink = "/bin/continue-boot";
      }
      {
        object = passwdFile;
        symlink = "/etc/passwd";
      }
      {
        object = groupFile;
        symlink = "/etc/group";
      }
      {
        object = shadowFile;
        symlink = "/etc/shadow";
      }
      {
        object = shellsFile;
        symlink = "/etc/shells";
      }
      {
        object = nsswitchFile;
        symlink = "/etc/nsswitch.conf";
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
