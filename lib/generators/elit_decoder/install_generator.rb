module ElitDecoder
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy ElitDecoder default files"
      source_root File.expand_path('../templates', __FILE__)

      def copy_config
        template "config/initializers/elit_decoder.rb"
      end
    end
  end
end
