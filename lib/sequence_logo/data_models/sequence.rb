require_relative '../canvases'

module SequenceLogo
  class Sequence
    attr_reader :sequence, :name
    def initialize(sequence, options = {})
      raise 'Wrong sequence' unless Sequence.valid_sequence?(sequence)
      @sequence = sequence
      @name = options[:name] || sequence
    end

    def length
      sequence.length
    end

    def revcomp
      Sequence.new(Sequence.revcomp(sequence), name: name)
    end

    def render(canvas_factory)
      canvas = LogoCanvas.new(canvas_factory)
      canvas.background(canvas_factory.background_fill)
      sequence.each_char do |letter|
        canvas.add_letter(letter)
      end
      canvas.image
    end

    def self.complement(sequence)
      sequence.tr('acgtACGT', 'tgcaTGCA')
    end
    def self.revcomp(sequence)
      complement(sequence).reverse
    end

    def self.valid_sequence?(sequence)
      sequence.match /\A[acgt]+\z/i
    end
  end
end
