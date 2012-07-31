# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sequence_logo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ilya Vorontsov"]
  gem.email         = ["prijutme4ty@gmail.com"]
  gem.description   = %q{SequenceLogo is a tool for drawing sequence logos of motifs. It gets Positional Count Matrices(PCMs) or IUPAC sequences as input and generates png-logos for a motif. Also one can create logo for reverse complement or even generate logos for a whole collection of motifs.
  Sequence logos are a graphical representation of an amino acid or nucleic acid multiple sequence alignment developed by Tom Schneider and Mike Stephens. Each logo consists of stacks of symbols, one stack for each position in the sequence. The overall height of the stack indicates the sequence conservation at that position, while the height of symbols within the stack indicates the relative frequency of each amino or nucleic acid at that position. In general, a sequence logo provides a richer and more precise description of, for example, a binding site, than would a consensus sequence (see http://weblogo.berkeley.edu/)
}
  gem.summary       = %q{Tool for drawing sequence logos of motifs}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sequence_logo"
  gem.require_paths = ["lib"]
  gem.version       = SequenceLogo::VERSION
  
  gem.add_dependency('rmagick', '~> 2.13.1')
end
