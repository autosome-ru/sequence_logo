require 'bioinform'

class Float
  def log_fact
    Math.lgamma(self + 1).first
  end
end

class Integer
  def log_fact
    self.to_f.log_fact
  end
end

def position_infocod(pos)
  words_count = pos.inject(0.0, &:+)
  ( pos.map(&:log_fact).inject(0.0, &:+) - words_count.log_fact ) / words_count
end

def icd4of4(words_count, floor: false)
  i4o4 = words_count / 4.0
  i4o4 = i4o4.floor  if floor
  position_infocod([i4o4, i4o4, i4o4, i4o4])
end

def icd2of4(words_count, floor: false)
  i2o4 = words_count / 2.0
  i2o4 = i2o4.floor if floor
  position_infocod([i2o4, i2o4, 0, 0]) # 0 is equal to words_count % 2, because 0! = 1!
end

def icd3of4(words_count, floor: false)
  i3o4 = words_count / 3.0
  i3o4 = i3o4.floor if floor
  addon = floor ? words_count % 3 : 0
  position_infocod([i3o4, i3o4, i3o4, addon])
end

def icdThc(words_count, floor: false)
  icd3of4(words_count, floor: floor)
end

def icdTlc(words_count, floor: false)
  io = words_count / 6.0
  io = io.floor  if floor
  position_infocod([2*io, 2*io, io, io])
end

def scale(value, relative_to:)
  ( (value - relative_to) / relative_to ).abs
end

class Bioinform::MotifModel::PCM
  def get_logo(icd_mode)
    case icd_mode.to_s
    when 'weblogo'
      get_logo_weblogo
    when 'discrete'
      get_logo_discrete
    end
  end

  def get_logo_weblogo
    each_position.map{|position|
      word_count = position.inject(0.0, &:+)
      inf_content = position.map{|el|
        (el == 0) ? 0 : (el / word_count) * Math.log2(el / word_count)
      }.inject(0.0, :+) + 2
      position.map{|el| (el / word_count) * inf_content / 2 }
    }
  end

  def get_logo_discrete
    each_position.map{|position|
      word_count = position.inject(0.0, &:+)
      icd4of4 = icd4of4(word_count)
      inf_content = (icd4of4 == 0) ? 1.0 : scale(position_infocod(position), relative_to: icd4of4)
      position.map{|el| (el / word_count) * inf_content }
    }
  end
end
