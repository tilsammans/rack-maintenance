require 'rack'
require 'json'

class Rack::Maintenance

  attr_reader :app, :options

  def initialize(app, options={})
    @app     = app
    @options = options
    check_options(options)
  end

  def call(env)
    if maintenance? && path_in_app(env)
      maintenance_response
    else
      app.call(env)
    end
  end

private ######################################################################

  def check_options(options)
    return raise(ArgumentError, 'Must specify a :file') unless options[:file]
    options.keys.map do |option|
      unless [ "file", "signal_file", "env", "format"].include?(option.to_s)
        raise(ArgumentError, "Unknown option '#{option}'!")
      end
    end
  end

  def environment
    options[:env]
  end

  def signal_file
    options[:signal_file]
  end

  def file
    options[:file]
  end

  def maintenance?
    environment ? ENV[environment] : File.exists?(signal_file || file)
  end

  def path_in_app(env)
    env["PATH_INFO"] !~ /^\/assets/
  end

  def maintenance_response
    response = nil
    case options[:format]
    when "json"
      response = json_response
    else
      response = html_response
    end
    [ 503,
      { 'Content-Type' => response[:format],
        'Content-Length' => response[:data].length.to_s },
      [ response[:data] ] ]
  end

  def html_response
    { data: File.read(file),
      format: 'text/html' }
  end

  def json_response
    { data: (content = YAML.load_file(file)) ? content.to_json : '',
      format: 'application/json' }
  end
end
