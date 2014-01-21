require "bundler/setup"
Bundler.require

module SchemaDoc
  class Config
    def self.schema_url
      ENV["SCHEMA_URL"] || raise("missing=SCHEMA_URL")
    end

    def self.root
      @root ||= File.expand_path("../", __FILE__)
    end
  end

  class Web < Sinatra::Base
    @@json ||= Excon.get(Config.schema_url,
      expects: 200,
      headers: {
        "Accept" => "application/vnd.heroku+json; version=3"
      }
    ).body
    @@schema = Committee::Schema.new(@@json)

    configure do
      set :views, Config.root + "/views"
    end

    before do
    end

    get "/" do
      slim :index
    end

    get "/*" do
      path = params[:splat][0]
      @type_schema = schema[path] || halt(404)
      slim :show
    end

    def schema
      @@schema
    end

    def type(attrs)
      return "" if !attrs || !attrs["type"]
      types = attrs["type"].dup.reject { |t| t == "null" }.join("/")
      type = attrs["format"] || types
      if attrs["type"].include?("null")
        "nullable #{type}"
      else
        type
      end
    end
  end
end
