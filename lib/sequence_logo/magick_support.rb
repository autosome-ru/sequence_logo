require 'rmagick'

module Magick
  class ImageList
    def put_image_at(image, x, y)
      self << image
      cur_image.page = Magick::Rectangle.new(0, 0, x, y)
    end

    # add transparent layer so that full canvas size can't be less than given size
    def set_minimal_size(x_size, y_size)
      empty_image = Magick::Image.new(x_size, y_size){ self.background_color = 'transparent'}
      self.unshift(empty_image)
    end
  end

  class SolidFill
    def initialize(bgcolor)
      @bgcolor = bgcolor
    end

    def fill(img)
      img.background_color = @bgcolor
      img.erase!
    end
  end
end
