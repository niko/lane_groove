# encoding: utf-8

Gem::Specification.new do |s|
  s.name         = 'lane_groove'
  s.version      = '0.0.3'
  s.authors      = %w{Niko Dittmann}
  s.email        = 'mail@niko-dittmann.com'
  s.homepage     = 'http://github.com/niko/lane_groove'
  s.description  = 'A small HTTP configuration server. Eats YAML, returns JSON, XML, YAML and rb. Restricts requests to local subnet.'
  s.summary      = s.description # for now
  
  s.files        = Dir['lib/**/*.rb']
  
  s.test_files   = Dir['test/**/*_test.rb']
  
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.executables  = %w{lane_groove lane_groove_test}
  s.bindir       = 'bin'
  
  s.rubyforge_project = 'nowarning'
  
  s.add_dependency 'xml-simple'
  s.add_dependency 'sinatra'
  s.add_dependency 'rack-contrib'
  s.add_dependency 'foreverb'
  
  s.add_development_dependency 'rack-test'
end
