module Hal
  module Recovery
    extend self

    KEYS = [
      # Smartwatch hardware buttons
      :KEY_POWER,
      :KEY_HOMEPAGE,
      :KEY_SEARCH,
      :KEY_MENU,
      :KEY_BACK,
      :BTN_9, # Stem button on Fossil Gen 6 (code 0x109)
      :BTN_SIDE, # Side stem button (code 0x113)
      :BTN_0, # Generic hardware button 0 (code 0x100)
      :BTN_1, # Generic hardware button 1 (code 0x101)
      :BTN_TRIGGER_HAPPY, # Trigger happy / stem button on Qualcomm platforms
    ]

    def firmware_wants_recovery?()
      # "Boot as recovery" systems do not have a discrete recovery partition.
      # For those systems, when `[s_]kip_initramfs` is in the kernel cmdline, we
      # know the intent is to boot the normal system.
      # Is a "boot as recovery" device, and Is `[s_]kip_initramfs` missing?
      if Configuration["device"]["boot_as_recovery"] then
        if File.exist?("/proc/cmdline") then
          !File.read("/proc/cmdline").split(/\s+/).grep(/[s_]kip_initramfs/).any?
        end
      end
    end

    # Is this boot image a recovery image, or booted into recovery mode by the
    # device firmware?
    def is_recovery?()
      # Check in /etc/boot/config for `is_recovery`, it's assumed to be set, and
      # true, for recovery builds.
      Configuration["is_recovery"] or firmware_wants_recovery?
    end

    # Is the normal boot flow interrupted by a key input?
    def boot_interrupted?()
      return true if Evdev.keys_held(KEYS)

      # On smartwatches, check over a 1-second window to detect a middle button press
      # matching AsteroidOS init.machine.sh waitmidbutton behavior
      if Configuration["watch"] || (Configuration["screen"] && Configuration["screen"]["shape"] == "round")
        10.times do
          sleep(0.1)
          return true if Evdev.keys_held(KEYS)
        end
      end

      false
    end

    def wants_recovery?
      [
        # Booted a recovery partition.
        is_recovery?,
        # Or signaling the boot selection menu should be shown.
        boot_interrupted?,
      ].any?
    end
  end
end
