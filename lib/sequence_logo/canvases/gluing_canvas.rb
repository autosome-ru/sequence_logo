require_relative '../magick_support'

module SequenceLogo
  class GluingCanvas
    attr_reader :i_logo, :size
    def initialize
      @i_logo = Magick::ImageList.new
      @size = 0
      @rendering_callbacks = []
      @rendering_callbacks << method(:render_background)
    end

    def image
      @rendering_callbacks.each(&:call)
      @i_logo.flatten_images
    end

    def background(fill)
      @background_fill = fill
    end

    def render_background
      if @background_fill
        @i_logo.unshift Magick::Image.new(x_size, y_size, @background_fill)
      else
        @i_logo.set_minimal_size(x_size, y_size)
      end
    end
    private :render_background

    def add_image(item)
      @size += 1
    end
  end
end
