require_relative '../../sequence_logo'
require 'shellwords'

# [{renderable: , name: }] --> [{renderable: , filename: }]
def in_necessary_orientations(objects_to_render, orientation, logo_folder)
  objects_to_render.map do |infos|
    case orientation
    when :direct
      {renderable: infos[:renderable], filename: "#{infos[:name]}.png" }
    when :revcomp
      {renderable: infos[:renderable].revcomp, filename: "#{infos[:name]}.png" }
    when :both
      [ {renderable: infos[:renderable], filename: "#{infos[:name]}_direct.png" },
        {renderable: infos[:renderable].revcomp, filename: "#{infos[:name]}_revcomp.png" } ]
    end
  end.flatten
end

def arglist_augmented_with_stdin(argv)
  result = argv
  result += $stdin.read.shellsplit  unless $stdin.tty?
  result
end

begin
  include SequenceLogo

  doc = <<-EOS
  sequence_logo is a tool for drawing motif and sequence logos
  It is able to process
  - PCM / PPM format i.e. position count/frequency matrix (*.pat or *.pcm) - preferable
  - FASTA format (file extensions: .mfa, .fasta, .plain)
  - SMall BiSMark format (.xml)
  - IUPAC format (any other extension)
  Usage:
    sequence_logo [options] <motif file>...
      or
    ls pcm_folder/*.pcm | sequence_logo [options]
      or
    sequence_logo --sequence <sequence>...
      or
    sequence_logo --snp-sequence <sequence with SNP>...

  EOS

  argv = ARGV
  default_options = { x_unit: 30, y_unit: 60, scheme: 'nucl_simpa',
                      orientation: :direct, icd_mode: :discrete, threshold_lines: true,
                      logo_folder: '.', background_color: 'white' }
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

    parser.on('--snp-sequence', 'Specify sequences with SNP (like ATCTC[C/G]CCTAAT) instead of motif filenames') do
      options[:sequence_w_snp] = true
    end
    parser.on('--sequence', 'Specify sequence (like ATCTCGCCTAAT) instead of motif filenames') do
      options[:sequence] = true
    end
    parser.on('--bg-fill FILL', 'Background fill. Specify either `transparent` or `color` or `color,hatch_color`') do |v|
      if v.match(/^\w+,\w+$/)
        options[:background_fill] = Magick::HatchFill.new(*v.split(','))
      else
        options[:background_fill] = Magick::SolidFill.new(v)
      end
    end
  end
  options = cli.parse_options!(argv)

  logo_folder = options[:logo_folder]
  Dir.mkdir(logo_folder)  unless Dir.exist?(logo_folder)

  scheme_dir = File.join(SequenceLogo::AssetsPath, options[:scheme])
  letter_images = SequenceLogo::CanvasFactory.letter_images(scheme_dir)
  canvas_factory = SequenceLogo::CanvasFactory.new( letter_images, x_unit: options[:x_unit], y_unit: options[:y_unit],
                                                    background_fill: options[:background_fill] )

  raise "Specify either sequence or sequence with SNP or none of them, but not both"  if options[:sequence] && options[:sequence_w_snp]

  objects_to_render = []
  if options[:sequence]
    sequences = arglist_augmented_with_stdin(argv)
    raise ArgumentError, 'Specify at least one sequence'  if sequences.empty?

    sequences.each do |sequence|
      objects_to_render << {renderable: SequenceLogo::Sequence.new(sequence),
                            name: File.join(logo_folder, sequence)}
    end
  elsif options[:sequence_w_snp]
    sequences = arglist_augmented_with_stdin(argv)
    raise ArgumentError, 'Specify at least one sequence'  if sequences.empty?

    sequences.each do |sequence_w_snp|
      objects_to_render << {renderable: SequenceLogo::SequenceWithSNP.from_string(sequence_w_snp),
                            name: File.join(logo_folder, sequence_w_snp.gsub(/[\[\]\/]/, '_'))}
    end
  else
    filenames = arglist_augmented_with_stdin(argv)
    raise ArgumentError, 'Specify at least one motif file'  if filenames.empty?

    filenames.each do |filename|
      ppm = Bioinform::MotifModel::PCM.from_file(filename)

      logo = SequenceLogo::PPMLogo.new( ppm,
                                        icd_mode: options[:icd_mode],
                                        enable_threshold_lines: options[:threshold_lines])
      objects_to_render << {renderable: logo, name: File.basename_wo_extname(filename)}
    end
  end

  in_necessary_orientations(objects_to_render, options[:orientation], logo_folder).each do |infos|
    filename = File.join(logo_folder, infos[:filename])
    infos[:renderable].render(canvas_factory).write("PNG:#{filename}")
  end
rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end
