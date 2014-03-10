require_relative 'ytilib'
require 'RMagick'

module SequenceLogo
  def self.draw_threshold_lines(i_logo, ppm)
    x_size = i_logo.columns
    y_size = i_logo.rows

    line2of4 = y_size - ppm.get_line(ppm.icd2of4) * y_size
    lineThc = y_size - ppm.get_line(ppm.icdThc) * y_size
    lineTlc = y_size - ppm.get_line(ppm.icdTlc) * y_size

    dr = Magick::Draw.new
    dr.fill('transparent')

    dr.stroke_width(y_size / 200.0)
    dr.stroke_dasharray(7,7)

    dr.stroke('silver')
    dr.line(0, line2of4, x_size, line2of4)
    dr.line(0, lineThc, x_size, lineThc)
    dr.line(0, lineTlc, x_size, lineTlc)

    dr.draw(i_logo)
  end

  def self.create_canvas(ppm, options)
    x_size = options[:x_unit] * ppm.length
    y_size = options[:y_unit]

    i_logo = Magick::ImageList.new
    if options[:icd_mode] == :discrete
      i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'white'))
      draw_threshold_lines(i_logo, ppm)  if options[:threshold_lines]
    else
      i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'bisque'))
    end

    i_logo
  end

  def self.letter_image(images, letter_index, x_size, y_size)
    images[letter_index].dup.resize(x_size, y_size)
  end

  def self.letter_images(scheme_dir)
    if File.exist?(File.join(scheme_dir,'a.png'))
      extension = 'png'
    elsif File.exist?(File.join(scheme_dir,'a.gif'))
      extension = 'gif'
    else
      raise "Scheme not exists in folder #{scheme_dir}"
    end

    letter_files = %w[a c g t].collect{|letter| File.join(scheme_dir, "#{letter}.#{extension}") }
    Magick::ImageList.new(*letter_files)
  end

  # Takes a matrix with letter heights and draws a logo with tall to short letters at each position
  def self.draw_letters_on_canvas(i_logo, i_letters, matrix, options)
    y_unit = options[:y_unit]
    x_unit = options[:x_unit]
    matrix.each_with_index do |position, i|
      y_pos = 0
      position.each_with_index.sort_by{|count, letter_index| count }.reverse_each do |count, letter_index|
        next  if y_unit * count <= 1
        y_block = (y_unit * count).round
        y_pos += y_block
        i_logo << letter_image(i_letters, letter_index, x_unit, y_block)
        i_logo.cur_image.page = Magick::Rectangle.new(0, 0, i * x_unit, y_unit - y_pos )
      end
    end
  end

  def self.draw_logo(ppm, options = {})
    ppm.words_count = options[:words_count]  if options[:words_count]
    unless ppm.words_count
      report "words count for PPM is undefined, assuming weblogo mode"
      options[:icd_mode] = :weblogo
    end
    i_logo = create_canvas(ppm, options)
    scheme_dir = File.join(AssetsPath, options[:scheme])
    draw_letters_on_canvas(i_logo, letter_images(scheme_dir), ppm.get_logo(options[:icd_mode]), options)
    i_logo = i_logo.flatten_images
  end

  # logos = { filename => {shift: ..., length: ..., name: ...} }
  def self.glue_files(logos, output_file, options)
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
end
