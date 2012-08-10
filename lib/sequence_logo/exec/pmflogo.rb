# pmflogo <input_file> <output_logo_filename> [words_count] [x_unit=100] [y_unit=200] [icd_mode=discrete|weblogo] [revcomp=no|yes] [scheme=nucl_simpa] [paper_mode=no|yes] [threshold_lines=yes|no]
# Any optional argument can be set as 'default' e.g.
#   pmflogo motif.pcm logo.png default 30 60 default yes
# skipped parameters are also substituted as default (in example above icd_mode is default, and also scheme, paper_mode and threshold_lines)

require_relative '../../sequence_logo'

if ARGV.size < 2
  puts('At least two arguments must be specified, see usage of pmflogo')
  exit(2)
end

input_file, output_logo_filename = ARGV.shift(2)
unless File.exist?(input_file)
  puts('Specified input file not exists')
  exit(1)
end

options = {}
options[:words_count] = ARGV.shift
options[:x_unit], options[:y_unit] = ARGV.shift(2)
options[:icd_mode], options[:revcomp], options[:scheme], options[:paper_mode], options[:threshold_lines] = ARGV.shift(5)

options.reject!{|k,v| v.nil?}

ppm = get_ppm_from_file(input_file)
checkerr("bad input file") { ppm == nil }

draw_logo(ppm, options).write(output_logo_filename)