class TestUnitAdapter
  
  def self.command(ruby_interpreter, files)
    "#{ruby_interpreter} -Itest -e '%w(#{files}).each { |file| require(file) }'"
  end
  
  def self.file_pattern
    '**/**/*_test.rb'
  end
  
  def self.requester_port
    2231
  end
  
  def self.pluralized
    'tests'
  end
  
  def self.base_path
    type
  end
  
  def self.name
    'Test::Unit'
  end
  
  def self.type
    'test'
  end  
  
end
