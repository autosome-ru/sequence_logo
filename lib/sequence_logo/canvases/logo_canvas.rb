require 'RMagick'
require_relative '../magick_support'
require_relative 'horizontal_gluing_canvas'

module SequenceLogo
  class LogoCanvas < HorizontalGluingCanvas
    attr_reader :canvas_factory
    def initialize(canvas_factory)
      super()
      @canvas_factory = canvas_factory
    end

    def draw_threshold_line(threshold_level)
      # stores threshold levels but doesn't render them because full length of canvas is not known yet,
      # so instantly rendered line would be too short
      @rendering_callbacks.push ->{ render_threshold_line(threshold_level) }
    end

    def render_threshold_line(threshold_level)
      y_coord = y_size - threshold_level * y_size
      dr = Magick::Draw.new
      dr.fill('transparent')

      dr.stroke_width(y_size / 200.0)
      dr.stroke_dasharray(7,7)

      dr.stroke('silver')
      dr.line(0, y_coord, x_size, y_coord)
      dr.draw(@i_logo)
    end

    def add_letter(letter)
      add_image( canvas_factory.letter_image(letter) )
    end

    def add_position_ordered(ordered_letter_heights)
      add_image( canvas_factory.logo_for_ordered_letters(ordered_letter_heights) )
    end
  end
end
