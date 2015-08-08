require 'bioinform'
require 'fileutils'

##########
module Bioinform
  module MotifModel
    class DiPM # Doesn't work with alphabet

      def self.from_file(filename)
        parser = Bioinform::MatrixParser.new(fix_nucleotides_number: 16)
        infos = parser.parse(File.read(filename))
        name = infos[:name] || File.basename(filename, File.extname(filename))
        pcm = self.new(infos[:matrix]).named(name)
      end

      attr_reader :matrix
      def initialize(matrix)
        @matrix = matrix
        raise ValidationError.new('invalid matrix', validation_errors: validation_errors)  unless valid?
      end

      def validation_errors
        errors = []
        errors << "matrix should be an Array"  unless matrix.is_a? Array
        errors << "matrix shouldn't be empty"  unless matrix.size > 0
        errors << "each matrix position should be an Array"  unless matrix.all?{|pos| pos.is_a?(Array) }
        errors << "each matrix position should be of size compatible with alphabet (=#{16})"  unless matrix.all?{|pos| pos.size == 16 }
        errors << "each matrix element should be Numeric"  unless matrix.all?{|pos| pos.all?{|el| el.is_a?(Numeric) } }
        errors
      end
      private :validation_errors

      def valid?
       validation_errors.empty?
      rescue
        false
      end

      private :valid?

      def to_s
        MotifFormatter.new.format(self)
      end

      def named(name)
        NamedModel.new(self, name)
      end

      def length
        matrix.size + 1
      end

      def ==(other)
        self.class == other.class && matrix == other.matrix # alphabet should be considered (when alphabet implemented)
      end

      def each_position
        if block_given?
          matrix.each{|pos| yield pos}
        else
          self.to_enum(:each_position)
        end
      end

    end

    class DiPCM < DiPM

      def sum_dependent_on_first_letter(pos)
        mono_pos = Array.new(4, 0.0)
        pos.each.with_index{|count, diletter|
          first_letter = diletter / 4
          mono_pos[first_letter] += count
        }
        mono_pos
      end

      def sum_dependent_on_second_letter(pos)
        mono_pos = Array.new(4, 0.0)
        pos.each.with_index{|count, diletter|
          second_letter = diletter % 4
          mono_pos[second_letter] += count
        }
        mono_pos
      end

      def to_mono
        mono_matrix = each_position.map{|pos|
          sum_dependent_on_first_letter(pos)
        } + [ sum_dependent_on_second_letter(matrix.last) ]

        PCM.new(mono_matrix)
      end
    end

    class DiPWM < DiPM
    end
  end
end
