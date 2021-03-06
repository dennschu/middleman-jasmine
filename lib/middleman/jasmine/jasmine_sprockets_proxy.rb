require 'jasmine'

class JasmineSprocketsProxy
  class << self
    def jasmine_app
      @@jasmine_app
    end

    def sprockets_app
      @@sprockets_app
    end

    def configure(middleman_sprockets)
      Jasmine.load_configuration_from_yaml
      @@jasmine_app = Jasmine::Application.app(Jasmine.config)
      @@sprockets_app = 
        if defined?(::Sprockets::Environment)
          sprockets = ::Sprockets::Environment.new
          middleman_sprockets.paths.each do |path|
            sprockets.append_path(path)
          end
          sprockets.append_path(Jasmine.config.spec_dir)
          sprockets
        else
          @@jasmine_app
        end
    end
  end

  def initialize(path="", js_dir="")
    @path = path
    @app  = 
      if setup_for_spec_files?
        self.class.sprockets_app
      else
        self.class.jasmine_app
      end
  end

  def call(env)
    env["PATH_INFO"] = "/#{@path}#{env["PATH_INFO"]}" unless serving_spec_via_sprockets?
    @app.call(env)
  end

  private

  def setup_for_spec_files?
    @path == "__spec__"
  end

  def serving_spec_via_sprockets?
    setup_for_spec_files? && defined?(@@sprockets_app)
  end
end

# monkey patch Rack::Jasmine::Runner to allow for paths other than /
module Rack
  module Jasmine
    class Runner
      def call(env)
        @path = env["PATH_INFO"]
        [
          200,
          { 'Content-Type' => 'text/html'},
          [@page.render]
        ]
      end      
    end
  end
end