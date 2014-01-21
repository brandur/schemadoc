require "./web"

Slim::Engine.set_default_options format: :html5, pretty: true

run SchemaDoc::Web
run Rack::Builder.new {
  use Rack::Instruments
  use Rack::Deflater
  run Sinatra::Router.new {
    mount SchemaDoc::Assets
    run SchemaDoc::Web
  }
}
