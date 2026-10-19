# This provides `build.rootfs`, which is the rootfs image (ext4) built from
# the current configuration.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (config.mobile._internal) compressLargeArtifacts;
  inherit (pkgs) buildPackages;
  rootfsLabel = config.mobile.generatedFilesystems.rootfs.label;
  cfgStrip = config.mobile.rootfs.strip;
  targetStrip = "${pkgs.buildPackages.binutils-unwrapped}/bin/${pkgs.stdenv.targetPlatform.config}-strip";
in
{
  options = {
    mobile = {
      rootfs = {
        enableDefaultConfiguration = mkOption {
          type = types.bool;
          default = config.mobile.enable;
          description = ''
            Whether some of the rootfs configuration is managed by Mobile NixOS or not.
          '';
        };
        rehydrateStore = mkOption {
          type = types.bool;
          default = config.nix.enable;
          defaultText = lib.literalExpression "config.nix.enable";
          description = ''
            Whether to rehydrate the store at first boot or not.

            The only reason you would disable this is to build a target system that has no Nix binaries.
          '';
        };
        strip = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether to strip unnecessary static symbols, debug info, static archives (.a),
              headers (/include), and documentation from the generated rootfs image.
            '';
          };
          stripUnneeded = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Run target strip with --strip-unneeded on all ELF binaries and shared
              libraries in the rootfs.
            '';
          };
          removeStaticArchives = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Remove static library archives (.a) from the rootfs.
            '';
          };
          removeHeaders = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Remove C/C++ development headers (/include) from the rootfs.
            '';
          };
          removeDocs = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Remove manual pages and documentation (/share/man, /share/doc, /share/info)
              from the rootfs.
            '';
          };
          keepLocales = mkOption {
            type = types.listOf types.str;
            default = [
              "en"
              "en_US"
              "en_GB"
              "C"
              "POSIX"
            ];
            description = ''
              Locale language prefixes to preserve in /share/locale; all other language .mo
              files will be pruned to save flash storage. Set to [] to keep all locales.
            '';
          };
        };
      };
    };
  };

  config = mkIf (config.mobile.rootfs.enableDefaultConfiguration) {
    boot.growPartition = lib.mkDefault true;

    mobile.generatedFilesystems.rootfs = {
      filesystem = lib.mkDefault "ext4";
      label = lib.mkDefault "NIXOS_SYSTEM";
      ext4.partitionID = "44444444-4444-4444-8888-888888888888";
      btrfs.partitionID = "44444444-4444-4444-8888-888888888888";
      btrfs.compression = "zstd:3";

      populateCommands =
        let
          closureInfo = pkgs.buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
        in
        ''
          mkdir -p ./nix/store
          echo "Copying system closure..."

          err=0
          while IFS= read -r path; do
            echo "  Copying $path"
            if test -e "$path"; then
              cp -prf "$path" ./nix/store
            else
              2>&1 printf "ERROR: path %q does not exist...\n" "$path"
              (( ++err ))
            fi
          done < "${closureInfo}/store-paths"

          if (( err > 0 )); then
            2>&1 printf "... Bailing out, %d errors.\n" "$err"
            exit 2
          fi

          echo "Done copying system closure..."

          ${optionalString cfgStrip.enable ''
            echo ":: Stripping and shrinking rootfs image..."
            chmod -R u+w ./nix/store

            ${optionalString cfgStrip.removeStaticArchives ''
              echo "   - Removing static archives (.a)..."
              find ./nix/store -type f -name "*.a" -delete
            ''}

            ${optionalString cfgStrip.removeHeaders ''
              echo "   - Removing C/C++ development headers (/include)..."
              find ./nix/store -type d -name "include" -prune -exec rm -rf {} + 2>/dev/null || true
            ''}

            ${optionalString cfgStrip.removeDocs ''
              echo "   - Removing manual pages and documentation..."
              find ./nix/store \( -path "*/share/man" -o -path "*/share/doc" -o -path "*/share/info" -o -path "*/share/gtk-doc" \) -prune -exec rm -rf {} + 2>/dev/null || true
            ''}

            ${optionalString (cfgStrip.keepLocales != [ ]) ''
              echo "   - Pruning non-essential desktop locales (keeping watch translations)..."
              find ./nix/store -type d -path "*/share/locale/*" -prune | while read -r locdir; do
                locname="$(basename "$locdir")"
                keep=0
                for k in ${concatStringsSep " " cfgStrip.keepLocales}; do
                  if [[ "$locname" == "$k"* ]]; then keep=1; break; fi
                done
                if (( keep == 0 )); then
                  rm -rf "$locdir"
                fi
              done
            ''}

            ${optionalString cfgStrip.stripUnneeded ''
              echo "   - Stripping ELF binaries and shared libraries..."
              find ./nix/store \( -path "*/bin/*" -o -path "*/sbin/*" -o -path "*/lib/*" -o -path "*/libexec/*" \) -type f ! -name "*.ko" -print0 | xargs -0 -P "$(nproc 2>/dev/null || echo 4)" -n 64 ${targetStrip} --strip-unneeded 2>/dev/null || true
              find ./nix/store -name "*.ko" -print0 | xargs -0 -P "$(nproc 2>/dev/null || echo 4)" -n 64 ${targetStrip} --strip-debug 2>/dev/null || true
            ''}
          ''}

          cp -v ${closureInfo}/registration ./nix-path-registration
        '';

      # Give some headroom for initial mounting.
      extraPadding = pkgs.image-builder.helpers.size.MiB 20;

      location = "/rootfs.img${optionalString compressLargeArtifacts ".zst"}";

      # FIXME: See #117, move compression into the image builder.
      # Zstd can take a long time to complete successfully at high compression
      # levels. Increasing the compression level could lead to timeouts.
      additionalCommands =
        optionalString compressLargeArtifacts ''
          echo ":: Compressing rootfs image"
          (PS4=" $ "; set -x
          cd $out_path
          # Hacky, but the img path here already has .zst appended.
          # Let's rename it (we assume rootfs.img) and do the compression here.
          mv "$img" "rootfs.img"
          time ${buildPackages.zstd}/bin/zstd -10 --rm "rootfs.img"
          )
        ''
        + ''
          echo ":: Adding hydra-build-products"
          (PS4=" $ "; set -x
          mkdir -p $out_path/nix-support
          cat <<EOF > $out_path/nix-support/hydra-build-products
          file rootfs${optionalString compressLargeArtifacts "-zstd"} $img
          EOF
          )
        '';
    };

    boot.postBootCommands = mkIf (config.mobile.rootfs.rehydrateStore) ''
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';

    fileSystems = {
      "/" = lib.mkDefault {
        device = "/dev/disk/by-label/${rootfsLabel}";
        fsType = config.mobile.generatedFilesystems.rootfs.filesystem;
        options =
          if config.mobile.generatedFilesystems.rootfs.filesystem == "btrfs" then
            [
              "compress=zstd:3"
              "noatime"
              "space_cache=v2"
            ]
          else
            [ "defaults" ];
        autoResize = true;
      };
    };

    # Include appropriate filesystem tools in stage-1 extraUtils
    mobile.boot.stage-1.extraUtils = [
      (lib.mkIf (config.mobile.generatedFilesystems.rootfs.filesystem == "ext4") {
        package = pkgs.e2fsprogs;
      })
      (lib.mkIf (config.mobile.generatedFilesystems.rootfs.filesystem == "btrfs") {
        package = pkgs.btrfs-progs;
      })
    ];
  };
}
