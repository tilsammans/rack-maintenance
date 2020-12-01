require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'

shared_examples "RackMaintenance" do
  let(:app) { Class.new { def call(env); end }.new }
  let(:rack) { Rack::Maintenance.new(app, :file => file_name) }
  let(:data) { data = File.read(file_name) }

  context "without a :file option" do
    it "raises an error" do
      expect {
        Rack::Maintenance.new(app)
      }.to raise_error(ArgumentError)
    end
  end

  context "without maintenance file" do
    before do
      FileUtils.rm(file_name) if File.exists?(file_name)
    end

    it "calls the app" do
      app.should_receive(:call).once
      rack.call({})
    end
  end

  context "with maintenance file" do
    before do
      FileUtils.touch file_name
    end

    after do
      FileUtils.rm file_name
    end

    it "does not call the app" do
      app.should_not_receive :call
      rack.call({})
    end

    it "returns the maintenance response" do
      rack.call({}).should eq [503, {"Content-Type"=>content_type, "Content-Length"=>data.bytesize.to_s}, [data]]
    end

    context "and :env option MAINTENANCE" do
      let(:rack) { Rack::Maintenance.new(app, :file => file_name, :env => "MAINTENANCE") }

      context "outside MAINTENANCE env" do
        it "calls the app" do
          app.should_receive(:call).once
          rack.call({})
        end
      end

      context "inside MAINTENANCE env" do
        before do
          ENV['MAINTENANCE'] = "true"
        end

        after do
          ENV.delete("MAINTENANCE")
        end

        it "does not call the app" do
          app.should_not_receive :call
          rack.call({})
        end

        context "and :processor option" do
          let(:processor) { lambda { |content| ERB.new(content).result } }
          let(:rack) do
            Rack::Maintenance.new(app, :file => file_name, :processor => processor )
          end

          it "passes the file content to the processor" do
            processor.should_receive(:call).with(data).and_call_original
            rack.call({})
          end
        end
      end
    end

    context "without paths" do
      let(:rack) { Rack::Maintenance.new(app, :file => file_name, :without => /\A\/assets/) }

      it "enables access depending on the path" do
        app.should_receive(:call).twice
        rack.call({"PATH_INFO" => "/"})
        rack.call({"PATH_INFO" => "/assets/application.css"})
        rack.call({"PATH_INFO" => "/users"})
        rack.call({"PATH_INFO" => "/assets/application.js"})
        rack.call({"PATH_INFO" => "/stuff"})
      end
    end

    context "and :without_env option MAINTENANCE_ALLOWED_PATHS" do
      let(:rack) { Rack::Maintenance.new(app, :file => file_name, :without => /\A\/assets/, :without_env => "MAINTENANCE_ALLOWED_PATHS") }

      context "outside WITHOUT env" do
        it "enables access depending on the :without default value and the path" do
          app.should_receive(:call).twice
          rack.call({"PATH_INFO" => "/"})
          rack.call({"PATH_INFO" => "/assets/application.css"})
          rack.call({"PATH_INFO" => "/users"})
          rack.call({"PATH_INFO" => "/assets/application.js"})
          rack.call({"PATH_INFO" => "/stuff"})
        end
      end

      context "inside WITHOUT env" do
        before do
          ENV["MAINTENANCE_ALLOWED_PATHS"] = "\/users"
        end

        after do
          ENV.delete("MAINTENANCE_ALLOWED_PATHS")
        end

        it "enables access to paths specified in the env var" do
          app.should_receive(:call).once
          rack.call({"PATH_INFO" => "/"})
          rack.call({"PATH_INFO" => "/assets/application.css"})
          rack.call({"PATH_INFO" => "/users"})
          rack.call({"PATH_INFO" => "/assets/application.js"})
          rack.call({"PATH_INFO" => "/stuff"})
        end
      end
    end
  end
end

describe "RackMaintenance with json maintenance file" do
  it_behaves_like "RackMaintenance" do
    let(:file_name) { "spec/maintenance.json" }
    let(:content_type) { "application/json" }
  end

  it_behaves_like "RackMaintenance" do
    let(:file_name) { Pathname.new("spec/maintenance.json") }
    let(:content_type) { "application/json" }
  end
end

describe "RackMaintenance with html maintenance file" do
  it_behaves_like "RackMaintenance" do
    let(:file_name) { "spec/maintenance.html" }
    let(:content_type) { "text/html" }
  end
end

describe "RackMaintenance with unicode maintenance file" do
  before do
    FileUtils.cp 'spec/unicode.html', 'spec/maintenance.html'
  end
  it_behaves_like "RackMaintenance" do
    let(:file_name) { "spec/maintenance.html" }
    let(:content_type) { "text/html" }
  end
end
