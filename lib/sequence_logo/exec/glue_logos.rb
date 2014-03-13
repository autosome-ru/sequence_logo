require_relative '../../sequence_logo'
require 'fileutils'
require 'cgi'
require 'tempfile'


class GlueLogos
  # named logo image with shist
  class Logo
    attr_accessor :image, :shift, :name
    def initialize(image, shift, name)
      @image, @shift, @name = image, shift, name
    end
    def width
      image.columns
    end
    def shifted_by(shift_by)
      Logo.new(image, shift + shift_by, name)
    end
  end

  # list of named logos with shifts and operations to normalize them
  class List
    def initialize(logos = [])
      @logos = logos
    end

    def add_logo(image, shift, name)
      @logos << Logo.new(image, shift, name)
    end

    def leftmost_shift
      @logos.map(&:shift).min
    end

    def logos
      shift = leftmost_shift
      @logos.map{|logo| logo.shifted_by(-shift) }
    end

    # imput is a hash: {filename => {name: , shift: }}
    def self.new_from_hash(logos_hash)
      logos_list = GlueLogos::List.new
      logos_hash.each do |filename, infos|
        logos_list.add_logo(Magick::Image.read(filename)[0], infos[:shift], infos[:name])
      end
      logos_list
    end
  end

  class Canvas
    attr_reader :x_unit, :y_unit, :text_size, :logo_shift, :i_logo
    def initialize(options = {})
      @logo_shift = options[:logo_shift] || 300
      @x_unit = options[:x_unit] || 30
      @y_unit = options[:y_unit] || 60
      @text_size = options[:text_size] || 24

      @i_logo = Magick::ImageList.new
      @index = 0
    end

    def put_image_at(image_list, image, x, y)
      image_list << image
      image_list.cur_image.page = Magick::Rectangle.new(0, 0, x, y)
    end

    # add transparent layer so that full canvas size can't be less than given size
    def set_minimal_size(image_list, x_size, y_size)
      empty_image = Magick::Image.new(x_size, y_size){ self.background_color = 'transparent'}
      image_list.unshift(empty_image)
    end

    def text_image(text)
      text_img = Magick::Image.new(logo_shift, y_unit){ self.background_color = 'transparent' }
      annotation = Magick::Draw.new
      annotation.pointsize(text_size)
      annotation.text(10, y_unit / 2, text)
      annotation.draw(text_img)
      text_img
    end

    def logo_with_name(image, name)
      named_logo = Magick::ImageList.new
      set_minimal_size(named_logo, logo_shift + image.columns, y_unit)
      put_image_at(named_logo, text_image(name), 0, 0)
      put_image_at(named_logo, image, logo_shift, 0)
      named_logo.flatten_images
    end

    def shifted_logo(image, shift)
      shifted_logo = Magick::ImageList.new
      set_minimal_size(shifted_logo, shift * x_unit + image.columns, y_unit)
      put_image_at(shifted_logo, image, shift * x_unit, 0)
      shifted_logo.flatten_images
    end

    def render_logo(logo)
      put_image_at(@i_logo, logo_with_name(shifted_logo(logo.image, logo.shift), logo.name), 0, @index * y_unit)
      @index += 1
    end

    def x_size
      @i_logo.to_a.map(&:columns).max
    end

    def y_size
      @i_logo.to_a.map(&:rows).inject(0, :+)
    end
    
    def background(fill)
      @i_logo.unshift Magick::Image.new(x_size, y_size, fill)
    end

    def image
      set_minimal_size(@i_logo, x_size, y_size)
      @i_logo.flatten_images
    end
  end
end

# logos = { filename => {shift: ..., length: ..., name: ...} }
def glue_files(logos, output_file, options)
  logos_list = GlueLogos::List.new_from_hash(logos)
  
  canvas = GlueLogos::Canvas.new(options)
  logos_list.logos.each do |logo|
    canvas.render_logo(logo)
  end
  canvas.image.write('PNG:' + output_file)
end


class Alignment
  def initialize

  end
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