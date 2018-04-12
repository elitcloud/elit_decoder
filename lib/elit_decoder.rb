require 'json'
require 'elit_decoder/version'
require 'helpers/configuration'

module ElitDecoder
  # Your code goes here...
  extend Configuration
  autoload :Decoder, 'elit_decoder/decoder'

  ROOT_DIR = File.expand_path('../../', __FILE__)
  RESOURCE_DIR = File.join(ROOT_DIR, '/res')
  SCHEMA = File.join(RESOURCE_DIR , 'schema.json')

  attr_accessor :python_server_url, :java_server_url, :schema

  define_setting :python_server_url, 'http://localhost:5000/'
  define_setting :java_server_url, 'http://localhost:4991/'
  define_setting :schema, JSON.parse(File.read(SCHEMA))

end
