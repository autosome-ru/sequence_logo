require_relative 'gluing_canvas'

module SequenceLogo
  class HorizontalGluingCanvas < GluingCanvas
    alias_method :length, :size

    def add_image(image)
      super
      @i_logo.put_image_at(image, x_size, 0)
    end

    def x_size
      @i_logo.to_a.map(&:columns).inject(0, :+)
    end

    def y_size
      @i_logo.to_a.map(&:rows).max || 0
    end
  end
end
