require_relative '../../sequence_logo'
require 'fileutils'

begin
  doc = <<-EOS
  Usage:
    glue_logos <output file> <alignment infos file>
      or
    <alignment infos file> | glue_logos <output file>

  Alignment infos has format:
    pcm_file_1  shift_1  orientation_1
    pcm_file_2  shift_2  orientation_2
    pcm_file_3  shift_3  orientation_3
  EOS

  argv = ARGV
  default_options = {x_unit: 30, y_unit: 60, words_count: nil, icd_mode: :discrete, threshold_lines: true, scheme: 'nucl_simpa', logo_shift: 300, text_size_pt: 24}
  cli = SequenceLogo::CLI.new(default_options)
  cli.instance_eval do
    parser.banner = doc
    parser.on_head('--logo-shift SHIFT', 'Width of region for labels') do |v|
      options[:logo_shift] = v.to_i
    end
    parser.on_head('--text-size SIZE', 'Text size in points') do |v|
      options[:text_size] = v.to_f
    end
  end
  options = cli.parse_options!(argv)

  output_file = argv.shift
  raise ArgumentError, 'Specify output file'  unless output_file

  raise 'You can specify alignment infos either from file or from stdin. Don\'t use both sources simultaneously' if !ARGV.empty? && !$stdin.tty?
  if !ARGV.empty?
    alignment_infos = File.readlines(ARGV.shift)
  elsif !$stdin.tty?
    alignment_infos = $stdin.readlines
  else
    raise ArgumentError, 'Specify alignment infos'
  end

  logos = {}
  logo_filenames = []
  alignment_infos.each do |line|
    filename, shift, orientation = line.strip.split("\t")
    ppm = get_ppm_from_file(filename)
    checkerr("bad input file: #{filename}") { ppm == nil }
    shift = shift.to_i
    logo_filename = "#{filename}_temp.png"
    logo_filenames << logo_filename
    case orientation
    when 'direct'
      SequenceLogo.draw_logo(ppm, options).write(logo_filename)
    when 'revcomp'
      SequenceLogo.draw_logo(ppm.revcomp, options).write(logo_filename)
    else
      raise "Unknown orientation #{orientation} for #{filename}"
    end
    logos[logo_filename] = {shift: shift, length: ppm.length, name: File.basename(filename, File.extname(filename))}
  end

  SequenceLogo.glue_files(logos, output_file, options)
  logo_filenames.each{|filename| File.delete(filename) }
rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end