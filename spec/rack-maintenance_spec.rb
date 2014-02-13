require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'

shared_examples "RackMaintenance" do
  let(:app) { Class.new { def call(env); end }.new }
  let(:rack) { Rack::Maintenance.new(app, :file => file_name) }

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
      rack.call({}).should eq [503, {"Content-Type"=>content_type, "Content-Length"=>"0"}, [""]]
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

describe "RackMaintenance with json maintenance file" do
  it_behaves_like "RackMaintenance" do
    let(:file_name) { "spec/maintenance.json" }
    let(:content_type) { "application/json" }
  end
end

describe "RackMaintenance with html maintenance file" do
  it_behaves_like "RackMaintenance" do
    let(:file_name) { "spec/maintenance.html" }
    let(:content_type) { "text/html" }
  end
end

