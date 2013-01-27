require 'mysql2'
require 'active_support/all'
require 'erb'
require 'ostruct'

class Property
  TYPES_MAP = {"varchar(255)" => "String", "datetime" => "DateTime", "int(11)" => "Integer", "bigint(20)" => "Serial"}
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
    puts mysql_type.class
    puts mysql_type
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


puts "lala"

DATABASE = "metricminerdsl"

client = Mysql2::Client.new(username: "root", database:DATABASE)

models = []

client.query("show tables").each do |row| 
  models << ModelClass.new(row["Tables_in_#{DATABASE}"])
end

models.each do |model|
  client.query("describe #{model.name}").each do |row| 
    field_name =  row["Field"]
    type =  row["Type"]
    model.add_property(name: field_name, type: type)
  end
end

models.each do |m|
  puts m.generate_class
end
