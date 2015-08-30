#!/usr/bin/env ruby

require 'net/http'
require 'json'

class Client
  attr_accessor :host
  attr_accessor :port
  attr_accessor :path
  attr_accessor :sessionId

  def initialize(host = '127.0.0.1', port = 9091, path = '/transmission/rpc')
    @host = host
    @port = port
    @path = path
  end

  def uri
    URI("http://#{host}:#{port}#{path}")
  end

  def http
    http = Net::HTTP.new(host,port)
    http.open_timeout = 1
    http.read_timeout = 0.5
    return http
  end

  def post(enable = true)
    req = Net::HTTP::Post.new(uri)
    req['X-Transmission-Session-Id'] = sessionId
    req.body = requestBody(enable)
    res = http.start() do
      http.request(req)
    end
    res = updateSessionIdIfNeed(req, res)
    return res
  end

  def repost(req)
    req['X-Transmission-Session-Id'] = sessionId
    res = http.start() do
      http.request(req)
    end
    return res
  end

  def updateSessionIdIfNeed(req, res)
    if res.class == Net::HTTPConflict and res.code == '409' then
      @sessionId = res['X-Transmission-Session-Id']
      return repost(req)
    else
      return res
    end
  end

  def requestBody(enable)
    bodyHash = {
      :method => 'session-set',
      :arguments => {
        'alt-speed-enabled' => enable
      }
    }
    return bodyHash.to_json
  end

end

if __FILE__ == $0
  enable = ARGV[0] != '1'
  client = Client.new
  puts enable
  res = client.post(enable)
  puts res.body
end
