class AppnexusApi::LogLevelDataDownloadService < AppnexusApi::ReadOnlyService
  RETRY_DOWNLOAD_PARAMS = {
    base_interval: 30,
    tries: 20,
    max_elapsed_time: 3600,
    on_retry: Proc.new do |exception, tries|
      connection.logger.warn("Retrying after #{exception.class}: #{tries} attempts.")
    end
  }.freeze

  class BadChecksumException < StandardError; end

  def initialize(connection, options = {})
    @downloaded_files_path = options[:downloaded_files_path] || '.'
    super(connection)
  end

  def download_location(params = {})
    @connection.get(uri_suffix, params).headers['location']
  end

  # Parameter is a LogLevelDataResource
  # Downloads a gzipped file
  # Returns an array of paths to downloaded files
  def download_resource(data_resource)
    data_resource.download_params.map do |params|
      uri = URI.parse(download_location(params.reject { |k, v| k == :checksum }))
      filename = File.join(@downloaded_files_path, "#{params[:siphon_name]}_#{params[:hour]}_#{params[:split_part]}.gz")

      Retriable.retriable(RETRY_DOWNLOAD_PARAMS) do
        download_file(uri, filename)
        calculated_checksum = Digest::MD5.hexdigest(File.read(filename))
        if calculated_checksum != params[:checksum]
          error_message = "Calculated checksum of #{calculated_checksum} doesn't match API provided checksum #{params[:checksum]}"
          puts error_message
          fail(BadChecksumException, error_message)
        end
      end

      filename
    end
  end

  def get
    fail(AppnexusApi::NotImplemented, 'This service is designed to work through download_location method.')
  end

  def uri_name
    'siphon-download'
  end

  private

  def download_file(uri, filename)
    puts "Starting HTTP download for: #{uri.to_s}..."
    http_object = Net::HTTP.new(uri.host, uri.port)
    http_object.use_ssl = true if uri.scheme == 'https'
    begin
      http_object.start do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.read_timeout = 500
        http.request(request) do |response|
          open(filename, 'wb') do |io|
            response.read_body do |chunk|
              io.write(chunk)
            end
          end
        end
      end
    rescue StandardError => e
      puts "=> Exception: '#{e}'. Skipping download."
      return
    end
    puts "Stored download as #{filename}"
  end
end
