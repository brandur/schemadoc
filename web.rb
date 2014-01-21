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
      @attributes = build_attributes(@type_schema)
      slim :show
    end

    def build_attributes(type_schema)
      attributes = []
      type_schema["properties"].each do |name, attrs|
        ref = attrs["$ref"] ? schema.find(attrs["$ref"]) : nil
        if ref
          attributes << { "name" => name }.merge(ref)
        else
          first = true
          attrs["properties"].each do |subname, subattrs|
            subref = subattrs["$ref"] ? schema.find(subattrs["$ref"]) : {}
            attribute = { "name" => subname, "subobject" => true }.merge(subref)
            if first
              attribute.merge!({
                "supername" => name,
                "count" => attrs["properties"].count
              })
              first = false
            end
            attributes << attribute
          end
        end
      end
      attributes
    end

    def schema
      @@schema
    end

    def type(attribute)
      return "" if !attribute || !attribute["type"]
      types = attribute["type"].dup.reject { |t| t == "null" }.join("/")
      type = attribute["format"] || types
      if attribute["type"].include?("null")
        "nullable #{type}"
      else
        type
      end
    end
  end
end
