$LOAD_PATH << File.join( File.expand_path(File.dirname(__FILE__)), 'lib')

WORKING_DIR = Dir.getwd

require 'lane_groove'

run LaneGroove
