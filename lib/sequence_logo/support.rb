class File
  def self.basename_wo_extname(filename)
    File.basename(filename, File.extname(filename))
  end
end
