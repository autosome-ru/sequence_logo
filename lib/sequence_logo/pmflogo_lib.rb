require 'sequence_logo/ytilib'
require 'RMagick'

class Object
  def deep_dup
    Marshal.load(Marshal.dump(self))
  end
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

def create_canvas(ppm, options)
  x_size = options[:x_unit] * ppm.length
  y_size = options[:y_unit]
  
  i_logo = Magick::ImageList.new
  if options[:paper_mode]
    i_logo.new_image(x_size, y_size)
  else
    if options[:icd_mode] == :discrete
      i_logo.new_image(x_size, y_size, Magick::HatchFill.new('white', 'white'))
      if options[:threshold_lines]
        dr = Magick::Draw.new
        dr.fill('transparent')
        
        dr.stroke_width(y_size / 200.0)
        dr.stroke_dasharray(7,7)
        
        line2of4 = y_size - ppm.get_line(ppm.icd2of4) * y_size
        lineThc = y_size - ppm.get_line(ppm.icdThc) * y_size
        lineTlc = y_size - ppm.get_line(ppm.icdTlc) * y_size
        
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
    lp = {'A' => File.join(scheme_dir,'a.gif'), 'C' => File.join(scheme_dir,'c.gif'), 'G' => File.join(scheme_dir,'g.gif'), 'T' => File.join(scheme_dir,'t.gif')}
  else
    raise "Scheme not exists in folder #{scheme_dir}"
  end
  Magick::ImageList.new(lp['A'], lp['C'], lp['G'], lp['T'])
end

def draw_letters_on_canvas(i_logo, i_letters, ppm, options)
  y_unit = options[:y_unit]
  x_unit = options[:x_unit]
  matrix = ppm.get_logo(options[:icd_mode])
  matrix['A'].each_index { |i|
    y_pos = 0
    sorted_letters = ['A', 'C', 'G', 'T'].collect { |letter| {:score => matrix[letter][i], :letter => letter} }.sort_by { |pair| pair[:score] }.collect { |pair| pair[:letter] }.reverse
    sorted_letters.each { |letter|
      next if y_unit * matrix[letter][i] <= 1
      letter_index = {'A' => 0, 'C' => 1, 'G' => 2, 'T' => 3}[letter]
      y_block = (y_unit * matrix[letter][i]).round
      i_logo << i_letters[letter_index].dup.resize(x_unit, y_block)
      y_pos += y_block
      i_logo.cur_image.page = Magick::Rectangle.new(0, 0, i * x_unit, y_unit - y_pos )
    }
  }
end

def process_options_hash_for_logo(options = {})
  default_options = { words_count: nil,
                      x_unit: 100,
                      y_unit: 200,
                      icd_mode: 'discrete',
                      revcomp: false,
                      scheme: 'nucl_simpa',
                      paper_mode: false,
                      threshold_lines: true }
  
  options = options.reject{|k,v| v == 'default' || v == :default}
  options = default_options.merge( options )
  options[:x_unit] = options[:x_unit].to_i
  options[:y_unit] = options[:y_unit].to_i
  options[:icd_mode] = options[:icd_mode].to_sym
  options[:words_count] = options[:words_count].to_f  if options[:words_count]
  options[:revcomp] = false  if options[:revcomp] == 'no' || options[:revcomp] == 'false' || options[:revcomp] == 'direct'
  options[:paper_mode] = false  if options[:paper_mode] == 'no' || options[:paper_mode] == 'false'
  options[:threshold_lines] = false  if options[:threshold_lines] == 'no' || options[:threshold_lines] == 'false'
  
  options
end

def draw_logo(ppm, options = {})
  options = process_options_hash_for_logo(options)
  
  ppm.words_count = options[:words_count]  if options[:words_count]
  
  unless ppm.words_count
    report "words count for PPM is undefined, assuming weblogo mode"
    options[:icd_mode] = :weblogo
  end
  
  i_logo = create_canvas(ppm, options)
  
  ppm = ppm.deep_dup.revcomp! if options[:revcomp]

  scheme_dir = File.join(SequenceLogo::AssetsPath, options[:scheme])
  draw_letters_on_canvas(i_logo, letter_images(scheme_dir), ppm, options)

  i_logo = i_logo.flatten_images
  
  if options[:paper_mode]
    border_thickness = options[:x_unit] / 100 + 1
    border_color = (options[:icd_mode] == :discrete) ? 'green' : 'red'
    i_logo.cur_image.border!(border_thickness, border_thickness, border_color)
  end
  
  i_logo
end

# logos = { filename => {shift: ..., length: ..., name: ...} }
def glue_files(logos, output_file, logo_shift = 300, x_unit = 30, y_unit = 60)
  leftmost_shift = logos.map{|file,infos| infos[:shift] }.min
  logos.each{|file, infos| infos[:shift] -= leftmost_shift}
  full_alignment_size = logos.map{|file,infos| infos[:length] + infos[:shift] }.max
  
  x_size = logo_shift + full_alignment_size * x_unit
  y_size = logos.size * y_unit
  command_string = "convert -size #{ x_size }x#{ y_size } -pointsize 24 xc:white "
  logos.each_with_index do |(logo_filename,infos), idx|
    logo_x_start = logo_shift + infos[:shift] * x_unit
    logo_y_start = y_unit * idx
    command_string << "\"#{ logo_filename }\" -geometry +#{ logo_x_start }+#{ logo_y_start } -composite "
  end
  
  command_draw_names = ""
  logos.each_with_index do |(logo_filename,infos), idx|
    text_x_start = 10
    text_y_start = y_unit * (idx + 0.5)
    command_draw_names << "-draw \"text #{ text_x_start },#{ text_y_start } '#{infos[:name]}'\" "
  end
  
  system(command_string + command_draw_names + "\"#{output_file}\"")
end

# ppms {ppm => shift}
def glue_ppms(ppms, output_file, logo_shift = 300, x_unit = 30, y_unit = 60)
  logos = {}
  ppms.each do |ppm, motif_shift|
    name = "#{name}_tmp.png"
    draw_logo(ppm, x_unit: x_unit, y_unit: y_unit, revcomp: 'direct').write(name)
    logos[name] = {length: ppm.length, name: ppm.name, shift: motif_shift}
  end
  glue_files(logos, output_file, logo_shift, x_unit, y_unit)
end