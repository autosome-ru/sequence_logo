class Object
  def deep_dup
    Marshal.load(Marshal.dump(self))
  end
end

def get_ppm_from_file(in_file_name)
  case File.ext_wo_name(in_file_name)
  when 'pat', 'pcm'
    pm = PM.load(in_file_name)
    pm.fixwc  if pm.words_count
  when 'mfa', 'fasta', 'plain'
    pm = PM.new_pcm(Ytilib.read_seqs2array(in_file_name))
  when 'xml'
    pm = PM.from_bismark(Bismark.new(in_file_name).elements["//PPM"])
  when in_file_name
    pm = PPM.from_IUPAC(in_file_name.upcase)
  end
  pm.get_ppm
rescue
  nil
end

class PPM
  attr_accessor :name
  
  def get_ppm
    self
  end
  
  def get_line(v)
    ( (v - icd4of4) / icd4of4 ).abs
  end

  def get_logo(icd_mode)
    case icd_mode.to_s
    when 'weblogo'
      get_logo_weblogo
    when 'discrete'
      get_logo_discrete
    end
  end


  def get_logo_weblogo
    rseq = each_position_index.map do |i|
      2 + ['A','C','G','T'].map{|l| el = @matrix[l][i]; (el == 0) ? 0 : el * Math.log2(el) }.inject(0, :+)
    end
    
    mat = {'A'=>[], 'C'=>[], 'G'=>[], 'T'=>[]}
    each_position_index do |i|
      ['A','C','G','T'].each { |l|
        mat[l][i]= @matrix[l][i] * rseq[i] / 2 # so we can handle a '2 bit' scale here
      }
    end
    
    mat
  end

  def get_logo_discrete
    checkerr("words count is undefined") { !words_count }
    
    rseq = each_position_index.map do |i|
      (icd4of4 == 0) ? 1.0 : get_line(infocod(i))
    end
    
    mat = {'A'=>[], 'C'=>[], 'G'=>[], 'T'=>[]}
    each_position_index do |i|
      ['A','C','G','T'].each { |l| 
        mat[l][i] = @matrix[l][i] * rseq[i]
      }
    end
    
    mat
  end
  
  def revcomp
    deep_dup.revcomp!
  end
end
