module Astrails
  module Safe
    class Local < Sink

      protected

      def active?
        # S3 can't upload from pipe. it needs to know file size, so we must pass through :local
        # will change once we add SSH/FTP sink
        true
      end

      def path
        @path ||= File.expand_path(expand(@config[:local, :path] || raise(RuntimeError, "missing :local/:path")))
      end

      def save
        puts "command: #{@backup.command}" if $_VERBOSE

        # FIXME: probably need to change this to smth like @backup.finalize!
        @backup.path = full_path # need to do it outside DRY_RUN so that it will be avialable for S3 DRY_RUN

        unless $DRY_RUN
          FileUtils.mkdir_p(path) unless File.directory?(path)
          benchmark = Benchmark.realtime do
            system "#{@backup.command}>#{@backup.path}"
          end
          puts("command took " + sprintf("%.2f", benchmark) + " second(s).") if $_VERBOSE
        end

      end

      def cleanup
        return unless keep = @config[:keep, :local]

        puts "listing files #{base}" if $_VERBOSE

        # TODO: cleanup ALL zero-length files

        files = Dir["#{base}*"] .
          select{|f| File.file?(f) && File.size(f) > 0} .
          sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing local file #{f}" if $DRY_RUN || $_VERBOSE
          File.unlink(f) unless $DRY_RUN
        end
      end
    end
  end
end
