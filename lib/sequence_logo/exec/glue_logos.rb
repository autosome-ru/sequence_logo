require_relative '../../sequence_logo'
require 'fileutils'
require 'cgi'
require 'tempfile'

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
  default_options = {x_unit: 30, y_unit: 60, words_count: nil, icd_mode: :discrete, threshold_lines: false, scheme: 'nucl_simpa', logo_shift: 300, text_size: 24}
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

  include SequenceLogo
  alignment = Alignment.new
  alignment_infos.each{|line|
    filename, shift, orientation, motif_name = line.strip.split("\t")
    motif_name ||= CGI.unescape(File.basename(filename, File.extname(filename)))
    ppm = get_ppm_from_file(filename)
    shift = shift.to_i

    checkerr("bad input file: #{filename}") { ppm == nil }
    raise 'Unknown orientation'  unless %w[direct revcomp].include?(orientation.downcase)

    ppm_oriented = (orientation.downcase == 'direct') ? ppm : ppm.revcomp
    ppm_oriented.name ||= motif_name
    ppm_logo = PPMLogo.new(ppm_oriented,
                          icd_mode: options[:icd_mode],
                          words_count: options[:words_count],
                          enable_threshold_lines: options[:threshold_lines])
    alignment += Alignment::Item.new(ppm_logo, shift)
  }

  scheme_dir = File.join(AssetsPath, options[:scheme])
  letter_images = CanvasFactory.letter_images(scheme_dir)
  canvas_factory = CanvasFactory.new(letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit],
                                                    text_size: options[:text_size], logo_shift: options[:logo_shift])

  extname = File.extname(output_file)
  basename = File.basename(output_file, extname)
  dirname = File.dirname(output_file)
  direct_output_filename = File.join(dirname, "#{basename}_direct#{extname}")
  reverse_output_filename = File.join(dirname, "#{basename}_revcomp#{extname}")

  if total_orientation == :both
    alignment.render(canvas_factory).write('PNG:' + direct_output_filename)
    alignment.revcomp.render(canvas_factory).write('PNG:' + reverse_output_filename)
  else
    if total_orientation == :direct
      alignment.render(canvas_factory).write('PNG:' + direct_output_filename)
    else
      alignment.revcomp.render(canvas_factory).write('PNG:' + reverse_output_filename)
    end
  end

rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end
