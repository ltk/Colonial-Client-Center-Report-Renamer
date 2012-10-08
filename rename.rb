require 'FileUtils'

# Set your path to the documents
folder_path = "/Users/jakedev2/Desktop/Col\ Client\ Center\ 2.0\ Working\ Dir/201207"
success_dir = folder_path + "/_renamed"
failure_dir = folder_path + "/_not-renamed"

FileUtils.mkdir success_dir if not File.directory? success_dir
successes = Dir.new success_dir

FileUtils.mkdir failure_dir if not File.directory? failure_dir
failures = Dir.new failure_dir
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

puts "Enter report year (4 digit):"
while year = gets.chomp do
	break if /^[\d]{4}$/.match(year)
	puts "Invalid! Enter a 4 digit report year (e.g. 2012):"
end

puts "Enter report month (2 digit):"
while month = gets.chomp do
	break if ( /^[\d]{2}$/.match(month) and (1..12) === month.to_i )
	puts "Invalid! Enter a valid 2 digit report month (e.g. 04 for April):"
end

puts "Renaming files..."

counts = { success: 0, failure: 0 }

Dir.glob(folder_path + "/*").sort.each do |f|
    extension = File.extname(f)
    filename = File.basename(f, extension)
    old_filename = folder_path + "/" + filename + extension
    # puts filename
    # puts extension
    match = false

    if /^[\d]{2,3} [a-zA-Z]+$/.match( filename ) # 123 statement
    	lot_number_match = /^(?<lot>[\d]{2,3})/.match( filename )
    	report_title_match = /(?<title>[a-zA-Z]+)$/.match( filename )

    	report_title = report_title_match[:title]
    	
    	lot_number = lot_number_match[:lot]

    	match = true

    elsif /^[\d]{2,3}[ -][a-zA-Z]+[ a-zA-Z\d]+$/.match( filename ) # 123 variance 201207 / 123-variance 201207
    	lot_number_match = /^(?<lot>[\d]{2,3})/.match( filename )
    	report_title_match = /(?<title>[a-zA-Z]+[ a-zA-Z\d]+)$/.match( filename )
    	
    	report_title = report_title_match[:title]

    	lot_number = lot_number_match[:lot]

    	match = true

    elsif /^[\d]{2,3}-[\d]{1} [a-zA-Z]+$/.match( filename ) # 123-1 statement
    	lot_number_match = /^(?<lot>[\d]{2,3})/.match( filename )
    	report_number_match = /^[\d]{2,3}-(?<report_number>[\d]{1})/.match( filename )
    	report_title_match = /(?<title>[a-zA-Z]+)$/.match( filename )

    	report_title = report_title_match[:title]
    	report_number = report_number_match[:report_number]
    	report_title = report_title + "-" + report_number
    	
    	lot_number = lot_number_match[:lot]

    	match = true

    # elsif /^[\d]{2,3}-[\d]{2,3} [a-z]+$/.match( filename ) # 824-825 statement
    	#split into two separate files? Probably beyond the scope of this script.
    # elsif /^[\d]{2,3} and [\d]{2,3} [a-z]+$/.match( filename ) # 123 and 345 statement
    	#split into two separate files? Probably beyond the scope of this script.
    end 

    if match
    	# Add a preceding zero to two digit lot numbers
        if /^[\d]{2}$/.match(lot_number)
            lot_number = "0" + lot_number
        end

        report_title = report_title.sub(" ", "-")
        new_filename = "LOT" + lot_number + "_" + year + "_" + month + "_" + report_title + extension
    	
    	# Rename and move the file
        if FileUtils.mv( old_filename, success_dir + "/" + new_filename ) 
    	#if File.rename( f, folder_path + "/" + new_filename )
    		counts[:success] = counts[:success] + 1
    		message = "'" + filename + "' converted to: '" + new_filename + "'"
    		puts message.green
    	else
    		counts[:failure] = counts[:falure] + 1
    		message = "'" + filename + "' could not be converted to: '" + new_filename + "'"
    		puts message.red
    	end
	
    else
        new_filename = filename + extension
    	#FileUtils.mv( old_filename, failure_dir + "/" + new_filename )
    	message = "Failure: File does not conform to conventions: " + filename
    	counts[:failure] = counts[:failure] + 1
    	puts message.red
    end
end

puts "Process complete. " + counts[:success].to_s + " files successfully renamed. " + counts[:failure].to_s + " failures."