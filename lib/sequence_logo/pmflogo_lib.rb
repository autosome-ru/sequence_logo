require 'sequence_logo/ytilib'
require 'RMagick'

class PPM
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
end

def get_ppm_from_file(in_file_name, words_count)
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
  pm = pm.get_ppm
  pm.words_count = words_count  if words_count
  pm
end

def create_canvas(x_size, y_size, icd_mode, paper_mode, threshold_lines, pm)
  
  i_logo = Magick::ImageList.new
  if paper_mode
    i_logo.new_image(x_size, y_size)
  else
    if icd_mode == :discrete
      i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'white'))
      if threshold_lines
        dr = Magick::Draw.new
        dr.fill('transparent')
        
        dr.stroke_width(y_size / 200.0)
        dr.stroke_dasharray(7,7)
        
        line2of4 = y_size - pm.get_line(pm.icd2of4) * y_size
        lineThc = y_size - pm.get_line(pm.icdThc) * y_size
        lineTlc = y_size - pm.get_line(pm.icdTlc) * y_size
        
        dr.stroke('silver')
        dr.line(0, line2of4, x_size, line2of4)
        dr.line(0, lineThc, x_size, lineThc)
        dr.line(0, lineTlc, x_size, lineTlc)
        
        dr.draw(i_logo)
      end
    else
      i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'bisque'))
    end
  end
  i_logo
end

def letter_images(scheme_dir)
  if File.exist?(File.join(scheme_dir,'a.png'))
    lp = {'A' => File.join(scheme_dir,'a.png'), 'C' => File.join(scheme_dir,'c.png'), 'G' => File.join(scheme_dir,'g.png'), 'T' => File.join(scheme_dir,'t.png')}
  elsif File.exist?(File.join(scheme_dir,'a.gif'))
    lp = {'A' => File.join(scheme_dir,'a.gif'), 'C' => File.join(scheme_dir,'ñ.gif'), 'G' => File.join(scheme_dir,'g.gif'), 'T' => File.join(scheme_dir,'t.gif')}
  else
    raise "Scheme not exists in folder #{scheme_dir}"
  end
  i_letters = Magick::ImageList.new(lp['A'], lp['C'], lp['G'], lp['T'])
end

def draw_letters_on_canvas(i_logo, i_letters, matrix, y_size, x_unit)
  matrix['A'].each_index { |i|
    y_pos = 0
    sorted_letters = ['A', 'C', 'G', 'T'].collect { |letter| {:score => matrix[letter][i], :letter => letter} }.sort_by { |pair| pair[:score] }.collect { |pair| pair[:letter] }.reverse
    sorted_letters.each { |letter|
      next if y_size * matrix[letter][i] <= 1
      letter_index = {'A' => 0, 'C' => 1, 'G' => 2, 'T' => 3}[letter]
      y_block = (y_size * matrix[letter][i]).round
      i_logo << i_letters[letter_index].dup.resize(x_unit, y_block)
      y_pos += y_block
      i_logo.cur_image.page = Magick::Rectangle.new(0, 0, i * x_unit, y_size - y_pos )
    }
  }
end


def draw_logo(in_file_name, out_file_name, options = {})
  default_options = { words_count: nil,
                      x_unit: 100,
                      y_size: 200,
                      icd_mode: 'discrete',
                      revcomp: false,
                      scheme: 'nucl_simpa',
                      paper_mode: false,
                      threshold_lines: true }

  options = options.reject{|k,v| v == 'default' || v == :default}
  options = default_options.merge( options )

  x_unit = options[:x_unit].to_i
  y_size = options[:y_size].to_i
  icd_mode = options[:icd_mode].to_sym
  scheme = options[:scheme]
  
  words_count = options[:words_count]
  words_count = words_count.to_f  if words_count
  
  revcomp = options[:revcomp]
  revcomp = false  if revcomp == 'no' || revcomp == 'false' || revcomp == 'direct'
  
  paper_mode = options[:paper_mode]
  paper_mode = false  if paper_mode == 'no' || paper_mode == 'false'

  threshold_lines = options[:threshold_lines]
  threshold_lines = false  if threshold_lines == 'no' || threshold_lines == 'false'
  
  ########################
  
  pm = get_ppm_from_file(in_file_name, words_count)
  checkerr("bad input file") { pm == nil }
  
  x_size = x_unit * pm.length
  
  
  unless pm.words_count
    report "words count for PM is undefined, assuming weblogo mode"
    icd_mode = :weblogo
  end
  
  i_logo = create_canvas(x_size, y_size, icd_mode, paper_mode, threshold_lines, pm)
  
  pm.revcomp! if revcomp
  matrix = pm.get_logo(icd_mode)

  scheme_dir = File.join(SequenceLogo::AssetsPath, scheme)
  i_letters = letter_images(scheme_dir)
  draw_letters_on_canvas(i_logo, i_letters, matrix, y_size, x_unit)

  i_logo = i_logo.flatten_images
  i_logo.cur_image.border!(x_unit / 100 + 1, x_unit / 100 + 1, icd_mode == :discrete ? "green" : "red") if paper_mode

  i_logo.write(out_file_name)
end