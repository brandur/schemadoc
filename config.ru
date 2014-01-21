require "./web"

Slim::Engine.set_default_options format: :html5, pretty: true

run SchemaDoc::Web
