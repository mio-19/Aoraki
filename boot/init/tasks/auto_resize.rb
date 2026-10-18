# Automatically resizes the given filesystem.
class Tasks::AutoResize < Task
  attr_reader :device

  def initialize(device, type: )
    @device = device
    @type = type
    add_dependency(:Devices, @device)
    add_dependency(:Mount, "/sys")
    # For better user experience.
    # Otherwise the device may look like it's hanging.
    add_dependency(:Target, :Graphics)
  end

  # Computes whether a filesystem needs to be expanded.
  # This way the long-running tasks happen only once.
  def needs_resize?()
    if @type.match(/^ext[234]$/)
      # Parse the output of dumpe2fs
      data = `dumpe2fs -h #{@device.shellescape}`
        .lines
        .map(&:strip)
        .map { |line| line.split(/:\s*/, 2) }
        .select { |pair| pair.length == 2 }
        .to_h

      block_size = data["Block size"].to_f
      block_count = data["Block count"].to_f

      # In bytes
      filesystem_size = block_count * block_size
    elsif @type == "btrfs"
      dump = `btrfs inspect-internal dump-super #{@device.shellescape}`
      total_bytes_line = dump.lines.grep(/total_bytes/).first
      filesystem_size = total_bytes_line ? total_bytes_line.split(/\s+/)[1].to_f : 0.0
      block_size = 4096.0
    else
      return false
    end

    device_file = File.realpath(@device)
    sys_file = Dir.glob("/sys/block/*/#{device_file.split("/").last}").first
    return false unless sys_file

    # In bytes. From 512 bytes sectors.
    partition_size = 512 * File.read(File.join(sys_file, "size")).to_f

    # Accounts for a partition size that can't fit a full block, plus some
    # fudge. It's been found that on some "fully resized" devices there was
    # more than the block size left at the end.
    fudge = 2 * block_size

    # Output the sizes in the log, for later interpretations.
    log("#{@device}: #{filesystem_size}/#{partition_size} in use.")

    # Resize when the filesystem size is smaller than the available space.
    # (While accounting for some fudge.)
    filesystem_size < (partition_size - fudge)
  end

  def run()
    if @type.match(/^ext[234]$/)
      if needs_resize?
        log("Resizing #{@device}...")
        Progress.exec_with_message("Verifying #{@device}...") do
          # TODO: Understand the actual underlying issue with e2fsck.
          # It seems `e2fsck` succeeds, according to the output, but has a >0 exit
          # status. Running it again in those situations is a no-op, which is weird
          # to me.
          # This is why we unconditionally run it once, then twice.
          # The second will hopefully abort the boot if it fails too.
          begin
            System.run_long_running("e2fsck", "-fp", @device)
          rescue System::CommandError
            $logger.info("Re-running e2fsc...")
            System.run_long_running("e2fsck", "-fp", @device)
          end
        end
        Progress.exec_with_message("Resizing #{@device}...") do
          System.run_long_running("resize2fs", "-f", @device)
        end
      else
        log("No need to resize #{@device}...")
      end
    elsif @type == "btrfs"
      if needs_resize?
        log("Resizing Btrfs #{@device}...")
        Progress.exec_with_message("Resizing #{@device}...") do
          System.run_long_running("btrfs", "filesystem", "resize", "--offline", "max", @device)
        end
      else
        log("No need to resize #{@device}...")
      end
    else
      $logger.warn("Cannot resize #{@type}... filesystem left untouched.")
    end
  end
end
