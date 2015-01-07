require File.expand_path('../../config/environment',  __FILE__)

require 'typhoeus'
#require 'uri'
require 'nokogiri'

class FileCache
  def initialize(root)
    @root = root
  end

  def paths(url)
    uri = URI.parse('http://' + url)
    path = uri.path
    path = "#{path}/index.html" if path.empty? or path[-1] == '/'
    path += '?' + uri.query if uri.query
    %w(body request).map { |p| File.join(@root, p, uri.host, path) }
  end

  def get(request)
    body_path, request_path = paths(request.url)
    return unless File.exists?(body_path)
    return unless File.exists?(request_path)
    options = File.open(request_path) { |f| Marshal.load(f) }
    raise "No Options" unless options.is_a?(Hash)
    body_data = File.open(body_path).read
    Typhoeus::Response.new(options.merge(response_body: body_data))
  end

  def set(request, response)
    body_path, request_path = paths(request.url).tap { |l| l.each do |p|
      FileUtils.mkdir_p(File.dirname(p))
    end}

    options = response.options.dup
    File.open(body_path, 'wb') do |f|
      f.write(options.delete(:response_body) || options.delete(:body))
    end

    File.open(request_path, 'w') { |f| Marshal.dump(options, f) }

    response
  end
end

Typhoeus::Config.cache = FileCache.new('/home/quinn/thisisink/fetch/cache')
