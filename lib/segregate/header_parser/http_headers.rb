class Segregate
  # HeaderParser
  class HeaderParser
    GENERAL_HEADERS = %w(
      'cache-control',
      'connection',
      'date',
      'pragma',
      'trailer',
      'transfer-encoding',
      'upgrade',
      'via',
      'warning'
    )

    REQUEST_HEADERS = %w(
      'accept',
      'accept-charset',
      'accept-encoding',
      'accept-language',
      'authorization',
      'expect',
      'from',
      'host',
      'if-match',
      'if-modified-Since',
      'if-none-Match',
      'if-range',
      'if-unmodified-Since',
      'max-forwards',
      'proxy-authorization',
      'range',
      'referer',
      'te',
      'user-agent'
    )

    RESPONSE_HEADERS = %w(
      'accept-ranges',
      'age',
      'etag',
      'location',
      'proxy-authenticate',
      'retry-after',
      'server',
      'vary',
      'www-authenticate'
    )

    ENTITY_HEADERS = %w(
      'allow',
      'content-encoding',
      'content-language',
      'content-length',
      'content-location',
      'content-md5',
      'content-range',
      'content-type',
      'expires',
      'last-modified'
    )

    ALL_HEADERS =
      GENERAL_HEADERS + REQUEST_HEADERS + RESPONSE_HEADERS + ENTITY_HEADERS
  end
end
