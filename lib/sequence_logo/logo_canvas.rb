require 'RMagick'

module SequenceLogo
  class LogoCanvas
    attr_reader :i_logo, :x_unit, :y_unit, :length
    attr_reader :letter_images
    def x_size; x_unit * length; end
    def y_size; y_unit; end

    def initialize(length, letter_images, options = {})
      @length = length
      @x_unit = options[:x_unit] || 30
      @y_unit = options[:y_unit] || 60
      @letter_images = letter_images

      @i_logo = Magick::ImageList.new
      @i_logo.new_image(x_size, y_size){ self.background_color = 'transparent' }
      @shift = 0
    end

    def background(fill)
      @i_logo.unshift Magick::Image.new(x_size, y_size, fill)
    end

    # Takes an enumerable with count=>letter pairs draws a logo position with letters in order of enumeration
    def logo_for_position_ordered(letters_by_counts)
      position_logo = Magick::ImageList.new
      position_logo.new_image(x_unit, y_unit){ self.background_color = 'transparent' }
      y_pos = 0
      letters_by_counts.each do |count, letter_index|
        next  if y_unit * count <= 1
        y_block = (y_unit * count).round
        y_pos += y_block
        position_logo << letter_image(letter_index, x_unit, y_block)
        position_logo.cur_image.page = Magick::Rectangle.new(0, 0, 0, y_unit - y_pos)
      end
      position_logo.flatten_images
    end

    # add logo of position to subsequent position
    def add_position_logo(logo)
      @i_logo << logo
      @i_logo.cur_image.page = Magick::Rectangle.new(0, 0, @shift * x_unit, 0)
      @shift += 1
    end

    # Takes an array with letter heights and draws a logo position with tall to short letters at each position
    def logo_for_positon(position)
      add_position_logo(logo_for_position_ordered( position_sorted_by_count(position) ))
    end

    def draw_logo(logo_matrix)
      logo_matrix.each{|position|  logo_for_positon(position)  }
    end

    def letter_image(letter_index, x_size, y_size)
      letter_images[letter_index].dup.resize(x_size, y_size)
    end

    def draw_threshold_line(threshold_level)
      y_coord = y_size - threshold_level * y_size
      dr = Magick::Draw.new
      dr.fill('transparent')

      dr.stroke_width(y_size / 200.0)
      dr.stroke_dasharray(7,7)

      dr.stroke('silver')
      dr.line(0, y_coord, x_size, y_coord)
      dr.draw(@i_logo)
    end

    def logo
      @i_logo.flatten_images
    end

    # [3,1,1,2] ==> [[3, 0],[2, 3],[1, 1],[1, 2]] (derived from [[3, 'A'],[2,'T'],[1,'C'],[1,'G']])
    def position_sorted_by_count(position)
      # sort by [count, letter_index] allows us to make stable sort by count (it's useful for predictable order of same-height nucleotides)
      position.each_with_index.sort_by{|count, letter_index| [count, letter_index] }.reverse
    end
  end
end
