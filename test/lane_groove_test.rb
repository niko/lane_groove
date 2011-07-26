require '../lib/app.rb'
require 'test/unit'
require 'rack/test'
require 'fileutils'

WORKING_DIR = File.join(Dir.getwd, 'config_files')

class ConfigAppTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    ConfigApp
  end
  
  def config
    {:test=>{:db=>{:host=>"my-db-server", :user=>"root", :pass=>"none"}, :redis=>{:host=>"my-redis-server"}}}
  end
  
  def config_all_xml
    <<-EOX
  <test>
    <db>
      <host>my-db-server</host>
      <user>root</user>
      <pass>none</pass>
    </db>
    <redis>
      <host>my-redis-server</host>
    </redis>
  </test>
    EOX
  end
  
  def config_db_xml
    <<-EOX
  <host>my-db-server</host>
  <user>root</user>
  <pass>none</pass>
    EOX
  end
  
  def config_all_XML
    <<-EOX
  <TEST>
    <DB>
      <HOST>my-db-server</HOST>
      <USER>root</USER>
      <PASS>none</PASS>
    </DB>
    <REDIS>
      <HOST>my-redis-server</HOST>
    </REDIS>
  </TEST>
    EOX
  end
  
  def config_db_XML
    <<-EOX
  <HOST>my-db-server</HOST>
  <USER>root</USER>
  <PASS>none</PASS>
    EOX
  end
  
  def test_all_rb
    get '/.rb'
    assert_equal config.inspect, last_response.body
  end
  def test_db_rb
    get '/test/db.rb'
    assert_equal config[:test][:db].inspect, last_response.body
  end
  
  def test_all_yaml
    get '/.yaml'
    assert_equal config.to_yaml, last_response.body
  end
  def test_db_yaml
    get '/test/db.yaml'
    assert_equal config[:test][:db].to_yaml, last_response.body
  end
  
  def test_all_json
    get '/.json'
    assert_equal config.to_json, last_response.body
  end
  def test_db_json
    get '/test/db.json'
    assert_equal config[:test][:db].to_json, last_response.body
  end
  
  def test_all_xml
    get '/.xml'
    assert_equal config_all_xml, last_response.body
  end
  def test_db_xml
    get '/test/db.xml'
    assert_equal config_db_xml, last_response.body
  end
  
  def test_all_XML
    get '/.XML'
    assert_equal config_all_XML, last_response.body
  end
  def test_db_XML
    get '/test/db.XML'
    assert_equal config_db_XML, last_response.body
  end
  
  def reset_assets
    FileUtils.mv('config_files/more_test.yaml', 'config_files/test.yaml') if File.exists?('config_files/more_test.yaml')
  end
  
  def setup
    reset_assets
  end
  
  def teardown
    reset_assets
  end
  
  def test_reloading
    get '/test/db.rb'
    assert_equal config[:test][:db].inspect, last_response.body
    
    FileUtils.mv('config_files/test.yaml', 'config_files/more_test.yaml')
    
    get '/test/db.rb'
    assert_equal config[:test][:db].inspect, last_response.body
    
    get '/more_test/db.rb?reload=true'
    assert_equal config[:test][:db].inspect, last_response.body
  end
  
  def test_network_restrictions
    get '/.yaml', {}, {'REMOTE_ADDR' => '134.34.3.2'}
    assert_equal 403, last_response.status
    assert_equal '', last_response.body
  end
  
end