module SequenceLogo
  class PredefinedLogo
    attr_reader :direct_image, :reverse_image
    def initialize(options = {})
      @direct_image = options[:direct_image]
      @reverse_image = options[:reverse_image]
      @name = options[:name]
      @length = options[:length]
    end

    def length
      raise 'Length not defined'  unless @length
      @length
    end

    def name
      raise 'Name not defined'  unless @name
      @name
    end

    def revcomp
      PredefinedLogo.new(direct_image: @reverse_image, reverse_image: @direct_image, name: @name, length: @length)
    end

    def render(canvas_factory)
      layers = Magick::ImageList.new
      layers.put_image_at(@direct_image, 0, 0)
      layers.unshift Magick::Image.new(@direct_image.columns, @direct_image.rows, canvas_factory.background_fill)
      layers.flatten_images
    end
  end
end
