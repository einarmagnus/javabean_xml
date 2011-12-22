require "nokogiri"
require "builder"

# TODO : document

class JavabeanXml

  def self.default_transformations
    Hash.new { |hash, key|
      lambda { |value, properties|
        {
          :class => key,
          :value => value,
          :properties => properties
        }.delete_if { |k,v| v.nil? || v.respond_to?(:empty?) && v.empty? }
      }
    }
  end

  def self.from_xml xml, type_transformations = {}
    nodes = Nokogiri::XML(xml).xpath("/java/object")
    # clean out all empty text-nodes to simplify parsing
    nodes.xpath("//text()").each do |text_node|
      if text_node.content.strip.empty?
        text_node.remove
      end
    end
    JavabeanXml.new(default_transformations.merge(type_transformations)).parse(nodes)
  end

  def self.to_xml object, type_transformations = {}
    xml = Builder::XmlMarkup.new #:indent => 2
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml.java :version => "1.6.0_26", :class => "java.beans.XMLDecoder" do
      JavabeanXml.new(type_transformations).to_xml(object, xml)
    end
  end

  def initialize type_transformations
    @type_transformations = type_transformations
  end

  def parse node
    if node.is_a? Nokogiri::XML::NodeSet
      raise "structure error" if node.length != 1
      node = node.first
    end
    case node.name
    when "object"
      parse_object node
    else
      parse_value node
    end
  end

  def to_xml object, xml
    if object.is_a? Hash
      case object[:class]
      when Symbol
        to_value_xml object, xml
      else
        to_object_xml object, xml
      end
    else
      # puts "#{object.inspect} (#{object.class})"
      # puts " -- #{@type_transformations.keys.inspect}"
      transformation = @type_transformations[object.class]
      raise "No transformation registered for #{object.class}" unless transformation
      to_xml transformation[object], xml
    end
  end

  private
  def parse_object obj_node
    klass = obj_node["class"]
    value = []
    properties = {}
    obj_node.children.each do |prop|
      case prop.name
      when "void"
        properties[prop[:property].to_sym] = parse(prop.children)
      when "string", "int", "boolean", "long"
        value << parse_value(prop)
      else
        raise "Unsupported method: #{prop.inspect}"
      end
    end
    value = value.first if value.length == 1
    @type_transformations[klass][value, properties]
  end

  def parse_value val_node
    case val_node.name
    when "int", "long"
      value = val_node.text.to_i
    when "boolean"
      value = val_node.text.strip == "true"
    else
      value = val_node.text
    end
    klass = val_node.name.to_sym
    @type_transformations[klass][value, nil]
  end

  def to_value_xml object, xml
    xml.tag! object[:class] do
      xml.text! object[:value].to_s
    end
  end

  def to_object_xml object, xml
    xml.object :class => object[:class] do
      if value = object[:value]
        value = [value] unless value.is_a? Array
        value.each do |v|
          to_xml v, xml
        end
      end
      if object[:properties]
        object[:properties].each_pair do |p, val|
          xml.void :property => p do
            to_xml val, xml
          end
        end
      end
    end
  end

end
