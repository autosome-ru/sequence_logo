require_relative 'canvases'
require_relative 'canvas_factory'
require_relative 'alignment'
require_relative 'data_models'
require_relative 'ytilib'

module SequenceLogo
  def self.draw_ppm_logo(ppm, options = {})
    scheme_dir = File.join(AssetsPath, options[:scheme])
    letter_images = CanvasFactory.letter_images(scheme_dir)
    canvas_factory = CanvasFactory.new(letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit])
    PPMLogo.new(ppm,
                icd_mode: options[:icd_mode],
                words_count: options[:words_count],
                enable_threshold_lines: options[:threshold_lines]).render(canvas_factory)
  end

  def self.draw_sequence_logo(sequence, options = {})
    scheme_dir = File.join(AssetsPath, options[:scheme])
    letter_images = CanvasFactory.letter_images(scheme_dir)
    canvas_factory = CanvasFactory.new(letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit])
    Sequence.new(sequence).render(canvas_factory)
  end

  def self.draw_sequence_w_snp_logo(sequence_w_snp, options = {})
    scheme_dir = File.join(AssetsPath, options[:scheme])
    letter_images = CanvasFactory.letter_images(scheme_dir)
    canvas_factory = CanvasFactory.new(letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit])
    SequenceWithSNP.from_string(sequence_w_snp).render(canvas_factory)
  end
end
