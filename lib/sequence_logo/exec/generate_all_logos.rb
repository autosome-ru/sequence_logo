require_relative '../../sequence_logo'
require 'fileutils'
require 'optparse'


options = {words_count: 'default', x_unit: 30, y_unit: 60, icd_mode: 'discrete'}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_all_logos [options]"

  opts.on("-x", "--x-unit X_UNIT", "Set letter width") do |v|
    options[:x_unit] = v
  end
  opts.on("-y", "--y-unit Y_UNIT", "Set base letter height") do |v|
    options[:y_unit] = v
  end
end.parse!

motifs_folder = ARGV.shift
unless motifs_folder && Dir.exist?(motifs_folder)
  puts('Specified input folder not exists')
  exit(1)
end

logo_folder = ARGV.shift
unless logo_folder
  puts('Output logo folder must be specified')
  exit(1)
end

Dir.mkdir(logo_folder)  unless Dir.exist?(logo_folder)

Dir.glob(File.join(motifs_folder, '*')).to_enum.each do |filename|
  filename_wo_ext = File.basename(filename, File.extname(filename))
  direct_output = File.join(logo_folder,"#{filename_wo_ext}_direct.png")
  revcomp_output = File.join(logo_folder,"#{filename_wo_ext}_revcomp.png")

  ppm = get_ppm_from_file(filename)
  checkerr("bad input file: #{filename}") { ppm == nil }
  
  
  SequenceLogo.draw_logo(ppm, options.merge(revcomp: 'direct')).write(direct_output)
  SequenceLogo.draw_logo(ppm, options.merge(revcomp: 'revcomp')).write(revcomp_output)
end