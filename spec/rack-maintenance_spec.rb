require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'

describe "RackMaintenance" do
  let(:app) { Class.new { def call(env); end }.new }
  let(:rack) { Rack::Maintenance.new(app, :file => "spec/maintenance.html") }

  context "without a :file option" do
    it "raises an error" do
      expect {
        Rack::Maintenance.new(app)
      }.to raise_error(ArgumentError)
    end
  end

  context "without maintenance file" do
    it "calls the app" do
      app.should_receive(:call).once
      rack.call({})
    end
  end

  context "with maintenance file" do
    before do
      FileUtils.touch 'spec/maintenance.html'
    end

    after do
      FileUtils.rm 'spec/maintenance.html'
    end

    it "does not call the app" do
      app.should_not_receive :call
      rack.call({})
    end

    it "returns the maintenance response" do
      rack.call({}).should eq [503, {"Content-Type"=>"text/html", "Content-Length"=>"0"}, [""]]
    end

    context "and :env option MAINTENANCE" do
      let(:rack) { Rack::Maintenance.new(app, :file => "spec/maintenance.html", :env => "MAINTENANCE") }

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

        it "does not call the app" do
          app.should_not_receive :call
          rack.call({})
        end
      end
    end

    context "and request to /assets" do
      it "calls the app" do
        app.should_receive(:call).once
        rack.call({"PATH_INFO"=>"/assets/application.css"})
      end
    end
  end
end
