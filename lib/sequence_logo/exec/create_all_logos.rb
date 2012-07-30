$:.unshift File.join(File.dirname(__FILE__),'./../../')

require 'sequence_logo'
require 'fileutils'

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

  draw_logo(filename, direct_output, words_count: 'default', x_unit: 30, y_size: 60, icd_mode: 'discrete', revcomp: 'direct')
  draw_logo(filename, revcomp_output, words_count: 'default', x_unit: 30, y_size: 60, icd_mode: 'discrete', revcomp: 'revcomp')
end