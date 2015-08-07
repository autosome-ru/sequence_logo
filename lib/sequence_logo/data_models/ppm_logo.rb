require_relative '../canvases'

module SequenceLogo
  # wrapper around PPM to make it possible to configure rendering in a flexible way
  class PPMLogo
    attr_reader :ppm, :icd_mode, :enable_threshold_lines

    def initialize(ppm, options = {})
      @ppm = ppm
      @icd_mode = options[:icd_mode]
      @enable_threshold_lines = options[:enable_threshold_lines]
    end

    def length
      ppm.length
    end

    def name
      ppm.name
    end

    def revcomp
      PPMLogo.new(ppm.revcomp, icd_mode: icd_mode, enable_threshold_lines: enable_threshold_lines)
    end

    def logo_matrix
      ppm.get_logo(icd_mode)
    end

    def render(canvas_factory)
      canvas = LogoCanvas.new(canvas_factory)
      canvas.background(canvas_factory.background_fill)
      word_count = ppm.each_position.map{|pos| pos.inject(0.0, &:+) }.max
      if icd_mode == :discrete && enable_threshold_lines
        canvas.draw_threshold_line( scale(icd2of4(word_count), relative_to: icd4of4(word_count)) )
        canvas.draw_threshold_line( scale(icdThc(word_count),  relative_to: icd4of4(word_count)) )
        canvas.draw_threshold_line( scale(icdTlc(word_count),  relative_to: icd4of4(word_count)) )
      end

      logo_matrix.each do |position|
        canvas.add_position_ordered( position_sorted_by_height(position) )
      end
      canvas.image
    end

    # [3,1,1,2] ==> [[3, 0],[2, 3],[1, 1],[1, 2]] (derived from [[3, 'A'],[2,'T'],[1,'C'],[1,'G']])
    def position_sorted_by_height(position)
      # sort by [count, letter_index] allows us to make stable sort by count (it's useful for predictable order of same-height nucleotides)
      position.each_with_index.sort_by{|count, letter_index| [count, letter_index] }.reverse
    end
    private :position_sorted_by_height
  end
end
