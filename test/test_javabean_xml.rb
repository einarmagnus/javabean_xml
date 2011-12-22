require "rubygems"
require "test/unit"
require "equivalent-xml"
require File.expand_path("../../lib/javabean_xml.rb", __FILE__)
class JavabeanXmlTest < Test::Unit::TestCase
  @@test_xml_1 = <<-XML_END.split(/\n/).map{|l|l.gsub(/^(  ){3}/, "")}.join("\n")
      <?xml version="1.0" encoding="UTF-8"?>
      <java version="1.6.0_26" class="java.beans.XMLDecoder">
        <object class="java.SomeClass">
          <void property="myString">
            <string>string1</string>
          </void>
          <void property="myObject">
            <object class="java.NestedObject">
              <string>Initialization string</string>
            </object>
          </void>
          <void property="myDate">
            <object class="java.util.Date">
              <long>1314102227000</long>
            </object>
          </void>
        </object>
      </java>
    XML_END
  @@test_object_1_a = {
    :class => "java.SomeClass",
    :properties => {
      :myString => {
        :class => :string,
        :value => "string1"
      },
      :myObject => {
        :class => "java.NestedObject",
        :value => {
          :class => :string,
          :value => "Initialization string"
        }
      },
      :myDate => {
        :class => "java.util.Date",
        :value => {
          :class => :long,
          :value => 1314102227000
        }
      }
    }
  }
  @@test_object_1_b = {
    :class => "java.SomeClass",
    :properties => {
      :myString => {
        :class => :string,
        :value => "string1"
      },
      :myObject => {
        :class => "java.NestedObject",
        :value => {
          :class => :string,
          :value => "Initialization string"
        }
      },
      :myDate => Time.at(1314102227)
    }
  }

  @@test_xml_2 = <<-XML_END.split(/\n/).map{|l|l.gsub(/^(  ){3}/, "")}.join("\n")
      <?xml version="1.0" encoding="UTF-8"?>
      <java version="1.6.0_26" class="java.beans.XMLDecoder">
        <object class="java.SomeClass">
          <void property="myString">
            <string>string1</string>
          </void>
          <void property="myRectangle">
            <object class="java.awt.Rectangle">
              <int>0</int>
              <int>2</int>
              <int>200</int>
              <int>300</int>
            </object>
          </void>
          <void property="myDate">
            <object class="java.util.Date">
              <long>1314102227000</long>
            </object>
          </void>
        </object>
      </java>
    XML_END

  @@test_object_2_a = {
    :class => "java.SomeClass",
    :properties => {
      :myString => {
        :class => :string,
        :value => "string1"
      },
      :myRectangle => {
        :class => "java.awt.Rectangle",
        :value => [
          {
            :class => :int,
            :value => 0
          },
          {
            :class => :int,
            :value => 2
          },
          {
            :class => :int,
            :value => 200
          },
          {
            :class => :int,
            :value => 300
          },
        ]
      },
      :myDate => {
        :class => "java.util.Date",
        :value => {
          :class => :long,
          :value => 1314102227000
        }
      }
    }
  }

  Rect = Struct.new :values
  MyClass = Struct.new :myString, :myRectangle, :myDate

  @@test_object_2_b = \
        MyClass.new(
          "string1",
          Rect.new([0,2,200,300]),
          Time.at(1314102227)
        )

  def test_deserialization_simple
    assert_equal(
      @@test_object_1_a,
      JavabeanXml.from_xml(@@test_xml_1),
      "Should parse simple object"
    )
  end


  def test_deserialization_multiple_initialization_values
    assert_equal(
      @@test_object_2_a,
      JavabeanXml.from_xml(@@test_xml_2),
      "Should handle several initialization parameters"
    )
  end

  def test_deserialization_custom_object_types_simple
    assert_equal(
      @@test_object_1_b,
      JavabeanXml.from_xml(
        @@test_xml_1,
        :long => lambda { |value, properties|
          value.to_i
        },
        "java.util.Date" => lambda { |value, properties|
          Time.at(value/1000)
        }
      ),
      "Should parse object and transform them"
    )
  end

  def test_deserialization_custom_object_types_complex
    assert_equal(
      @@test_object_2_b,
      JavabeanXml.from_xml(
        @@test_xml_2,
        :long => lambda { |value, properties|
          value.to_i
        },
        "java.util.Date" => lambda { |value, properties|
          Time.at(value/1000)
        },
        :int => lambda { |value, properties|
          value.to_i
        },
        :string => lambda { |value, properties|
          value
        },
        "java.awt.Rectangle" => lambda { |value, properties|
          Rect.new value
        },
        "java.SomeClass" => lambda { |value, properties|
          c = MyClass.new
          properties.each_pair do |k, v|
            c.send :"#{k}=", v
          end
          c
        }
      ),
      "Should parse object and transform them"
    )
  end

  def test_serialization_simple
    assert(
      EquivalentXml.equivalent?(
        @@test_xml_1,
        JavabeanXml.to_xml(@@test_object_1_a),
        :element_order => (RUBY_VERSION =~ /^1.9/),
        :normalize_whitespace => true
      ),
      "Should serialize simple object"
    )
  end

  def test_serialization_simple_with_transformation
    result = JavabeanXml.to_xml(
          @@test_object_1_b,
          Time => lambda { |value|
            {
              :class => "java.util.Date",
              :value => {
                :class => :long,
                :value => value.to_i * 1000
              }
            }
          }
        )
    unless EquivalentXml.equivalent?(
          @@test_xml_1,
          result,
          :element_order => (RUBY_VERSION =~ /^1.9/),
          :normalize_whitespace => true
        )
    then
      puts "Expected:"
      puts @@test_xml_2
      puts
      puts "Was:"
      puts result
      fail "Should serialize object and transform types"
    end
  end

  def test_serialization_complex_with_transformation
    result = JavabeanXml.to_xml(
          @@test_object_2_b,
          Rect => lambda { |value|
            {
              :class => "java.awt.Rectangle",
              :value => value.values.map {|v|
                {
                  :class => :int,
                  :value => v
                }
              }
            }
          },
          String => lambda { |value|
            { :class => :string, :value => value }
          },
          Time => lambda { |value|
            {
              :class => "java.util.Date",
              :value => {
                :class => :long,
                :value => value.to_i * 1000
              }
            }
          },
          MyClass => lambda { |value|
            {
              :class => "java.SomeClass",
              :properties => value.each_pair.inject({}){|h, (k, v)| h[k] = v; h}
            }
          }
        )
    unless EquivalentXml.equivalent?(
                                @@test_xml_2,
                                result,
                                :element_order => (RUBY_VERSION =~ /^1.9/),
                                :normalize_whitespace => true
                             )
    then
      puts "Expected:"
      puts @@test_xml_2
      puts
      puts "Was:"
      puts result
      fail "Should serialize object and transform types"
    end
  end

end
