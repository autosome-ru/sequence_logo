# SequenceLogo

SequenceLogo is a tool for drawing sequence logos of motifs. It gets Positional Count Matrices(PCMs) at input and generates png-logos for motif. Also one can create logo for reverse complement or even generate logos for a whole collection of motifs.
Sequence logos are a graphical representation of an amino acid or nucleic acid multiple sequence alignment developed by Tom Schneider and Mike Stephens. Each logo consists of stacks of symbols, one stack for each position in the sequence. The overall height of the stack indicates the sequence conservation at that position, while the height of symbols within the stack indicates the relative frequency of each amino or nucleic acid at that position. In general, a sequence logo provides a richer and more precise description of, for example, a binding site, than would a consensus sequence (see http://weblogo.berkeley.edu/)
 

## Installation

Add this line to your application's Gemfile:

    gem 'sequence_logo'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequence_logo

## Usage

SequenceLogo consists of three tools:
* The most flexible tool **pmflogo** generates single logo for a single motif. It has quite complicated usage format:
  
  `pmflogo <input_file> <output_logo_filename> [words_count] [x_unit=100] [y_size=200] [icd_mode=discrete|weblogo] [revcomp=no|yes] [scheme=nucl_simpa] [paper_mode=no|yes] [threshold_lines=yes|no]`
  
  Any optional argument can be set as 'default' e.g.
  
  `pmflogo motif.pcm logo.png default 30 60 default yes`
  
  skipped parameters are also substituted as default (in example above icd_mode is default, and also scheme, paper_mode and threshold_lines)


  Required arguments:
    * input_file can be either in PCM format (file extension should be .pat or .pcm), or in FASTA format (file extensions: .mfa, .fasta, .plain), or in SMall BiSMark format (.xml), or in IUPAC format (any other extension).
    * output_logo_filename is output logo file with format .png (extension should be included into name) which will be generated
  Optional parameters:
    * words_count [=default] is a float number that represents alignment weight. If words_count is set to 'default' - it'd be obtained from input (if it's PCM or IUPAC). In some cases (when PPM is used) words_count can't be obtained. In such a case discrete logo can't be drawn, and weblogo will be drawn instead.
    * x_unit - width of a single letter
    * y_size - full height of an image
    * icd_mode - information content mode
    * revcomp - create logo for a direct or reverse-complement orientation
    * scheme - nucleotide images folder name (by default only one scheme is used)
    * paper_mode - if paper_mode is true then threshold lines won't be drawn but a border is drawn instead
    * threshold_lines - lines on levels: icd2of4, icdThc(=icd3of4), icdTlc, - relative to icd4of4
  
* Tool **generate_logo** generates two logos - direct and reverse-complement with some reasonable defaults for a single motif and puts a logo in a logo_folder
  
  `generate_logo <motif_filename> [logo_folder = directory of input motif file]`

* Tool **create_all_logos** generates two logos - direct and reverse-complement with some reasonable defaults for each motif in a folder and puts all logos in a logo_folder
  `create_all_logos <motifs_folder> <logo_folder>`
 
 
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright (c) 2011-2012 Ivan Kulakovskiy(author), Ilya Vorontsov(refactoring and gemification)