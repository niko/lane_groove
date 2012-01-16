require 'yaml'
require 'json'
require 'xmlsimple'
require 'sinatra/base'
require 'sinatra/respond_with'
require 'rack/contrib'

if Dir.glob(File.join(WORKING_DIR, '*.yaml')).empty?
  puts "No config file(s) found in #{WORKING_DIR}. Please put one or more YAML files in #{WORKING_DIR}."
  exit
end

class Hash
  def recursive_values
    inject([]){ |new_array, key_value|
      key, value = key_value
      value = value.recursive_values if value.is_a?(Hash)
      new_array << value
      new_array.flatten
    }
  end
  
  def remove_nil_values
    inject({}){ |new_hash, key_value|
      key, value = key_value
      value = value.remove_nil_values if value.is_a?(Hash)
      new_hash[key] = value unless value.nil?
      new_hash
    }
  end
  
  def to_xml(root=nil)
    XmlSimple.xml_out(self, 'RootName' => root, 'NoAttr' => true)
  end
end

class Rack::Static
  def initialize(app, options={})
    # don't default to 'index.html' as per https://github.com/lgierth/rack/blob/5ab871f2a86ca4f943a5b1d0a3d0f32a2f9f77ef/lib/rack/static.rb
    @app = app
    @urls = options[:urls]
    root = options[:root]
    @file_server = Rack::File.new(root)
  end
end

# inspired by https://github.com/crohr/rack-accept-header-updater/blob/master/lib/rack/accept_header_updater.rb
# turns file extensions into accept headers.
module Rack
  class AcceptHeaderUpdater
    def initialize(app)
      @app = app
    end
    
    def call(env)
      req = Rack::Request.new(env)
      if ext = (req.path_info.match('\.') && ".#{req.path_info.split('.').last}")
        if mime_type = Rack::Mime::MIME_TYPES[ext.downcase]
          env['HTTP_ACCEPT'] = [mime_type, env['HTTP_ACCEPT']].join(",")
          req.path_info.gsub!(/#{ext}$/, '')
        end
      end
      @app.call(env)
    end
  end
end

class LaneGroove < Sinatra::Base
  use Rack::CommonLogger
  use Rack::Access, '/' => %w{ 127.0.0.1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 }
  
  # We're using Rack::Static instead of Sinatra static so we can put it in the Middleware stack before AcceptHeaderUpdater
  if File.exists?(static_dir = File.join(WORKING_DIR, 'static'))
    puts "Serving static files from #{static_dir}: #{Dir.glob File.join(static_dir, '*')}"
    use Rack::Static, :urls => ['/static'], :root => WORKING_DIR
  end
  
  use Rack::AcceptHeaderUpdater
  register Sinatra::RespondWith
  
  disable :protection
  set :config, nil
  
  helpers do
    def config_files
      Dir.glob File.join(WORKING_DIR, '*.yaml')
    end
    
    def reload_yaml
      self.class.config = {}
      
      config_files.each do |file|
        puts "Loading #{file}"
        self.class.config[File.basename(file, '.yaml')] = YAML.load_file(file)
      end
    end
    
    def config(*path)
      reload_yaml if self.class.config.nil?
      cfg = self.class.config
      
      path.each do |node|
        break if (cfg = cfg[node]).nil?
      end
      
      return cfg
    end
    
    def parse_path(path)
      path.split('/').delete_if{|n| n.empty?}.compact.map{|n| n}
    end
    def extract_values(path)
      path.is_a?(Hash) ? path.recursive_values : path
    end
  end
  
  before do
    reload_yaml if params['reload']
  end
  
  get /^(.*)\.line$/ do |paths|
    content_type 'application/x-line; charset=utf-8'
    paths.split(',').map{ |path| extract_values config(*parse_path(path)) }.flatten.join(params['F'] || ' ')
  end
  
  get /^(.*)$/, :provides => [:json, :yaml, :xml] do |path|
    halt 404 unless (conf = config *parse_path(path))
    
    respond_to do |format|
      format.json { conf.to_json }
      format.yaml { conf.to_yaml }
      format.xml  { conf.remove_nil_values.to_xml }
    end
  end
  
end