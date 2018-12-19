#
# Author:: Adam Leff (<adamleff@chef.io)
# Author:: Ryan Cragun (<ryan@chef.io>)
#
# Copyright:: Copyright 2012-2018, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "chef/data_collector"
require "chef/resource_builder"

describe Chef::DataCollector do

  describe ".register_reporter?" do
    context "when no data collector URL or output locations are configured" do
      it "returns false" do
        Chef::Config[:data_collector][:server_url] = nil
        Chef::Config[:data_collector][:output_locations] = nil
        expect(Chef::DataCollector.register_reporter?).to be_falsey
      end
    end

    context "when a data collector URL is configured" do
      before do
        Chef::Config[:data_collector][:server_url] = "http://data_collector"
      end

      context "when operating in why_run mode" do
        it "returns false" do
          Chef::Config[:why_run] = true
          expect(Chef::DataCollector.register_reporter?).to be_falsey
        end
      end

      context "when not operating in why_run mode" do

        before do
          Chef::Config[:why_run] = false
          Chef::Config[:data_collector][:token] = token
        end

        context "when a token is configured" do

          let(:token) { "supersecrettoken" }

          context "when report is enabled for current mode" do
            it "returns true" do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(true)
              expect(Chef::DataCollector.register_reporter?).to be_truthy
            end
          end

          context "when report is disabled for current mode" do
            it "returns false" do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(false)
              expect(Chef::DataCollector.register_reporter?).to be_falsey
            end
          end

        end

        # `Chef::Config[:data_collector][:server_url]` defaults to a URL
        # relative to the `chef_server_url`, so we use configuration of the
        # token to infer whether a solo/local mode user intends for data
        # collection to be enabled.
        context "when a token is not configured" do

          let(:token) { nil }

          context "when report is enabled for current mode" do

            before do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(true)
            end

            context "when the current mode is solo" do

              before do
                Chef::Config[:solo] = true
              end

              it "returns true" do
                expect(Chef::DataCollector.register_reporter?).to be(true)
              end

            end

            context "when the current mode is local mode" do

              before do
                Chef::Config[:local_mode] = true
              end

              it "returns false" do
                expect(Chef::DataCollector.register_reporter?).to be(true)
              end
            end

            context "when the current mode is client mode" do

              before do
                Chef::Config[:local_mode] = false
                Chef::Config[:solo] = false
              end

              it "returns true" do
                expect(Chef::DataCollector.register_reporter?).to be_truthy
              end

            end

          end

          context "when report is disabled for current mode" do
            it "returns false" do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(false)
              expect(Chef::DataCollector.register_reporter?).to be_falsey
            end
          end

        end

      end
    end

    context "when output_locations are configured" do
      before do
        Chef::Config[:data_collector][:output_locations] = ["http://data_collector", "/tmp/data_collector.json"]
      end

      context "when operating in why_run mode" do
        it "returns false" do
          Chef::Config[:why_run] = true
          expect(Chef::DataCollector.register_reporter?).to be_falsey
        end
      end

      context "when not operating in why_run mode" do

        before do
          Chef::Config[:why_run] = false
          Chef::Config[:data_collector][:token] = token
        end

        context "when a token is configured" do

          let(:token) { "supersecrettoken" }

          context "when report is enabled for current mode" do
            it "returns true" do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(true)
              expect(Chef::DataCollector.register_reporter?).to be_truthy
            end
          end

          context "when report is disabled for current mode" do
            it "returns false" do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(false)
              expect(Chef::DataCollector.register_reporter?).to be_falsey
            end
          end

        end

        # `Chef::Config[:data_collector][:server_url]` defaults to a URL
        # relative to the `chef_server_url`, so we use configuration of the
        # token to infer whether a solo/local mode user intends for data
        # collection to be enabled.
        context "when a token is not configured" do

          let(:token) { nil }

          context "when report is enabled for current mode" do

            before do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(true)
            end

            context "when the current mode is solo" do

              before do
                Chef::Config[:solo] = true
              end

              it "returns true" do
                expect(Chef::DataCollector.register_reporter?).to be(true)
              end

            end

            context "when the current mode is local mode" do

              before do
                Chef::Config[:local_mode] = true
              end

              it "returns false" do
                expect(Chef::DataCollector.register_reporter?).to be(true)
              end
            end

            context "when the current mode is client mode" do

              before do
                Chef::Config[:local_mode] = false
                Chef::Config[:solo] = false
              end

              it "returns true" do
                expect(Chef::DataCollector.register_reporter?).to be_truthy
              end

            end

          end

          context "when report is disabled for current mode" do
            it "returns false" do
              allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(false)
              expect(Chef::DataCollector.register_reporter?).to be_falsey
            end
          end

        end

      end
    end
  end

  describe ".reporter_enabled_for_current_mode?" do
    context "when running in solo mode" do
      before do
        Chef::Config[:solo] = true
        Chef::Config[:local_mode] = false
      end

      context "when data_collector_mode is :solo" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :solo
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end

      context "when data_collector_mode is :client" do
        it "returns false" do
          Chef::Config[:data_collector][:mode] = :client
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(false)
        end
      end

      context "when data_collector_mode is :both" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :both
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end
    end

    context "when running in local mode" do
      before do
        Chef::Config[:solo] = false
        Chef::Config[:local_mode] = true
      end

      context "when data_collector_mode is :solo" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :solo
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end

      context "when data_collector_mode is :client" do
        it "returns false" do
          Chef::Config[:data_collector][:mode] = :client
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(false)
        end
      end

      context "when data_collector_mode is :both" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :both
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end
    end

    context "when running in client mode" do
      before do
        Chef::Config[:solo] = false
        Chef::Config[:local_mode] = false
      end

      context "when data_collector_mode is :solo" do
        it "returns false" do
          Chef::Config[:data_collector][:mode] = :solo
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(false)
        end
      end

      context "when data_collector_mode is :client" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :client
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end

      context "when data_collector_mode is :both" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :both
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end
    end
  end

end

describe Chef::DataCollector::Reporter do
  let(:reporter) { described_class.new }
  let(:run_status) { Chef::RunStatus.new(Chef::Node.new, Chef::EventDispatch::Dispatcher.new) }

  let(:token) { "supersecrettoken" }

  before do
    Chef::Config[:data_collector][:server_url] = "http://my-data-collector-server.mycompany.com"
    Chef::Config[:data_collector][:token] = token
  end

  describe "selecting token or signed header authentication" do

    context "when the token is set in the config" do

      before do
        Chef::Config[:client_key] = "/no/key/should/exist/at/this/path.pem"
      end

      it "configures an HTTP client that doesn't do signed header auth" do
        # Initializing with the wrong kind of HTTP class should cause Chef::Exceptions::PrivateKeyMissing
        expect { reporter.http }.to_not raise_error
      end

    end

    context "when no token is set in the config" do

      let(:token) { nil }

      let(:client_key) { File.join(CHEF_SPEC_DATA, "ssl", "private_key.pem") }

      before do
        Chef::Config[:client_key] = client_key
      end

      it "configures an HTTP client that does signed header auth" do
        expect { reporter.http }.to_not raise_error
        expect(reporter.http.options).to have_key(:signing_key_filename)
        expect(reporter.http.options[:signing_key_filename]).to eq(client_key)
      end
    end

  end

  describe "#run_started" do
    before do
      allow(reporter).to receive(:update_run_status)
      allow(reporter).to receive(:send_to_data_collector)
      allow(Chef::DataCollector::Messages).to receive(:run_start_message)
    end

    it "updates the run status" do
      expect(reporter).to receive(:update_run_status).with(run_status)
      reporter.run_started(run_status)
    end

    it "sends the RunStart message output to the Data Collector server" do
      expect(Chef::DataCollector::Messages)
        .to receive(:run_start_message)
        .with(run_status)
        .and_return(key: "value")
      expect(reporter).to receive(:send_to_data_collector).with({ key: "value" })
      reporter.run_started(run_status)
    end
  end

  describe "when sending a message at chef run completion" do

    let(:node) { Chef::Node.new }

    let(:run_status) do
      instance_double("Chef::RunStatus",
                      run_id: "run_id",
                      node: node,
                      start_time: Time.new,
                      end_time: Time.new,
                      exception: exception)
    end

    before do
      reporter.send(:update_run_status, run_status)
    end

    describe "#run_completed" do

      let(:exception) { nil }

      it "sends the run completion" do
        expect(reporter).to receive(:send_to_data_collector) do |message|
          expect(message).to be_a(Hash)
          expect(message["status"]).to eq("success")
        end
        reporter.run_completed(node)
      end
    end

    describe "#run_failed" do

      let(:exception) { StandardError.new("oops") }

      it "updates the exception and sends the run completion" do
        expect(reporter).to receive(:send_to_data_collector) do |message|
          expect(message).to be_a(Hash)
          expect(message["status"]).to eq("failure")
        end
        reporter.run_failed("test_exception")
      end
    end
  end

  describe "#converge_start" do
    it "stashes the run_context for later use" do
      reporter.converge_start("test_context")
      expect(reporter.run_context).to eq("test_context")
    end
  end

  describe "#run_list_expanded" do
    it "sets the expanded run list" do
      reporter.run_list_expanded("test_run_list")
      expect(reporter.expanded_run_list).to eq("test_run_list")
    end
  end

  describe "#run_list_expand_failed" do
    let(:node)         { double("node") }
    let(:error_mapper) { double("error_mapper") }
    let(:exception)    { double("exception") }

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:run_list_expand_failed).with(
        node,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.run_list_expand_failed(node, exception)
    end
  end

  describe "#cookbook_resolution_failed" do
    let(:error_mapper)      { double("error_mapper") }
    let(:exception)         { double("exception") }
    let(:expanded_run_list) { double("expanded_run_list") }

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:cookbook_resolution_failed).with(
        expanded_run_list,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.cookbook_resolution_failed(expanded_run_list, exception)
    end

  end

  describe "#cookbook_sync_failed" do
    let(:cookbooks)    { double("cookbooks") }
    let(:error_mapper) { double("error_mapper") }
    let(:exception)    { double("exception") }

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:cookbook_sync_failed).with(
        cookbooks,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.cookbook_sync_failed(cookbooks, exception)
    end
  end

  describe "#disable_reporter_on_error" do
    context "when no exception is raise by the block" do
      it "does not disable the reporter" do
        expect(reporter).not_to receive(:disable_data_collector_reporter)
        reporter.send(:disable_reporter_on_error) { true }
      end

      it "does not raise an exception" do
        expect { reporter.send(:disable_reporter_on_error) { true } }.not_to raise_error
      end
    end

    context "when an unexpected exception is raised by the block" do
      it "re-raises the exception" do
        expect { reporter.send(:disable_reporter_on_error) { raise "bummer" } }.to raise_error(RuntimeError)
      end
    end

    [ Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError,
      Errno::EHOSTDOWN ].each do |exception_class|
      context "when the block raises a #{exception_class} exception" do
        it "disables the reporter" do
          expect(reporter).to receive(:disable_data_collector_reporter)
          reporter.send(:disable_reporter_on_error) { raise exception_class.new("bummer") }
        end

        context "when raise-on-failure is enabled" do
          it "logs an error and raises" do
            Chef::Config[:data_collector][:raise_on_failure] = true
            expect(Chef::Log).to receive(:error)
            expect { reporter.send(:disable_reporter_on_error) { raise exception_class.new("bummer") } }.to raise_error(exception_class)
          end
        end

        context "when raise-on-failure is disabled" do
          it "logs an info message and does not raise an exception" do
            Chef::Config[:data_collector][:raise_on_failure] = false
            expect(Chef::Log).to receive(:info)
            expect { reporter.send(:disable_reporter_on_error) { raise exception_class.new("bummer") } }.not_to raise_error
          end
        end
      end
    end
  end

  describe "#validate_data_collector_server_url!" do
    context "when server_url is empty" do
      it "raises an exception" do
        Chef::Config[:data_collector][:server_url] = ""
        expect { reporter.send(:validate_data_collector_server_url!) }.to raise_error(Chef::Exceptions::ConfigurationError)
      end
    end

    context "when server_url is omitted but output_locations is specified" do
      it "does not an exception" do
        Chef::Config[:data_collector][:output_locations] = ["http://data_collector", "/tmp/data_collector.json"]
        expect { reporter.send(:validate_data_collector_server_url!) }.not_to raise_error(Chef::Exceptions::ConfigurationError)
      end
    end

    context "when server_url is not empty" do
      context "when server_url is an invalid URI" do
        it "raises an exception" do
          Chef::Config[:data_collector][:server_url] = "this is not a URI"
          expect { reporter.send(:validate_data_collector_server_url!) }.to raise_error(Chef::Exceptions::ConfigurationError)
        end
      end

      context "when server_url is a valid URI" do
        context "when server_url is a URI with no host" do
          it "raises an exception" do
            Chef::Config[:data_collector][:server_url] = "/file/uri.txt"
            expect { reporter.send(:validate_data_collector_server_url!) }.to raise_error(Chef::Exceptions::ConfigurationError)
          end

        end

        context "when server_url is a URI with a valid host" do
          it "does not an exception" do
            Chef::Config[:data_collector][:server_url] = "http://www.google.com/data-collector"
            expect { reporter.send(:validate_data_collector_server_url!) }.not_to raise_error
          end
        end
      end
    end
  end

  describe "#validate_data_collector_output_locations!" do
    context "when output_locations is empty" do
      it "raises an exception" do
        Chef::Config[:data_collector][:output_locations] = {}
        expect { reporter.send(:validate_data_collector_output_locations!) }.to raise_error(Chef::Exceptions::ConfigurationError)
      end
    end

    context "when valid output_locations are provided" do
      it "does not raise an exception" do
        expect(reporter).to receive(:open).with("data_collection.json", "a")
        Chef::Config[:data_collector][:output_locations] = { urls: ["http://data_collector"], files: ["data_collection.json"] }
        expect { reporter.send(:validate_data_collector_output_locations!) }.not_to raise_error(Chef::Exceptions::ConfigurationError)
      end
    end

    context "when output_locations contains an invalid URI" do
      it "raises an exception" do
        Chef::Config[:data_collector][:output_locations] = { urls: ["this is not a url"], files: ["/tmp/data_collection.json"] }
        expect { reporter.send(:validate_data_collector_output_locations!) }.to raise_error(Chef::Exceptions::ConfigurationError)
      end
    end
  end
end
