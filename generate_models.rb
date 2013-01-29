require 'mysql2'
require 'active_support/all'
require 'erb'

class Property
  TYPES_MAP = {"varchar(255)" => "String", "datetime" => "DateTime", "int(11)" => "Integer", "bigint(20)" => "Serial"}
  attr_reader :name, :type
  def initialize(options)
    field_name = options[:name]
    @name = field_name_to_property field_name
    @type = convert_type(options[:type])
  end

  def to_s
    "#{@name}: #{@type}"
  end

  private
  def field_name_to_property(name)
    name.underscore
  end
  def convert_type(mysql_type)
    TYPES_MAP[mysql_type]
  end
end

class ModelClass
  attr_reader :name
  def initialize(name)
    @name = name
    @properties = []
  end

  def add_property(options) 
    @properties << Property.new(options)
  end

  def to_s
    "#{@name}: #{@properties}"
  end

  def generate_class
    template = File.read("model_class.erb")
    erb = ERB.new(template)
    erb.result(binding)
  end

end

DATABASE, USER = ARGV

if USER.nil?
  abort "usage: generate_models.rb <database> <user>"
end

client = Mysql2::Client.new(username: USER, database:DATABASE)

models = []

client.query("show tables").each do |row| 
  model_name = row["Tables_in_#{DATABASE}"]
  models << ModelClass.new(model_name)
end

models.each do |model|
  client.query("describe #{model.name}").each do |row| 
    field_name =  row["Field"]
    type =  row["Type"]
    model.add_property(name: field_name, type: type)
  end
end

models.each do |m|
  file_name = "generated/#{m.name.underscore}.rb"
  puts "generating #{m.name} class \n\tinto #{file_name}..."
  file = File.open(file_name, 'w')
  file.write(m.generate_class)
end
