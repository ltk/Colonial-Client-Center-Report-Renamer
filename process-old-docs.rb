unless ARGV.length == 1
  puts "Please provide a path to a folder containing user folders containing old documents to process."
  exit
end

input_path = ARGV[0]
ARGV.clear

require 'FileUtils'

# Adding some color function to our output
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end

class CCC_Report
    def initialize(f, path, success_dir)
        @errors = Array.new

        @success_dir = success_dir

        @file = f
        @ext = File.extname(f)
        @basename = File.basename(f, @ext)
        @old_filename = path + "/" + @basename + @ext
        @year = "2012"
        @month = self.pull_month
        @lot = self.pull_lot_number
        @report_title = self.pull_report_title
        @new_filename = self.construct_new_filename

        self.setup_directories

        moved_files = self.mv_files

        if @errors.any?
            @errors.each do |message|
                puts message.red
            end
        else 
            message =  @old_filename + " converted to " + @new_filename
            puts message.green
            
        end
    end

    def status 
        return @errors.empty?
    end

    def setup_directories
        FileUtils.mkdir @success_dir if not File.directory? @success_dir
    end

    def pull_month
        match = @basename.scan(/^(?<month>[\d])_/)
        
        if match.any?
            month = "0" + match[0][0]
        else
            month = "01"
        end

        month
    end

    def pull_lot_number

        match = @basename.scan(/^([\d]_)?(?<lot>[\d]{2,3})[ -]/)

        if match.any?
            lot = match[0][0]
        end

        if lot.nil?
            @errors << ("No lot ID found in " + @old_filename).red
        end

        lot
    end

    def pull_report_title
        report_title = @basename        


        report_title.sub!(/^([\d]_)?[\d]{2,3}[ -]/, '')


        report_title.lstrip.gsub(/[[:space:]]/, "_").gsub(/\./,"_").gsub(/--/,"-").gsub(/_-/,"_").gsub(/__/,"_")
    end

    def construct_new_filename

        unless @lot.nil?
            new_filename = "LOT" + @lot + "_" + @year + "_" + @month + "_" + @report_title + @ext
        end

        new_filename
    end

    def mv_files
        unless @errors.any?
            file_moved = FileUtils.mv( @old_filename, @success_dir + "/" + @new_filename )
        end
        file_moved
    end
end

class CCC_Renamer
    @@success_dir_name = "_renamed"
    @@combined_dir_name = "_combined"

    def initialize( path )
        @successes = 0
        @failures = 0

        @path = path

        @combined_dir = @path + "/" + @@combined_dir_name
        @success_dir = @combined_dir + "/" + @@success_dir_name

        self.setup_directories
        self.combine_docs
        self.process_combined_dir

        # self.display_completion_msg
    end

    def display_completion_msg
        puts "Process complete. " + @successes.to_s + " files successfully processed. " + @failures.to_s + " failures."
    end

    def setup_directories
        FileUtils.mkdir @combined_dir if not File.directory? @combined_dir
        FileUtils.mkdir @success_dir if not File.directory? @success_dir
    end

    def combine_docs
        Dir.glob( @path + "/*" ).sort.each do |f|
            if (File.directory?(f) && f != @combined_dir)
                Dir.glob( f + "/*" ).sort.each do |report|
                    ext = File.extname(report)
                    basename = File.basename(report, ext)
                    # puts report.green if FileUtils.mv( report, @combined_dir + "/" + basename + ext, force: true )
                end
            end
        end
    end

    def process_combined_dir
        Dir.glob( @combined_dir + "/*" ).sort.each do |f|
            file = CCC_Report.new( f, @combined_dir, @success_dir )

            if file.status == true
                @successes = @successes + 1;
            else
                @failures = @failures + 1;
            end
        end
    end
end

rename = CCC_Renamer.new input_path
