require_relative '../../sequence_logo'
require 'fileutils'
require 'cgi'

def generate_glued_logo(alignment_infos, options, total_orientation, output_file)
  logos = {}
  logo_filenames = []
  rightmost_side = alignment_infos.map do |line|
    filename, shift, orientation, motif_name = line.strip.split("\t")
    shift = shift.to_i
    shift + get_ppm_from_file(filename).length
  end.max

  alignment_infos.each do |line|
    filename, shift, orientation, motif_name = line.strip.split("\t")
    motif_name ||= CGI.unescape(File.basename(filename, File.extname(filename)))
    ppm = get_ppm_from_file(filename)
    shift = shift.to_i
    raise 'Unknown orientation'  unless %w[direct revcomp].include?(orientation.downcase)
    if total_orientation == :revcomp
      orientation = (orientation == 'direct') ? 'revcomp' : 'direct'
      shift = rightmost_side - shift - ppm.length
    end
    checkerr("bad input file: #{filename}") { ppm == nil }
    logo_filename = "#{filename}_temp.png"
    logo_filenames << logo_filename
    case orientation
    when 'direct'
      SequenceLogo.draw_logo(ppm, options).write(logo_filename)
    when 'revcomp'
      SequenceLogo.draw_logo(ppm.revcomp, options).write(logo_filename)
    else
      raise "Unknown orientation #{orientation} for #{motif_name}"
    end
    logos[logo_filename] = {shift: shift, length: ppm.length, name: motif_name}
  end

  SequenceLogo.glue_files(logos, output_file, options)
  logo_filenames.each{|filename| File.delete(filename) }
end

begin
  doc = <<-EOS
  Usage:
    glue_logos <output file> <alignment infos file>
      or
    <alignment infos file> | glue_logos <output file>

  Alignment infos has the following format (tab separated)
  if motif names not specified - filenames are used as labels:
    pcm_file_1  shift_1  orientation_1  [motif_name_1]
    pcm_file_2  shift_2  orientation_2  [motif_name_2]
    pcm_file_3  shift_3  orientation_3  [motif_name_3]

  EOS

  argv = ARGV
  total_orientation = :direct
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
    parser.on_head('--orientation ORIENTATION', 'Which logo to draw: direct/revcomp/both') do |v|
      v = v.to_sym
      raise ArgumentError, 'Orientation can be either direct or revcomp or both'  unless [:direct, :revcomp, :both].include?(v)
      total_orientation = v
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

  if total_orientation == :both
    extname = File.extname(output_file)
    basename = File.basename(output_file, extname)
    dirname = File.dirname(output_file)
    generate_glued_logo(alignment_infos, options, :direct, File.join(dirname, "#{basename}_direct.#{extname}"))
    generate_glued_logo(alignment_infos, options, :revcomp, File.join(dirname, "#{basename}_revcomp.#{extname}"))
  else
    generate_glued_logo(alignment_infos, options, total_orientation, output_file)
  end

rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end