$: << File.dirname(File.dirname(File.absolute_path __FILE__))
$: << File.dirname(File.absolute_path __FILE__)
require 'macroape/lib/pwm'
require 'lib/fantom'
dirname = ARGV.shift
raise 'Dir not pointed or not exist' unless dirname and Dir.exist?(dirname)
sample_dir = File.join(dirname,'groups')
logo_dir = File.join(dirname,'logos')
glued_logos_dir = File.join(dirname,'glued_logos')
Dir.mkdir glued_logos_dir unless Dir.exist? glued_logos_dir

logo_shift = 300
Dir.glob(File.join(sample_dir,'*')) do |filename|
  sample=YAML.load_file(filename)
  puts sample[:name]
  sample[:leader].size.times do |group_index|
    indices = []
    sample[:motifs].size.times{|motif_index| indices << motif_index if sample[:motif_group][motif_index] == group_index }
    
    left_size = right_size = 0
    shifts = [0]
    logos = [  File.join(logo_dir,"#{motif_id(sample,indices[0])}_direct.png")  ]
    names = [ motif_id(sample,indices[0]) ]
    indices[1..-1].each do |motif_index|
      info = sample[:similarities_inner][motif_index]
      
      left_size = [ info[:text].split[0].each_char.take_while{|c|c=='.'}.length, left_size ].max
      right_size = [ info[:text].split[0].reverse.each_char.take_while{|c|c=='.'}.length, right_size ].max
      #left_size = [left_size, [-info[:shift], 0].max ].max
      #right_size = [right_size, info[:alignment_length] - [-info[:shift],0].max - sample[:motifs][sample[:leader][group_index]][:PWM][:A].length ].max
      shifts << info[:shift]
      logos << File.join(logo_dir,"#{motif_id(sample,motif_index)}_#{info[:orientation]}.png")
      names << motif_id(sample,motif_index)
    end
    
    # motif[:length] isn't real length so use motif[:PWM][:A].length
    full_alignment_size = sample[:motifs][ sample[:leader][group_index] ][:PWM][:A].length + left_size + right_size
    shifts = shifts.map{|s| s - shifts.min}
    
    joinl = "convert -size #{full_alignment_size*30+logo_shift}x#{indices.size*60} -pointsize 24 xc:white "
    logos.each.with_index { |logo_name, i|
      joinl << "\"#{logo_name}\" -geometry +#{shifts[i]*30+logo_shift}+#{60*i} -composite "
    }
    names.each.with_index { |name, i|
      joinl << "-draw \"text #{10},#{60*i+30} '#{name}'\" "
    }
    joinl << "\"#{File.join(glued_logos_dir,"#{sample_id(sample)}_g#{group_index}.png")}\""

    system(joinl)
  end
end