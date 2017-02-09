require 'spec_helper'

describe AppnexusApi::Connection do
  subject do
    connection = AppnexusApi::Connection.new({})
    connection.logger.level = Logger::FATAL
    connection
  end
  let(:connection_with_null_logger) { AppnexusApi::Connection.new(connection_params) }

  it 'allows no logger to be specified' do
    expect { AppnexusApi::CreativeService.new(connection_with_null_logger) }.to_not raise_error
  end

  it 'returns data from expiration' do
    #stub to raise error the first time and then return []
    counter = 0
    allow(subject).to receive(:login)
    allow(subject.connection).to receive(:run_request) do |arg|
      counter += 1
      raise AppnexusApi::Unauthorized.new if counter == 1
      Faraday::Response.new(body: { not_an_error: 1 })
    end
    expect(subject.run_request(:get, 'http://localhost', nil, {})).not_to eq({})
  end
end
