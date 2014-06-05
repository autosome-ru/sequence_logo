require_relative 'sequence'
require_relative '../canvases'

module SequenceLogo
  class SequenceWithSNP
    attr_reader :left, :allele_variants, :right, :name
    def initialize(left, allele_variants, right, options = {})
      raise unless Sequence.valid_sequence?(left)
      raise unless Sequence.valid_sequence?(right)
      raise unless allele_variants.all?{|letter| %w[A C G T].include?(letter.upcase) }
      @left, @allele_variants, @right = left, allele_variants, right
      @name = options[:name] || (left + '_' + allele_variants.join('-') + '_' + right)
    end

    def self.from_string(sequence, options = {})
      left, mid, right = sequence.split(/[\[\]]/)
      allele_variants = mid.split('/')
      SequenceWithSNP.new(left, allele_variants, right, options)
    end

    def length
      left.length + 1 + right.length
    end

    def revcomp
      SequenceWithSNP.new(Sequence.revcomp(right),
                          allele_variants.map{|letter| Sequence.complement(letter) },
                          Sequence.revcomp(left))
    end

    def render(canvas_factory)
      canvas = LogoCanvas.new(canvas_factory)
      canvas.background(canvas_factory.background_fill)
      left.each_char{|letter| canvas.add_letter(letter) }
      canvas.add_position_ordered(snp_position_heights)
      right.each_char{|letter| canvas.add_letter(letter) }
      canvas.image
    end

    def snp_position_heights
      allele_variants.map{|letter| [1.0 / allele_variants.size, letter] }
    end
    private :snp_position_heights
  end
end
