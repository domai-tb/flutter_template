/// response status code is not 200
class ServerException implements Exception {}

// failed to parse
class ParseException implements Exception {}

/// expected response is not existing
class EmptyResponseException implements Exception {}

/// Generic authentication error (e.g. invalid credentials / expired session).
class AuthenticationException implements Exception {}

/// object is not valid JSON
class JsonException implements Exception {}

/// some unexpected error occured
class UnexpectedException implements Exception {}

/// No connection to a remote dependency.
class NoConnectionException implements Exception {}

/// Too many requests to a remote dependency.
class RateLimitException implements Exception {}
