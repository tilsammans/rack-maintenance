require 'rack'

class Rack::Maintenance

  attr_reader :app, :options

  def initialize(app, options={})
    @app     = app
    @options = options

    raise(ArgumentError, 'Must specify a :file') unless options[:file]
  end

  def call(env)
    if maintenance? && path_in_app(env)
      content = File.read(file)
      data = processor.call(content)
      [ 503, { 'Content-Type' => content_type, 'Content-Length' => data.bytesize.to_s }, [data] ]
    else
      app.call(env)
    end
  end

private ######################################################################

  def content_type
    file.to_s.end_with?('json') ? 'application/json' : 'text/html'
  end

  def environment
    options[:env]
  end

  def file
    options[:file]
  end

  def processor
    options[:processor] || lambda { |content| content }
  end

  def maintenance?
    environment ? ENV[environment] : File.exists?(file)
  end

  def path_in_app(env)
    env["PATH_INFO"] !~ without
  end

  def without
    if configurable_allowlist
      Regexp.new(configurable_allowlist)
    else
      options[:without]
    end
  end

  def configurable_allowlist
    if options[:without_env]
      ENV[options[:without_env]]
    end
  end
end
