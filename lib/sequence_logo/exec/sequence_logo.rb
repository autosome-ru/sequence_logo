require_relative '../../sequence_logo'
require 'shellwords'

begin
  doc = <<-EOS
  sequence_logo is a tool for drawing motif logos. It is able to process PCM files either as a position matrix (*.pat or *.pcm), or in FASTA format (file extensions: .mfa, .fasta, .plain), or in SMall BiSMark format (.xml), or in IUPAC format (any other extension).
  Usage:
    sequence_logo [options] <pcm/ppm file>...
      or
    ls pcm_folder/*.pcm | sequence_logo [options]
  EOS

  argv = ARGV
  default_options = {x_unit: 30, y_unit: 60, words_count: nil, orientation: :both, logo_folder: '.', icd_mode: :discrete, threshold_lines: true, scheme: 'nucl_simpa'}
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
  end
  options = cli.parse_options!(argv)

  logo_folder = options[:logo_folder]
  Dir.mkdir(logo_folder)  unless Dir.exist?(logo_folder)

  filenames = argv
  filenames += $stdin.read.shellsplit  unless $stdin.tty?
  raise ArgumentError, 'Specify at least one motif file'  if filenames.empty?

  filenames.each do |filename|
    ppm = get_ppm_from_file(filename)
    checkerr("bad input file: #{filename}") { ppm == nil }

    filename_wo_ext = File.basename(filename, File.extname(filename))
    if [:direct, :both].include?(options[:orientation])
      direct_output = File.join(logo_folder, "#{filename_wo_ext}_direct.png")
      SequenceLogo.draw_logo(ppm, options).write(direct_output)
    end
    if [:revcomp, :both].include?(options[:orientation])
      revcomp_output = File.join(logo_folder, "#{filename_wo_ext}_revcomp.png")
      SequenceLogo.draw_logo(ppm.revcomp, options).write(revcomp_output)
    end
  end
rescue => err
  $stderr.puts "\n#{err}\n#{err.backtrace.first(5).join("\n")}\n\nUse --help option for help\n\n#{doc}"
end