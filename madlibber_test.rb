require 'madlibber'
require 'yaml'

API_KEY = YAML.load(File.read("giantbomb.yaml"))['api_key']

puts API_KEY
