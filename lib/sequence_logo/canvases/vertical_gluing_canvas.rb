require_relative 'gluing_canvas'

module SequenceLogo
  class VerticalGluingCanvas < GluingCanvas
    def add_image(image)
      super
      @i_logo.put_image_at(image, 0, y_size)
    end

    def x_size
      @i_logo.to_a.map(&:columns).max || 0
    end

    def y_size
      @i_logo.to_a.map(&:rows).inject(0, :+)
    end
  end
end
