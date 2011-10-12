module ActsAsAddress
  ADDRESS_SUFFIX = %w(null index region area town settl street house house_a flat)
  ADDRESS_SUFFIX_HASH = YAML::load(File.open( File.dirname(__FILE__)+"/kladr.yml").read)
  
  def self.included(base_class)
    base_class.extend(ClassMethods)
  end
  
  class Address 
      attr_reader :model
      attr_reader :field
      
      def initialize(model, field,suffixes = ADDRESS_SUFFIX)
        @model = model
        @field = field
        @address = []
        address_string = @model.send(field)
        @address = if address_string then
                        address_string.split_with_nils(",") 
                      else
                        new_string = ","*(suffixes.count-1)
                        @model.send("#{@field}=", new_string)
                        new_string.split_with_nils(",")
                      end
      end
      
      def to_s
        @address.join(",")
      end
      
      def write(index, param)
        @address ||= []
        @address[index] = param ? param.gsub(",",".") : ""
        @model.send("#{@field}=", self.to_s)
      end
      
      def read(index)
        @address[index]
      end
  end
  
  module ClassMethods
       
    def acts_as_address(*fields)
      suffixes = ADDRESS_SUFFIX
              fields_object_names = fields.map {|field| field.to_s+"_object"}
              
              fields_object_names.each_with_index {|field_object_name, index|
                self.class_eval {
                attr_accessor field_object_name

                suffixes.each_with_index { |suffix,i|
                        self.send :define_method, "#{fields[index]}_#{suffix}=" do |param|
                          if self.send(field_object_name) then
                          self.send(field_object_name).write(i,param)
                        else
                          self.send "#{field_object_name}=", Address.new(self, fields[index], suffixes)
                        end
                        end

                        self.send :define_method, "#{fields[index]}_#{suffix}" do

                          self.send(field_object_name).read(i)
                        end
                 }
              }
              
              
              
              self.send :define_method, :after_initialize do
                fields_object_names.each_with_index {|field_object_name, index|
                self.send "#{field_object_name}=", Address.new(self, fields[index], suffixes)
              }
              end
              
              }   
      end   
       
 end

  module StringMethods
    
      def split_with_nils(param)
        result = self.each(param).map { |m| m.delete(param)  }
        result += [""] if self.last == param
      end
 
  end
end