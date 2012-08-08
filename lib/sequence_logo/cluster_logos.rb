$: << 'd:/iogen/macroape_and_fantom/macroape/'
require 'lib/pwm'

logo_dir = 'd:/iogen/macroape_and_fantom/clustering/logos/'
collection = YAML.load_file('d:/programming/macroape_tools/data_and_results/hocomoco_v9_ad_uniform.yaml')
logo_shift = 300

pvalue = 0.0005
          
Dir.glob('d:/iogen/macroape_and_fantom/clustering/results/*.out') do |filename|
  dirname = File.join('d:/iogen/macroape_and_fantom/clustering/results',File.basename(filename,'.out'))
  Dir.mkdir(dirname) unless Dir.exist? dirname
  
  File.open(filename){|f|f.readlines}.each do |str_cl|
    group = str_cl.split(' ')
    puts "#{group}"
    
    leader_name = group.shift
    pwm_leader = collection.pwms[leader_name].with_background([1,1,1,1]).discrete(collection.rough_discretization)
    pwm_leader_info = collection.infos[leader_name]
    logos = [  File.join(logo_dir,"#{leader_name}_direct.png")  ]
    names = [ leader_name ]
    left_size = right_size = 0
    shifts = [0]
    group.each do |pwm_second_name|
      puts "-- #{pwm_second_name}"
      pwm_second = collection.pwms[pwm_second_name].with_background([1,1,1,1]).discrete(collection.rough_discretization)
      pwm_second_info = collection.infos[pwm_second_name]
      cmp = PWMCompare::PWMCompare.new(pwm_leader, pwm_second)
      info = cmp.jaccard(pwm_leader_info[:rough][pvalue] * collection.rough_discretization,
                         pwm_second_info[:rough][pvalue] * collection.rough_discretization)
                         
      left_size = [ info[:text].split[0].each_char.take_while{|c|c=='.'}.length, left_size ].max
      right_size = [ info[:text].split[0].reverse.each_char.take_while{|c|c=='.'}.length, right_size ].max
      
      shifts << info[:shift]
      logos << File.join(logo_dir,"\"#{pwm_second_name}_#{info[:orientation]}.png\"")
      names << pwm_second_name
    end

    full_alignment_size = pwm_leader.length + left_size + right_size
    shifts = shifts.map{|s| s - shifts.min}
        
    joinl = "convert -size #{full_alignment_size*30+logo_shift}x#{(1+group.size)*60} -pointsize 24 xc:white "
    logos.each.with_index { |logo_name, i|
      joinl << "#{logo_name} -geometry +#{shifts[i]*30+logo_shift}+#{60*i} -composite "
    }
    names.each.with_index { |name, i|
      joinl << "-draw \"text #{10},#{60*i+30} '#{name}'\" "
    }
    joinl << '"' +File.join(dirname,"clust_about_group_#{leader_name}.png") + '"'
    system(joinl)
  end
end