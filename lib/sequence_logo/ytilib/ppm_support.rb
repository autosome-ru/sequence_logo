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
    if icd_mode == :weblogo
      get_logo_weblogo
    else
      get_logo_discrete
    end
  end


  def get_logo_weblogo
    rseq = []
    @matrix['A'].each_index { |i|
      rseq << 2 + ['A','C','G','T'].inject(0) { |sum, l|
        pn = @matrix[l][i]
        sum += (pn == 0) ? 0 : pn * Math.log(pn) / Math.log(2)
      }
    }
    
    mat = {'A'=>[], 'C'=>[], 'G'=>[], 'T'=>[]}
    @matrix['A'].each_index { |i|
      ['A','C','G','T'].each { |l|
        mat[l][i]= @matrix[l][i] * rseq[i] / 2 # so we can handle a '2 bit' scale here
      }
    }
    
    mat
  end

  def get_logo_discrete
    checkerr("words count is undefined") { !words_count }
    
    rseq = []
    @matrix['A'].each_index { |i|
      rseq << (icd4of4 == 0 ? 1.0 : ( (infocod(i) - icd4of4) / icd4of4 ).abs)
    }
    
    mat = {'A'=>[], 'C'=>[], 'G'=>[], 'T'=>[]}
    @matrix['A'].each_index { |i|
      ['A','C','G','T'].each { |l| 
        mat[l][i] = @matrix[l][i] * rseq[i]
      }
    }
    
    mat
  end
  
  def revcomp
    deep_dup.revcomp!
  end
end
