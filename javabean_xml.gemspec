# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'javabean_xml'
  s.version     = '0.1.2'
  s.date        = '2011-12-22'
  s.summary     = "Small library for interacting with java.beans.{Encoder,Decoder} "
  s.description = "Small library for encoding and decoding xml the way java.beans.{Encoder,Decoder} does it"
  s.authors     = ["Einar Magnús Boson"]
  s.email       = 'einar.boson@gmail.com'
  s.files       = Dir["lib/*.rb"]
  s.homepage    = 'http://github.com/einarmagnus/javabean_xml'
  s.license = 'MIT'
  s.test_files = Dir["test/test_*.rb"]
  s.required_ruby_version = '>= 1.8.7' # I don't know, it may work on older ones too

  s.add_runtime_dependency "nokogiri", "~> 1.5" # I don't know, it may work on older ones too
  s.add_runtime_dependency "builder", "~> 3.0" # I don't know, it may work on older ones too 

  # this is used for comparing xml output in the tests
  s.add_development_dependency "equivalent-xml", "~> 0.2" # I don't know, at least it worked with 0.2.8
  
end
