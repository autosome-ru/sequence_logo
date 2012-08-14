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
end