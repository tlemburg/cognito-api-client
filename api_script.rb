

# We'll be creating a profile in this example
body = JSON.dump({

})
request_target = 'get /screenings/scr_aH8LHPZkbEE5Z6/revisions'

# Generates a digest using the request body
digest = 'SHA-256=' + Base64.strict_encode64(Digest::SHA256.digest(''))

# Generates a date in this format: Thu, 25 Aug 2016 22:37:14 GMT
date = Time.now.httpdate


# Generates the signing string. Note that the parts of the string are
# concatenated with a newline character
signing_string = [
  "(request-target): #{request_target}",
  "date: #{date}",
  "digest: #{digest}"
].join("\n")

# Creates the HMAC-SHA256 digest using the API secret and then base64
# encodes that value
signature = Base64.strict_encode64(
  OpenSSL::HMAC.digest(
    OpenSSL::Digest::SHA256.new, LOCAL_API_SECRET, signing_string
  )
)

# Creates the authorization header and concatenates it together using
# a comma
authorization = [
  'Signature keyId="' + LOCAL_API_KEY + '"',
  'algorithm="hmac-sha256"',
  'headers="(request-target) date digest"',
  'signature="' + signature + '"'
].join(',')

# Put everything together and execute the request. Note that the headers
# are defined in the same order as they are defined in the Authorization
# header above. They can be in any order, but they must be consistent.
response =
  HTTP.headers(
    'Date'             => date,
    'Digest'           => digest,
    'Authorization'    => authorization,
    'Content-Type'     => content_type,
    'Accept'           => accept_type,
    'Cognito-Version'  => version
  ).get('http://localhost:5000/screenings/scr_aH8LHPZkbEE5Z6/revisions')

puts response.body
