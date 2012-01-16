WORKING_DIR = File.join(File.dirname(__FILE__), 'config_files')

require_relative '../lib/lane_groove.rb'
require 'test/unit'
require 'rack/test'
require 'fileutils'

class LaneGrooveTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    LaneGroove
  end
  
  def config
    {"test"=>{"db"=>{"host"=>"my-db-server", "user"=>"root", "pass"=>"none", "foo" => nil, "bar" => 1}, "redis"=>{"host"=>"my-redis-server"}}}
  end
  
  def config_all_xml
    <<-EOX
  <test>
    <db>
      <host>my-db-server</host>
      <user>root</user>
      <pass>none</pass>
      <bar>1</bar>
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
  <bar>1</bar>
    EOX
  end
  
  def test_all_yaml
    get '/.yaml'
    assert_equal 200, last_response.status
    assert_equal 'text/yaml;charset=utf-8', last_response.content_type
    assert_equal config.to_yaml, last_response.body
  end
  def test_db_yaml
    get '/test/db.yaml'
    assert_equal 200, last_response.status
    assert_equal 'text/yaml;charset=utf-8', last_response.content_type
    assert_equal config["test"]["db"].to_yaml, last_response.body
  end
  
  def test_all_json
    get '/.json'
    assert_equal 200, last_response.status
    assert_equal 'application/json;charset=utf-8', last_response.content_type
    assert_equal config.to_json, last_response.body
  end
  def test_db_json
    get '/test/db.json'
    assert_equal 200, last_response.status
    assert_equal 'application/json;charset=utf-8', last_response.content_type
    assert_equal config['test']["db"].to_json, last_response.body
  end
  
  def test_all_xml
    get '/.xml'
    assert_equal 200, last_response.status
    assert_equal 'application/xml;charset=utf-8', last_response.content_type
    assert_equal config_all_xml, last_response.body
  end
  def test_db_xml
    get '/test/db.xml'
    assert_equal 200, last_response.status
    assert_equal 'application/xml;charset=utf-8', last_response.content_type
    assert_equal config_db_xml, last_response.body
  end
  
  def test_line
    get '/test/db/host,/test/db/user.line'
    assert_equal 200, last_response.status
    assert_equal 'my-db-server root', last_response.body
  end
  def test_line_with_separator
    get '/test/db/host,/test/db/user.line?F=,'
    assert_equal 200, last_response.status
    assert_equal 'my-db-server,root', last_response.body
  end
  
  def reset_assets
    FileUtils.mv(File.join(WORKING_DIR, 'more_test.yaml'), File.join(WORKING_DIR, 'test.yaml')) if File.exists?(File.join(WORKING_DIR, 'more_test.yaml'))
    FileUtils.mv(File.join(WORKING_DIR, 'no_static'), File.join(WORKING_DIR, 'static')) if File.exists?(File.join(WORKING_DIR, 'no_static'))
  end
  
  def setup
    reset_assets
  end
  
  def teardown
    reset_assets
  end
  
  def test_reloading
    get '/test/db.json'
    assert_equal config["test"]["db"].to_json, last_response.body
    
    FileUtils.mv(File.join(WORKING_DIR, 'test.yaml'), File.join(WORKING_DIR, 'more_test.yaml'))
    
    get '/test/db.json'
    assert_equal config["test"]["db"].to_json, last_response.body
    
    get '/more_test/db.json?reload=true'
    assert_equal config["test"]["db"].to_json, last_response.body
  end
  
  def test_network_restrictions
    get '/.yaml', {}, {'REMOTE_ADDR' => '134.34.3.2'}
    assert_equal 403, last_response.status
    assert_equal '', last_response.body
  end
  
  def test_static_files
    get '/static/some.txt'
    assert_equal 'some text', last_response.body
  end
  def test_static_files_no_dir
    FileUtils.mv(File.join(WORKING_DIR, 'static'), File.join(WORKING_DIR, 'no_static'))
    get '/static/some.txt'
    assert_equal 404, last_response.status
  end
  
end