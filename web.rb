require "bundler/setup"
Bundler.require

module Committee
  class Schema
    def raw
      @schema
    end
  end
end

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
      @schema_title = @@json["title"]
      @schema_description = @@json["description"]
    end

    get "/" do
      slim :index
    end

    get "/*" do
      path = params[:splat][0]
      @type_schema = schema[path] || halt(404)
      @attributes = build_attributes(@type_schema)
      @object = build_object(@type_schema)
      slim :show
    end

    def build_attributes(type_schema)
      attributes = []
      type_schema["properties"].each do |name, attrs|
        if attrs["$ref"]
          attributes << { "name" => name }.merge(schema.find(attrs["$ref"]))
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

    def build_object(type_schema)
      object = {}
      type_schema["properties"].each do |name, attrs|
        object[name] = if attrs["$ref"]
          ref = schema.find(attrs["$ref"])
          ref["example"]
        else
          build_object(attrs)
        end
      end
      object
    end

    def description(str)
      str.split("\n\n").map { |p| "<p>#{p}</p>" }.join
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
