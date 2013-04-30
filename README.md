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

SequenceLogo consists of two tools:

    sequence_logo [options] \<input files\>...

  *input_file* can be either in PCM format (file extension should be .pat or .pcm), or in FASTA format (file extensions: .mfa, .fasta, .plain), or in SMall BiSMark format (.xml), or in IUPAC format (any other extension). In future releases formats except PCM and PPM will be removed in preference of Unix-like modular style.

  Optional parameters:

    * --x-unit SIZE - width of a single letter
    * --y-unit SIZE - base height of a letter
    * --words-count WEIGHT - float number that represents alignment weight. If words count not defined - it'd be obtained from input if input file is a PCM. If input file is a PPM words_count can't be obtained. In such a case discrete logo can't be drawn, and weblogo will be drawn instead.
    * --icd-mode \<weblogo|discrete\> - information content mode
    * --orientation \<direct|revcomp|both\> - create logo for a direct, reverse-complement or both orientations of motif
    * --scheme FOLDER - name of folder containing nucleotide images
    * --threshold-lines - draw lines on specific levels

* Tool **glue_logos** generates a single image of aligned motifs.

    glue_logos <output file> <file with alignment infos>
      or
    \<alignment infos\> | glue_logos <output file>

  Input data comes either from file with alignments or from stdin. *glue_logos* is designated to work fine with macroape *align_motifs* tool and has input format the same as output format of *align_motifs* tool:
      pcm_file_1  shift_1  orientation_1
      pcm_file_2  shift_2  orientation_2
      pcm_file_3  shift_3  orientation_3

  So it's simple to run `align_motifs --pcm leader.pcm other_motifs_1.pcm other_motifs_2.pcm | glue_logos cluster.png`
  Don't forget to use PCM files instead of PWM files!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright (c) 2011-2012 Ivan Kulakovskiy(author), Ilya Vorontsov(refactoring and gemification)