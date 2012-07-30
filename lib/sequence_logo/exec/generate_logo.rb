require 'sequence_logo'
require 'fileutils'

filename = ARGV.shift
unless filename && File.exist?(filename)
  puts 'Existing input file should be specified'
  exit(1)
end

logo_dir = ARGV.shift || File.dirname(filename)
FileUtils.mkdir(logo_dir) unless Dir.exist?(logo_dir)

filename_wo_ext = File.basename(filename, File.extname(filename))
direct_output = File.join(logo_dir,"#{filename_wo_ext}_direct.png")
revcomp_output = File.join(logo_dir,"#{filename_wo_ext}_revcomp.png")

draw_logo(filename, direct_output,  x_unit: 30, y_size: 60, revcomp: 'direct')
draw_logo(filename, revcomp_output, x_unit: 30, y_size: 60, revcomp: 'revcomp')