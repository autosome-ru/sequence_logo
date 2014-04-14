require_relative 'magick_support'
require_relative 'canvases'

module SequenceLogo
  class CanvasFactory
    attr_reader :x_unit, :y_unit, :text_size, :logo_shift
    attr_reader :letter_images

    def initialize(letter_images, options = {})
      @letter_images = letter_images # .map{|letter_image| letter_image.dup.resize(x_size, y_size) }
      @logo_shift = options[:logo_shift] || 300
      @x_unit = options[:x_unit] || 30
      @y_unit = options[:y_unit] || 60
      @text_size = options[:text_size] || 24
    end

    def text_image(text, img_height = y_unit)
      text_img = Magick::Image.new(logo_shift, img_height){ self.background_color = 'transparent' }
      annotation = Magick::Draw.new
      annotation.pointsize(text_size)
      annotation.text(10, img_height / 2, text)
      annotation.draw(text_img)
      text_img
    end

    def shifted_logo(image, shift)
      # shifted_logo = Magick::ImageList.new
      # shifted_logo.set_minimal_size(shift * x_unit + image.columns, image.rows)
      # shifted_logo.put_image_at(image, shift * x_unit, 0)
      # shifted_logo.flatten_images
      canvas = HorizontalGluingCanvas.new
      canvas.add_image Magick::Image.new(shift * x_unit, image.rows){ self.background_color = 'transparent' }
      canvas.add_image image
      canvas.image
    end

    def logo_with_name(image, name)
      # named_logo = Magick::ImageList.new
      # named_logo.set_minimal_size(logo_shift + image.columns, image.rows)
      # named_logo.put_image_at(text_image(name, image.rows), 0, 0)
      # named_logo.put_image_at(image, logo_shift, 0)
      # named_logo.flatten_images
      canvas = HorizontalGluingCanvas.new
      canvas.add_image text_image(name, image.rows)
      canvas.add_image image
      canvas.image
    end

    def logo_canvas
      LogoCanvas.new(letter_images, x_unit: x_unit, y_unit: y_unit)
    end

    # Takes an enumerable with relative (0 to 1) heights of letters and draws them scaled appropriately
    def logo_for_ordered_letters(letters_with_heights)
      logo_for_ordered_letters_nonscaling(rescale_letters(letters_with_heights))
    end

    # Takes an enumerable with height=>letter pairs draws a logo position with letters in order of enumeration
    # It's a basic logo-block.
    def logo_for_ordered_letters_nonscaling(letters_with_heights)
      y_pos = 0
      position_logo = Magick::ImageList.new
      position_logo.set_minimal_size(x_unit, y_unit)
      letters_with_heights.each do |height, letter|
        y_pos += height
        position_logo.put_image_at(letter_image(letter, x_unit, height), 0, y_unit - y_pos)
      end
      position_logo.flatten_images
    end

    def rescale_letters(letters_with_heights)
      letters_with_heights
        .reject{|part_of_height, letter| y_unit * part_of_height <= 1 }
        .map{|part_of_height, letter| [(y_unit * part_of_height), letter] }
    end
    private :logo_for_ordered_letters_nonscaling, :rescale_letters

    def letter_image(letter, x_size = x_unit, y_size = y_unit)
      case letter
      when Numeric
        index = letter
      else
        index = letter_index(letter)
      end
      letter_images[index].dup.resize(x_size, y_size)
    end

    def letter_index(letter)
      {'A' => 0 ,'C' => 1,'G' => 2 ,'T' => 3}[letter.upcase]
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
  end
end
