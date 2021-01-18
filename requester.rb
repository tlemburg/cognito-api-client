require 'http' # https://github.com/httprb/http
require 'digest'
require 'base64'
require 'base58'
require 'openssl'

class Requester
  attr_reader :digest, :request_target
  attr_accessor :mode

  def initialize(mode:)
    @mode = mode
  end

  def get(url)
    set_digest('')
    set_request_target('get', URI.decode(url))
    response = HTTP.headers(request_headers).get("#{prefix}#{url}")
    clear_date
    format_response(response)
  end

  def post(url, params)
    body = JSON.dump(params)
    set_digest(body)
    set_request_target('post', url)

    response = HTTP.headers(request_headers).post("#{prefix}#{url}", body: body)
    clear_date
    format_response(response)
  end

  def patch(url, params)
    body = JSON.dump(params)
    set_digest(body)
    set_request_target('patch', url)

    response = HTTP.headers(request_headers).patch("#{prefix}#{url}", body: body)
    clear_date
    format_response(response)
  end

  def format_response(response)
    (JSON.parse response.body.to_s)
  end

  private

  def prefix
    case @mode
    when :development
      'http://localhost:5000'
    when :staging
      'https://staging.cognitohq.com'
    end
  end

  def set_digest(string)
    @digest = 'SHA-256=' + Base64.strict_encode64(Digest::SHA256.digest(string))
  end

  def set_request_target(method, url)
    @request_target = "#{method} #{url}"
  end

  def request_headers
    {
      'Date'             => date,
      'Digest'           => digest,
      'Authorization'    => authorization,
      'Content-Type'     => content_type,
      'Accept'           => accept_type,
      'Cognito-Version'  => version
    }
  end

  def clear_date
    @date = nil
  end

  def date
    @date ||= Time.now.httpdate
  end

  def authorization
    [
      'Signature keyId="' + api_key + '"',
      'algorithm="hmac-sha256"',
      'headers="(request-target) date digest"',
      'signature="' + signature + '"'
    ].join(',')
  end

  def signing_string
    [
      "(request-target): #{request_target}",
      "date: #{date}",
      "digest: #{digest}"
    ].join("\n")
  end

  def signature
    Base64.strict_encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::SHA256.new, api_secret, signing_string
      )
    )
  end

  def api_key
    case @mode
    when :development
      ENV['LOCAL_API_KEY']
    when :staging
      ENV['STAGING_API_KEY']
    end
  end

  def api_secret
    case @mode
    when :development
      ENV['LOCAL_API_SECRET']
    when :staging
      ENV['STAGING_API_SECRET']
    end
  end

  def content_type
    'application/vnd.api+json'
  end

  def accept_type
    'application/vnd.api+json'
  end

  def version
    '2020-08-14'
  end
end
