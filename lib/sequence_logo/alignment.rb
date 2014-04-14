require_relative 'canvases'

module SequenceLogo
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

      def render(canvas_factory)
        object_image = object.render(canvas_factory)
        shifted_image = canvas_factory.shifted_logo(object_image, shift)
        canvas_factory.logo_with_name(shifted_image, name)
      end
    end

  ####################

    def initialize(items = [])
      @alignable_items = items
    end

    def +(item)
      Alignment.new(@alignable_items + [item])
    end

    def revcomp
      items_reversed = @alignable_items.map{|item|
        shift_reversed = rightmost_position - item.shift - item.length
        Item.new(item.object.revcomp, shift_reversed)
      }
      Alignment.new(items_reversed)
    end

    def render(canvas_factory)
      canvas = VerticalGluingCanvas.new
      items_normalized.each do |item|
        canvas.add_image item.render(canvas_factory)
      end
      canvas.background(Magick::HatchFill.new('white', 'white'))
      canvas.image
    end

  private

    # return list of items shifted altogether such that minimal shift is zero
    def items_normalized
      @alignable_items.map{|item| Item.new(item.object, item.shift - leftmost_shift) }
    end

    def leftmost_shift
      @alignable_items.map(&:shift).min
    end

    def rightmost_position
      @alignable_items.map{|item| item.shift + item.length  }.max
    end
  end
end
