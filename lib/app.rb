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
end

class ConfigApp < Sinatra::Base
  use Rack::CommonLogger
  use Rack::Access, '/' => %w{ 127.0.0.1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 }
  
  set :config, nil
  
  helpers do
    def config_files
      Dir.glob File.join(WORKING_DIR, '*.yaml')
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
  end
  
  get /^(.*)\.([\w\d]{2,4})$/ do |path, ext|
    reload_yaml if params['reload']
    
    ext = ext.to_sym
    path = path.split('/').delete_if{|n| n.empty?}.compact.map{|n| n.to_sym}
    
    case ext
      when :yaml then config(*path).to_yaml
      when :json then config(*path).to_json
      when :xml  then XmlSimple.xml_out(config(*path), 'RootName' => nil, 'NoAttr' => true)
      when :XML  then XmlSimple.xml_out(config(*path).upcase_keys, 'RootName' => nil, 'NoAttr' => true)
      when :rb   then config(*path).inspect
      else ; "unknown format #{ext}"
    end
  end
  
end