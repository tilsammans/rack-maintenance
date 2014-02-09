require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'
require 'json'

describe "RackMaintenance" do
  let(:app) { Class.new { def call(env); end }.new }

  context "maintenance response" do
    let(:file) { "spec/maintenance.html" }
    let(:rack) { Rack::Maintenance.new(app, :file => file) }

    context "check options" do
      context "without a :file option" do
        it "raises an error" do
          expect {
            Rack::Maintenance.new(app)
          }.to raise_error(ArgumentError)
        end
      end

      context "with wrong options" do
        it "raises an error" do
          expect {
            Rack::Maintenance.new(app, file: file, wrong_option: "text")
          }.to raise_error(ArgumentError,  "Unknown option 'wrong_option'!")
        end
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
        FileUtils.touch file
      end

      after do
        FileUtils.rm file
      end

      it "does not call the app" do
        app.should_not_receive :call
        rack.call({})
      end

      it "returns the maintenance response" do
        rack.call({}).should eq [503, {"Content-Type"=>"text/html", "Content-Length"=>"0"}, [""]]
      end

      context "and :env option MAINTENANCE" do
        let(:rack) { Rack::Maintenance.new(app, :file => file, :env => "MAINTENANCE") }

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

  context "JSON maintenance response" do
    let(:file) { "spec/maintenance.yaml" }
    let(:rack) { Rack::Maintenance.new(app, :file => file, format: "json") }

    after do
      FileUtils.rm file
    end

    context "has maintenance content" do
      before do
        File.open(file, 'w') { |file| file.write("error: 'maintenance'") }
      end

      it "returns the maintenance response" do
        error_message = { error: "maintenance"}.to_json
        rack.call({}).should eq [
          503,
          { "Content-Type"=>"application/json",
            "Content-Length"=>error_message.length.to_s},
            [ error_message ]]
      end
    end

    context "hasn't maintenance content" do
      before do
        FileUtils.touch file
      end

      it "returns the maintenance response" do
        rack.call({}).should eq [
          503,
          { "Content-Type"=>"application/json", "Content-Length"=>"0"}, [""]]
      end
    end
  end

  context "with signal file" do
    let(:file) { "spec/maintenance.html" }
    let(:signal_file) { "spec/maintenance.txt" }
    let(:rack) { Rack::Maintenance.new(app, file: file, signal_file: signal_file) }

    context "without maintenance file" do
      it "calls the app" do
        app.should_receive(:call).once
        rack.call({})
      end
    end

    context "with maintenance file" do
      before do
        FileUtils.touch file
        FileUtils.touch signal_file
      end

      after do
        FileUtils.rm file
        FileUtils.rm signal_file
      end

      it "does not call the app" do
        app.should_not_receive :call
        rack.call({})
      end

      it "returns the maintenance response" do
        rack.call({}).should eq [503, {"Content-Type"=>"text/html", "Content-Length"=>"0"}, [""]]
      end
    end
  end
end
