require 'yaml'
require 'json'
require 'xmlsimple'
require 'sinatra/base'
require 'rack/contrib'

class Hash
  def upcase_keys
    self.inject({}){ |new_hash, key_value|
      key, value = key_value
      value = value.upcase_keys if value.is_a?(Hash)
      new_hash[key.upcase] = value
      new_hash
    }
  end
  
  def recursive_values
    self.inject([]){ |new_array, key_value|
      key, value = key_value
      value = value.recursive_values if value.is_a?(Hash)
      new_array << value
      new_array.flatten
    }
  end
end

class LaneGroove < Sinatra::Base
  use Rack::CommonLogger
  use Rack::Access, '/' => %w{ 127.0.0.1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 }
  
  set :config, nil
  
  static_dir = File.join(WORKING_DIR, 'static')
  
  if File.exists? static_dir
    puts "Serving static files from #{static_dir}"
    set :static, true
    set :public, static_dir
  end
  
  helpers do
    def config_files
      Dir.glob File.join(WORKING_DIR, '*.yaml')
    end
    
    def content_type_for(format)
      {
        :json => {'Content-Type' => 'application/json; charset=utf-8'},
        :xml  => {'Content-Type' => 'application/xml; charset=utf-8'},
        :yaml => {'Content-Type' => 'application/x-yaml; charset=utf-8'},
        :rb   => {'Content-Type' => 'application/x-ruby; charset=utf-8'},
        :line => {'Content-Type' => 'application/x-line; charset=utf-8'}
      }[format]
    end
    
    def reload_yaml
      self.class.config = {}
      
      config_files.each do |file|
        puts "Loading #{file}"
        self.class.config[File.basename(file, '.yaml').to_sym] = YAML.load_file(file)
      end
      
      config.to_yaml
    end
    
    def config(*path)
      reload_yaml if self.class.config.nil?
      cfg = self.class.config
      
      path.each do |node|
        cfg = cfg[node]
        break if cfg.nil?
      end
      
      return cfg
    end
    
    def parse_path(path)
      path.split('/').delete_if{|n| n.empty?}.compact.map{|n| n.to_sym}
    end
    def extract_values(path)
      path.is_a?(Hash) ? path.recursive_values : path
    end
  end
  
  before do
    reload_yaml if params['reload']
  end
  
  get /^(.*)\.line$/ do |paths|
    [200, content_type_for(:line), paths.split(',').map{ |path| extract_values config(*parse_path(path)) }.flatten.join(params['F'] || ' ')]
  end
  
  get /^(.*)\.([\w\d]{2,4})$/ do |path, ext|
    ext = ext.to_sym
    path = parse_path(path)
    
    case ext
      when :yaml then [200, content_type_for(:yaml), config(*path).to_yaml]
      when :json then [200, content_type_for(:json), config(*path).to_json]
      when :xml  then [200, content_type_for(:xml), XmlSimple.xml_out(config(*path), 'RootName' => nil, 'NoAttr' => true)]
      when :XML  then [200, content_type_for(:xml), XmlSimple.xml_out(config(*path).upcase_keys, 'RootName' => nil, 'NoAttr' => true)]
      when :rb   then [200, content_type_for(:rb), config(*path).inspect]
      else ; [404, {}, "unknown format #{ext}"]
    end
  end
  
end