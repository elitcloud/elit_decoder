require "spec_helper"

RSpec.describe ElitDecoder do
  it "has a version number" do
    expect(ElitDecoder::VERSION).not_to be nil
  end

  describe "#configure" do
    before do
      ElitDecoder.configuration do |config|
        config.python_server_url = "http://localhost:5000/"
        config.java_server_url = "http://localhost:4991/"
      end
    end
    it "should return server_url" do
      expect(ElitDecoder.python_server_url).to eq("http://localhost:5000/")
      expect(ElitDecoder.java_server_url).to eq("http://localhost:4991/")
    end
  end

  describe "#resources" do
    it "should return path of resources" do
      expect(ElitDecoder::RESOURCE_DIR).to eq(File.join(File.expand_path('../../', __FILE__), '/res'))
    end
  end

  describe "#decoder" do
    before  do
      @params = {
        input: "hello world",
        task: "sent",
        is_file: "false",
        arguments: {},
        dependencies: []
      }
    end

    it "should has task tok" do
      # expect(ElitDecoder::Decoder.params_parser(@params)).to eq(true)
      ElitDecoder::Decoder.decode(@params)
    end
  end
end
