# Native ext4 File-Based Encryption (FBE) via fscrypt for wearable devices.
# Linux kernel fscrypt documentation: https://www.kernel.org/doc/html/latest/filesystems/fscrypt.html
# Google Adiantum cipher (designed for devices lacking AES hardware acceleration): https://github.com/google/adiantum
# fscrypt userspace implementation & PAM integration: https://github.com/google/fscrypt
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mobile.fscrypt;
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options.mobile.fscrypt = {
    enable = mkEnableOption "Ext4 native File-Based Encryption (fscrypt) for user home directory";

    user = mkOption {
      type = types.str;
      default = "ceres";
      description = "User whose home directory is protected with native ext4 file-based encryption.";
    };

    policy = mkOption {
      type = types.enum [
        "adiantum"
        "aes-256-xts"
      ];
      default = "adiantum";
      description = ''
        Encryption cipher policy for directories.
        Adiantum is optimized for devices without hardware AES acceleration (such as ARM Cortex-A7 smartwatches).
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable NixOS PAM fscrypt module integration (pam_fscrypt.so)
    # This automatically unlocks the user's home directory upon authentication and locks on session end.
    security.pam.enableFscrypt = mkDefault true;

    # CLI tools for filesystem encryption management
    environment.systemPackages = [
      pkgs.fscrypt
      pkgs.fscryptctl
      pkgs.e2fsprogs
    ];

    # Ensure systemd service verifies filesystem initialization
    systemd.services.fscrypt-init = {
      description = "Initialize ext4 fscrypt filesystem encryption metadata";
      wantedBy = [ "multi-user.target" ];
      before = [
        "display-manager.service"
        "systemd-user-sessions.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "fscrypt-init" ''
          if [ ! -d "/etc/fscrypt.conf" ] && [ ! -f "/etc/fscrypt.conf" ]; then
            ${pkgs.fscrypt}/bin/fscrypt setup --force
          fi
        '';
      };
    };
  };
}
