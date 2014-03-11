require_relative '../../sequence_logo'
require 'fileutils'
require 'cgi'
require 'tempfile'

# logos = { filename => {shift: ..., length: ..., name: ...} }
def glue_files(logos, output_file, options)
  logo_shift = options[:logo_shift] || 300
  x_unit = options[:x_unit] || 30
  y_unit = options[:y_unit] || 60
  text_size = options[:text_size] || 24

  leftmost_shift = logos.map{|file,infos| infos[:shift] }.min
  logos.each{|file, infos| infos[:shift] -= leftmost_shift}
  full_alignment_size = logos.map{|file,infos| infos[:length] + infos[:shift] }.max

  x_size = logo_shift + full_alignment_size * x_unit
  y_size = logos.size * y_unit

  command_string = "convert -size #{ x_size }x#{ y_size } -pointsize #{text_size} xc:white "

  logos.each_with_index do |(logo_filename,infos), idx|
    logo_x_start = logo_shift + infos[:shift] * x_unit
    logo_y_start = y_unit * idx
    command_string << "\"#{ logo_filename }\" -geometry +#{ logo_x_start }+#{ logo_y_start } -composite "
  end

  command_draw_names = ""
  logos.each_with_index do |(logo_filename,infos), idx|
    text_x_start = 10
    text_y_start = y_unit * (idx + 0.5)
    command_draw_names << "-draw \"text #{ text_x_start },#{ text_y_start } '#{infos[:name]}'\" "
  end

  system(command_string + command_draw_names + "\"#{output_file}\"")
end

def rightmost_position(alignment_infos)
  alignment_infos.map{|filename, shift, orientation, motif_name, ppm|  shift + ppm.length  }.max
end

def alignment_on_reverse_strand(alignment_infos)
  rightmost_position = rightmost_position(alignment_infos)
  alignment_infos.map{ |filename, shift, orientation, motif_name, ppm|
    shift_reversed = rightmost_position - shift - ppm.length
    orientation_reversed = (orientation == 'direct') ? 'revcomp' : 'direct'

    [filename, shift_reversed, orientation_reversed, motif_name, ppm] # don't revcomp PPM
  }
end

def generate_glued_logo(alignment_infos, options, total_orientation, output_file)
  logos = {}
  logo_files = []
  if total_orientation == :revcomp
    return generate_glued_logo(alignment_on_reverse_strand(alignment_infos), options, :direct, output_file)
  end

  alignment_infos.each_with_index do |(filename, shift, orientation, motif_name, ppm), index|
    motif_name ||= CGI.unescape(File.basename(filename, File.extname(filename)))
    logo_file = Tempfile.new("#{index}_#{File.basename(filename)}")
    logo_files << logo_file
    SequenceLogo.draw_ppm_logo((orientation.to_s.downcase == 'direct') ? ppm : ppm.revcomp, options).write("PNG:#{logo_file.path}")
    logos[logo_file.path] = {shift: shift, length: ppm.length, name: motif_name}
  end

  glue_files(logos, output_file, options)
  logo_files.each(&:close)
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
  # ToDo: should threshold_lines be true here?
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

  alignment_infos = alignment_infos.map{|line|
    filename, shift, orientation, motif_name = line.strip.split("\t")
    motif_name ||= CGI.unescape(File.basename(filename, File.extname(filename)))
    ppm = get_ppm_from_file(filename)
    shift = shift.to_i

    checkerr("bad input file: #{filename}") { ppm == nil }
    raise 'Unknown orientation'  unless %w[direct revcomp].include?(orientation.downcase)

    [filename, shift, orientation, motif_name, ppm]
  }

  if total_orientation == :both
    extname = File.extname(output_file)
    basename = File.basename(output_file, extname)
    dirname = File.dirname(output_file)
    generate_glued_logo(alignment_infos, options, :direct, File.join(dirname, "#{basename}_direct#{extname}"))
    generate_glued_logo(alignment_infos, options, :revcomp, File.join(dirname, "#{basename}_revcomp#{extname}"))
  else
    generate_glued_logo(alignment_infos, options, total_orientation, output_file)
  end

rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end