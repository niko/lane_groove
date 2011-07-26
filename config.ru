$LOAD_PATH << File.join( File.expand_path(File.dirname(__FILE__)), 'lib')

WORKING_DIR = Dir.getwd

require 'app'

run LaneGroove
