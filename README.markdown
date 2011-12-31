# Description

I wrote this to handle xml serialisation and deserialisation for my project [truby_license] []
It does not handle everything a java.beans.Encoder can spit out, but it handles what is needed by Truby License.
I think it is mainly method calls that isn't implemented, but it should be fairly easy to add should anyone need it.

# Use

Consider this xml document:

    xml_document = <<-XML_END
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

We can parse it like this:

    JavabeanXml.from_xml xml_document
    #  => {
    #       :class => "java.SomeClass",
    #       :properties => {
    #         :myString => {
    #           :class => :string,
    #           :value => "string1"
    #         },
    #         :myObject => {
    #           :class => "java.NestedObject",
    #           :value => {
    #             :class => :string,
    #             :value => "Initialization string"
    #           }
    #         },
    #         :myDate => {
    #           :class => "java.util.Date",
    #           :value => {
    #             :class => :long,
    #             :value => 1314102227000
    #           }
    #         }
    #       }
    #     }

Notice that every object becomes a hash with the properties `:class` and `:value` and/or `:properties`.
The `:class` property is the name of the class as a `String`, or as a `Symbol` if it is a simple type with a primitive value. The properties is a hash with all the object's properties.
This will then need to be further interpreted and `from_xml` accepts as the last parameter a hash with object transformations. If an object's `:class` property matches a key in the transformations hash, that transformation will called with the object's value and properties as arguments. This will be done recursively from the leaves to the root and allows you to transform e.g. the java date to a ruby date with ease:

    some_class = JavabeanXml.from_xml xml_document,
                                      :long => lambda { |val, prop| val },
                                      "java.util.Date" => lambda { |val, prop|
                                                                    # time is in milliseconds
                                                                    Time.at(val / 1000)
                                                                  }
    #  => {
    #       :class => "java.SomeClass",
    #       :properties => {
    #         :myString => {
    #           :class => :string,
    #           :value => "string1"
    #         },
    #         :myObject => {
    #           :class => "java.NestedObject",
    #           :value => {
    #             :class => :string,
    #             :value => "Initialization string"
    #           }
    #         },
    #         :myDate => #<Time: Thu Mar 29 13:23:20 +0100 43612 >
    #       }
    #     }

See the tests for more examples.

Serialisation works very similarly but backwards. During serialization the hash keys are ruby classes:

    result = JavabeanXml.to_xml(
              some_class,
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
    # => <?xml version="1.0" encoding="UTF-8"?>
    #    <java version="1.6.0_26" class="java.beans.XMLDecoder">
    #      <object class="java.SomeClass">
    #        <void property="myString">
    #          <string>string1</string>
    #        </void>
    #        <void property="myObject">
    #          <object class="java.NestedObject">
    #            <string>Initialization string</string>
    #          </object>
    #        </void>
    #        <void property="myDate">
    #          <object class="java.util.Date">
    #            <long>1314102227000</long>
    #          </object>
    #        </void>
    #      </object>
    #    </java>

Again, have a look at the tests for more examples.


  [truby_license]: https://github.com/einarmagnus/truby_license

# License

## MIT

    Copyright (C) 2011 Einar Magnús Boson

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
