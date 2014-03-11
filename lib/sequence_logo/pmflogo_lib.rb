require_relative 'logo_canvas'
require_relative 'ytilib'

module SequenceLogo
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

  def self.draw_ppm_logo(ppm, options = {})
    ppm.words_count = options[:words_count]  if options[:words_count]
    unless ppm.words_count
      report "words count for PPM is undefined, assuming weblogo mode"
      options[:icd_mode] = :weblogo
    end

    scheme_dir = File.join(AssetsPath, options[:scheme])
    letter_images = letter_images(scheme_dir)
    LogoCanvas.new(ppm.length, letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit]) do |canvas|
      if options[:icd_mode] == :discrete
        canvas.background(Magick::HatchFill.new('white', 'white'))
        if options[:threshold_lines]
          canvas.draw_threshold_line(ppm.get_line(ppm.icd2of4))
          canvas.draw_threshold_line(ppm.get_line(ppm.icdThc))
          canvas.draw_threshold_line(ppm.get_line(ppm.icdTlc))
        end
      else
        canvas.background(Magick::HatchFill.new('white', 'bisque'))
      end
      canvas.draw_logo( ppm.get_logo(options[:icd_mode]) )
    end.logo
  end

  def self.draw_sequence_logo(sequence, options = {})
    scheme_dir = File.join(AssetsPath, options[:scheme])
    letter_images = letter_images(scheme_dir)
    LogoCanvas.new(sequence.length, letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit]) do |canvas|
      canvas.background(Magick::HatchFill.new('white', 'white'))
      canvas.draw_logo( logo_matrix_by_sequence(sequence) )
    end.logo
  end

  def self.draw_sequence_w_snp_logo(sequence_w_snp, options = {})
    left, mid, right = sequence_w_snp.split(/[\[\]]/)
    allele_variants = mid.split('/').map(&:upcase)
    snp_counts = allele_variants.map{|letter| [1.0 / allele_variants.size, letter_index(letter)] }

    scheme_dir = File.join(AssetsPath, options[:scheme])
    letter_images = letter_images(scheme_dir)
    LogoCanvas.new(left.length + 1 + right.length, letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit]) do |canvas|
      canvas.background(Magick::HatchFill.new('white', 'white'))

      logo_matrix_by_sequence(left).each{|position|  canvas.logo_for_positon(position)  }
      canvas.add_position_logo(canvas.logo_for_position_ordered(snp_counts))
      logo_matrix_by_sequence(right).each{|position|  canvas.logo_for_positon(position)  }
    end.logo
  end

  def self.letter_index(letter)
    {'A' => 0 ,'C' => 1,'G' => 2 ,'T' => 3}[letter.upcase]
  end

  def self.logo_matrix_by_sequence(sequence)
    sequence.each_char.map{|letter| letter_index(letter) }.map{|letter_index| 4.times.map{|i| i == letter_index ? 1.0 : 0.0 }}
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
