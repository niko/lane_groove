# encoding: utf-8

Gem::Specification.new do |s|
  s.name         = 'lane_groove'
  s.version      = '0.0.1'
  s.authors      = ['Niko Dittmann']
  s.email        = 'mail@niko-dittmann.com'
  s.homepage     = 'http://github.com/niko/lane_groove'
  s.description  = 'A small HTTP configuration server. Supports JSON, XML, YAML and rb. Restricts requests to local subnet.'
  s.summary      = s.description # for now
  
  s.files        = Dir['lib/**/*.rb']
  
  # s.test_files   = Dir['spec/**/*_spec.rb']
  
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.executables  = ['lane_groove']
  s.bindir       = 'bin'
  
  s.rubyforge_project = 'nowarning'
  
  s.add_dependency 'xml-simple'
  s.add_dependency 'sinatra'
  s.add_dependency 'rack-contrib'
  
  # s.add_development_dependency 'qed'
end