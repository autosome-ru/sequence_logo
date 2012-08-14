require 'sequence_logo/ytilib'
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
    if options[:paper_mode]
      i_logo.new_image(x_size, y_size)
    else
      if options[:icd_mode] == :discrete
        i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'white'))
        draw_threshold_lines(i_logo, ppm)  if options[:threshold_lines]
      else
        i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'bisque'))
      end
    end
    i_logo
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

  def self.draw_letters_on_canvas(i_logo, i_letters, ppm, options)
    y_unit = options[:y_unit]
    x_unit = options[:x_unit]
    matrix = ppm.get_logo(options[:icd_mode])
    matrix['A'].each_index { |i|
      y_pos = 0
      sorted_letters = ['A', 'C', 'G', 'T'].collect { |letter| {:score => matrix[letter][i], :letter => letter} }.sort_by { |pair| pair[:score] }.collect { |pair| pair[:letter] }.reverse
      sorted_letters.each { |letter|
        next if y_unit * matrix[letter][i] <= 1
        letter_index = {'A' => 0, 'C' => 1, 'G' => 2, 'T' => 3}[letter]
        y_block = (y_unit * matrix[letter][i]).round
        i_logo << i_letters[letter_index].dup.resize(x_unit, y_block)
        y_pos += y_block
        i_logo.cur_image.page = Magick::Rectangle.new(0, 0, i * x_unit, y_unit - y_pos )
      }
    }
  end

  def self.process_options_hash_for_logo(options = {})
    default_options = { words_count: nil,
                        x_unit: 100,
                        y_unit: 200,
                        icd_mode: 'discrete',
                        revcomp: false,
                        scheme: 'nucl_simpa',
                        paper_mode: false,
                        threshold_lines: true }
    
    options = options.reject{|k,v| v == 'default' || v == :default}
    options = default_options.merge( options )
    options[:x_unit] = options[:x_unit].to_i
    options[:y_unit] = options[:y_unit].to_i
    options[:icd_mode] = options[:icd_mode].to_sym
    options[:words_count] = options[:words_count].to_f  if options[:words_count]
    options[:revcomp] = false  if options[:revcomp] == 'no' || options[:revcomp] == 'false' || options[:revcomp] == 'direct'
    options[:paper_mode] = false  if options[:paper_mode] == 'no' || options[:paper_mode] == 'false'
    options[:threshold_lines] = false  if options[:threshold_lines] == 'no' || options[:threshold_lines] == 'false'
    
    options
  end

  def self.draw_logo(ppm, options = {})
    options = process_options_hash_for_logo(options)
    
    ppm.words_count = options[:words_count]  if options[:words_count]
    
    unless ppm.words_count
      report "words count for PPM is undefined, assuming weblogo mode"
      options[:icd_mode] = :weblogo
    end
    
    i_logo = create_canvas(ppm, options)
    
    ppm = ppm.revcomp if options[:revcomp]

    scheme_dir = File.join(AssetsPath, options[:scheme])
    draw_letters_on_canvas(i_logo, letter_images(scheme_dir), ppm, options)

    i_logo = i_logo.flatten_images
    
    if options[:paper_mode]
      border_thickness = options[:x_unit] / 100 + 1
      border_color = (options[:icd_mode] == :discrete) ? 'green' : 'red'
      i_logo.cur_image.border!(border_thickness, border_thickness, border_color)
    end
    
    i_logo
  end

  # logos = { filename => {shift: ..., length: ..., name: ...} }
  def self.glue_files(logos, output_file, logo_shift = 300, x_unit = 30, y_unit = 60)
    leftmost_shift = logos.map{|file,infos| infos[:shift] }.min
    logos.each{|file, infos| infos[:shift] -= leftmost_shift}
    full_alignment_size = logos.map{|file,infos| infos[:length] + infos[:shift] }.max
    
    x_size = logo_shift + full_alignment_size * x_unit
    y_size = logos.size * y_unit
    command_string = "convert -size #{ x_size }x#{ y_size } -pointsize 24 xc:white "
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

  # ppms {ppm => shift}
  def self.glue_ppms(ppms, output_file, logo_shift = 300, x_unit = 30, y_unit = 60)
    logos = {}
    filenames = []
    ppms.each do |ppm, motif_shift|
      name = "#{name}_tmp.png"
      filenames << name
      draw_logo(ppm, x_unit: x_unit, y_unit: y_unit, revcomp: 'direct').write(name)
      logos[name] = {length: ppm.length, name: ppm.name, shift: motif_shift}
    end
    glue_files(logos, output_file, logo_shift, x_unit, y_unit)
    filenames.each{|filename| File.delete(filename)}
  end
end