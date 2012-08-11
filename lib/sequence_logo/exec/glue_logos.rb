require_relative '../../sequence_logo'
require 'fileutils'

# ppms {ppm => shift}

output_file = ARGV.shift
unless output_file
  STDERR.puts "You should specify output filename"
end
logos = {}
filenames = []
STDIN.readlines.each do |line|
  pcm_file, shift, orientation = line.split
  shift = shift.to_i
  # ppm = Bioinform::PCM.new(pcm_file).to_ppm
  ppm = get_ppm_from_file(pcm_file)
  logo_filename = "#{pcm_file}_temp.png"
  filenames << logo_filename
  draw_logo(ppm, x_unit: 30, y_unit: 60, revcomp: orientation).write(logo_filename)
  logos[logo_filename] = {shift: shift, length: ppm.length, name: File.basename(pcm_file, File.extname(pcm_file))}
end

glue_files(logos, output_file)
filenames.each{|filename| File.delete(filename) }
