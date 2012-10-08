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
    def initialize(f, path, year, month, success_dir)
        @errors = Array.new

        @file = f
        @ext = File.extname(f)
        @basename = File.basename(f, @ext)
        @old_filename = path + "/" + @basename + @ext
        @year = year
        @month = month

        @success_dir = success_dir

        self.setup_directories

        @passed_regex = false

        @lots = self.pull_lot_numbers
        @report_title = self.pull_report_title

        @new_filenames = self.construct_new_filename

        moved_files = self.mv_files

        self.cleanup unless @errors.any?

        if @errors.any?
            @errors.each do |message|
                puts message
            end
        else
            moved_files.each do |message|
                puts message
            end
        end
    end

    def status 
        return @errors.empty?
    end

    def setup_directories
        FileUtils.mkdir @success_dir if not File.directory? @success_dir
    end

    def pull_lot_numbers
        lots = Array.new

        lot_sub_strings = @basename.split(/[ -]/)

        lot_sub_strings.each do |sub_str|
            sub_str.scan(/(?:^|[^\d])(?<lot>[\d]{3})(?:[^\d]|$)/) do |match|
                lots << match
            end
        end

        if not lots.any?
            @errors << ("No lot ID found in " + @old_filename).red
        end

        lots
    end

    def pull_report_title
        report_title = @basename        

        @lots.each do |lot|
            report_title.sub!(/[ -_&]?#{lot}[ -_&]?/, '')
        end

        report_title.lstrip.gsub(/[[:space:]]/, "_").gsub(/\./,"_")
    end

    def construct_new_filename
        new_filenames = Array.new

        @lots.each do |lot|
            if lot.is_a?(String)
                new_filenames << "LOT" + lot + "_" + @year + "_" + @month + "_" + @report_title + @ext
            else
                lot.each do |l|
                    new_filenames << "LOT" + l + "_" + @year + "_" + @month + "_" + @report_title + @ext
                end
            end
        end

        new_filenames
    end

    def mv_files
        moved_files = Array.new

        unless @errors.any?
            @new_filenames.each do |new_name|
                file_moved = FileUtils.copy( @old_filename, @success_dir + "/" + new_name )
                moved_files << (@basename + @ext +  " converted to " + new_name).green
            end
        end
        @errors << (@basename + @ext + " NOT converted.").red unless moved_files.any?
        moved_files
    end

    def cleanup
        FileUtils.remove( @old_filename )
    end
end

class CCC_Renamer
    @@success_dir_name = "_renamed"

    def initialize( path )
        @successes = 0
        @failures = 0

        @path = path

        @success_dir = @path + "/" + @@success_dir_name

        @year = prompt_year
        @month = prompt_month

        self.process_dir

        self.display_completion_msg
    end

    def display_completion_msg
        puts "Process complete. " + @successes.to_s + " files successfully processed. " + @failures.to_s + " failures."
    end

    def prompt_year
        puts "Enter report year (4 digit):"
        while year = gets.chomp do
            break if /^[\d]{4}$/.match(year)
            puts "Invalid! Enter a 4 digit report year (e.g. 2012):"
        end
        
        year
    end

    def prompt_month
        puts "Enter report month (2 digit):"
        while month = gets.chomp do
            break if ( /^[\d]{2}$/.match(month) and (1..12) === month.to_i )
            puts "Invalid! Enter a valid 2 digit report month (e.g. 04 for April):"
        end
        month
    end

    def process_dir
        Dir.glob( @path + "/*" ).sort.each do |f|
            file = CCC_Report.new( f, @path, @year, @month, @success_dir )

            if file.status == true
                @successes = @successes + 1;
            else
                @failures = @failures + 1;
            end
        end
    end
end

rename = CCC_Renamer.new "/Users/jakedev2/Desktop/Col\ Client\ Center\ 2.0\ Working\ Dir/renaming\ tests/201206"
