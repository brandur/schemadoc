require "bundler/setup"
Bundler.require

module SchemaDoc
  class Config
    def self.schema_url
      ENV["SCHEMA_URL"]
    end
  end

  class Web < Sinatra::Base
    @@schema ||= Excon.get(Config.schema_url,
      expects: 200,
      headers: {
        "Accept" => "application/vnd.heroku+json; version=3"
      }
    ).body

    before do
    end

    get "/" do
      @@schema
    end
  end
end
