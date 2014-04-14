class CanvasConfigurator
  attr_reader :x_unit, :y_unit, :text_size, :logo_shift
  def initialize(options = {})
    @logo_shift = options[:logo_shift] || 300
    @x_unit = options[:x_unit] || 30
    @y_unit = options[:y_unit] || 60
    @text_size = options[:text_size] || 24
  end

  def text_image(text)
    text_img = Magick::Image.new(logo_shift, y_unit){ self.background_color = 'transparent' }
    annotation = Magick::Draw.new
    annotation.pointsize(text_size)
    annotation.text(10, y_unit / 2, text)
    annotation.draw(text_img)
    text_img
  end

  def shifted_logo(image, shift)
    shifted_logo = Magick::ImageList.new
    set_minimal_size(shifted_logo, shift * x_unit + image.columns, y_unit)
    put_image_at(shifted_logo, image, shift * x_unit, 0)
    shifted_logo.flatten_images
  end

  def logo_with_name(image, name)
    named_logo = Magick::ImageList.new
    set_minimal_size(named_logo, logo_shift + image.columns, y_unit)
    put_image_at(named_logo, text_image(name), 0, 0)
    put_image_at(named_logo, image, logo_shift, 0)
    named_logo.flatten_images
  end

  # add transparent layer so that full canvas size can't be less than given size
  def set_minimal_size(image_list, x_size, y_size)
    empty_image = Magick::Image.new(x_size, y_size){ self.background_color = 'transparent'}
    image_list.unshift(empty_image)
  end
end

class Alignment
  # object to be aligned should respond to #name, #render, #revcomp
  class Item
    attr_reader :object, :shift
    def initialize(object, shift)
      @object, @shift = object, shift
    end
    def length
      @object.length
    end
    def name
      @object.name
    end
    def revcomp_object
      object.revcomp
    end
    def render(canvas_configurator)
      shifted_image = canvas_configurator.shifted_logo(object.render)
      canvas_configurator.logo_with_name(shifted_image, name)
    end
  end

  def initialize(items = [])
    @alignable_items = items
  end

  def revcomp
    items_reversed = alignable_items.map{|item|
      shift_reversed = rightmost_position - item.shift - item.length
      Item.new(item.revcomp_object, shift_reversed, orientation_reversed)
    }
    Alignment.new(items_reversed)
  end

  def render(canvas)
    items_normalized.each do |item|
      # canvas.render(item.render())
      # canvas.render_logo(logo)
    end
  end

  # return list of items shifted altogether such that minimal shift is zero
  def items_normalized
    @alignable_items.map{|item| Item.new(item.object, item.shift - leftmost_shift) }
  end

  def leftmost_shift
    @alignable_items.map(&:shift).min
  end

  def rightmost_position
    @alignable_items.map{|item|| item.shift + item.length  }.max
  end
  private :items_normalized, :leftmost_shift, :rightmost_position
end
