require 'fileutils'
require 'optparse'
require_relative 'support'

module SequenceLogo
  class CLI
    attr_reader :options
    def initialize(options = {})
      @options = options.dup
    end
    def parse_options!(argv)
      parser.parse!(argv)
      options
    end
    def parser
      @parser ||= OptionParser.new do |opts|
        opts.version = ::SequenceLogo::VERSION
        opts.on('-x', '--x-unit X_UNIT', 'Single letter width') do |v|
          options[:x_unit] = v.to_i
        end
        opts.on('-y', '--y-unit Y_UNIT', 'Base letter height') do |v|
          options[:y_unit] = v.to_i
        end
        opts.on('--words-count WEIGHT', 'Define alignment weight') do |v|
          options[:words_count] = v.to_f
        end
        opts.on('--icd-mode MODE', 'Calculation mode: discrete or weblogo', 'Weblogo is assumed if word count not given') do |v|
          options[:icd_mode] = v.to_sym
          raise ArgumentError, 'icd-mode can be either discrete or weblogo'  unless [:discrete, :weblogo].include?(options[:icd_mode])
        end
        opts.on('--[no-]threshold-lines', 'Draw threshold lines') do |v|
          options[:threshold_lines] = v
        end
        opts.on('--scheme SCHEME', 'Specify folder with nucleotide images') do |v|
          options[:scheme] = v
        end
      end
    end
  end
end
