require_relative '../../sequence_logo'
require 'shellwords'

begin
  include SequenceLogo

  doc = <<-EOS
  sequence_logo is a tool for drawing motif logos. It is able to process PCM files either as a position matrix (*.pat or *.pcm), or in FASTA format (file extensions: .mfa, .fasta, .plain), or in SMall BiSMark format (.xml), or in IUPAC format (any other extension).
  Usage:
    sequence_logo [options] <pcm/ppm file>...
      or
    ls pcm_folder/*.pcm | sequence_logo [options]
  EOS

  argv = ARGV
  default_options = {x_unit: 30, y_unit: 60, words_count: nil, orientation: :direct, logo_folder: '.', icd_mode: :discrete, threshold_lines: true, scheme: 'nucl_simpa'}
  cli = SequenceLogo::CLI.new(default_options)
  cli.instance_eval do
    parser.banner = doc
    parser.on_head('--logo-folder FOLDER', 'Folder to store generated logos') do |v|
      options[:logo_folder] = v
    end
    parser.on_head('--orientation ORIENTATION', 'Which logo to draw: direct/revcomp/both') do |v|
      v = v.to_sym
      raise ArgumentError, 'Orientation can be either direct or revcomp or both'  unless [:direct, :revcomp, :both].include?(v)
      options[:orientation] = v
    end

    parser.on('--snp-sequence SEQUENCE', 'Specify sequence with SNP (like ATCTC[C/G]CCTAAT) instead of motif') do |v|
      options[:sequence_w_snp] = v
    end
    parser.on('--sequence SEQUENCE', 'Specify sequence (like ATCTCGCCTAAT) instead of motif') do |v|
      options[:sequence] = v
    end
  end
  options = cli.parse_options!(argv)

  logo_folder = options[:logo_folder]
  Dir.mkdir(logo_folder)  unless Dir.exist?(logo_folder)

  scheme_dir = File.join(SequenceLogo::AssetsPath, options[:scheme])
  letter_images = SequenceLogo::CanvasFactory.letter_images(scheme_dir)
  canvas_factory = SequenceLogo::CanvasFactory.new(letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit])

  raise "Specify either sequence or sequence with SNP, not both"  if options[:sequence] && options[:sequence_w_snp]
  raise "Can't yet draw reverse complement of sequence/sequence with SNP due to uncertainity with output filename. Next version will fix this"  if (options[:sequence] || options[:sequence_w_snp]) && options[:orientation] != :direct

  objects_to_render = []
  if options[:sequence]
    sequence = options[:sequence]
    objects_to_render << {renderable: SequenceLogo::Sequence.new(sequence),
                          output_filename: File.join(logo_folder, "#{sequence}.png")}
  elsif options[:sequence_w_snp]
    sequence_w_snp = options[:sequence_w_snp]
    objects_to_render << {renderable: SequenceLogo::SequenceWithSNP.from_string(sequence_w_snp),
                          output_filename: File.join(logo_folder, sequence_w_snp.gsub(/[\[\]\/]/, '_') + ".png")}
  else
    filenames = argv
    filenames += $stdin.read.shellsplit  unless $stdin.tty?
    raise ArgumentError, 'Specify at least one motif file'  if filenames.empty? && !options[:sequence] && !options[:sequence_w_snp]

    filenames.each do |filename|
      ppm = get_ppm_from_file(filename)
      checkerr("bad input file: #{filename}") { ppm == nil }

      logo = SequenceLogo::PPMLogo.new( ppm,
                                        icd_mode: options[:icd_mode],
                                        words_count: options[:words_count],
                                        enable_threshold_lines: options[:threshold_lines])

      filename_wo_ext = File.basename_wo_extname(filename)
      if [:direct, :both].include?(options[:orientation])
        objects_to_render << {renderable: logo, output_filename: File.join(logo_folder, "#{filename_wo_ext}_direct.png")}
      end
      if [:revcomp, :both].include?(options[:orientation])
        objects_to_render << {renderable: logo.revcomp, output_filename: File.join(logo_folder, "#{filename_wo_ext}_revcomp.png")}
      end
    end
  end

  objects_to_render.each do |infos|
    infos[:renderable].render(canvas_factory).write("PNG:#{infos[:output_filename]}")
  end
rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end
