ElitDecoder.configuration do |config|
  # Set up RPC SERVER URL endpoint
  config.python_server_url = ENV['PYTHON_SERVER_URL']
  config.java_server_url = ENV['JAVA_SERVER_URL']
end
