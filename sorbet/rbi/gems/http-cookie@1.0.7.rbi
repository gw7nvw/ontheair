# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `http-cookie` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module HTTP
end

class HTTP::Cookie
  include(::Comparable)

  def initialize(*args); end

  def <=>(other); end
  def acceptable?; end
  def acceptable_from_uri?(uri); end
  def accessed_at; end
  def accessed_at=(_); end
  def cookie_value; end
  def created_at; end
  def created_at=(_); end
  def domain; end
  def domain=(domain); end
  def domain_name; end
  def dot_domain; end
  def encode_with(coder); end
  def expire!; end
  def expired?(time = T.unsafe(nil)); end
  def expires; end
  def expires=(t); end
  def expires_at; end
  def expires_at=(t); end
  def for_domain; end
  def for_domain=(_); end
  def for_domain?; end
  def httponly; end
  def httponly=(_); end
  def httponly?; end
  def init_with(coder); end
  def inspect; end
  def max_age; end
  def max_age=(sec); end
  def name; end
  def name=(name); end
  def origin; end
  def origin=(origin); end
  def path; end
  def path=(path); end
  def secure; end
  def secure=(_); end
  def secure?; end
  def session; end
  def session?; end
  def set_cookie_value; end
  def to_s; end
  def to_yaml_properties; end
  def valid_for_uri?(uri); end
  def value; end
  def value=(value); end
  def yaml_initialize(tag, map); end

  class << self
    def cookie_value(cookies); end
    def cookie_value_to_hash(cookie_value); end
    def parse(set_cookie, origin, options = T.unsafe(nil), &block); end
    def path_match?(base_path, target_path); end
  end
end

HTTP::Cookie::MAX_COOKIES_PER_DOMAIN = T.let(T.unsafe(nil), Fixnum)

HTTP::Cookie::MAX_COOKIES_TOTAL = T.let(T.unsafe(nil), Fixnum)

HTTP::Cookie::MAX_LENGTH = T.let(T.unsafe(nil), Fixnum)

HTTP::Cookie::PERSISTENT_PROPERTIES = T.let(T.unsafe(nil), Array)

class HTTP::Cookie::Scanner < ::StringScanner
  def initialize(string, logger = T.unsafe(nil)); end

  def parse_cookie_date(s); end
  def scan_cookie; end
  def scan_dquoted; end
  def scan_name; end
  def scan_name_value(comma_as_separator = T.unsafe(nil)); end
  def scan_set_cookie; end
  def scan_value(comma_as_separator = T.unsafe(nil)); end
  def skip_wsp; end

  private

  def tuple_to_time(day_of_month, month, year, time); end

  class << self
    def quote(s); end
  end
end

HTTP::Cookie::Scanner::RE_BAD_CHAR = T.let(T.unsafe(nil), Regexp)

HTTP::Cookie::Scanner::RE_COOKIE_COMMA = T.let(T.unsafe(nil), Regexp)

HTTP::Cookie::Scanner::RE_NAME = T.let(T.unsafe(nil), Regexp)

HTTP::Cookie::Scanner::RE_WSP = T.let(T.unsafe(nil), Regexp)

HTTP::Cookie::UNIX_EPOCH = T.let(T.unsafe(nil), Time)

module HTTP::Cookie::URIParser

  private

  def escape_path(path); end
  def parse(uri); end

  class << self
    def escape_path(path); end
    def parse(uri); end
  end
end

HTTP::Cookie::URIParser::URIREGEX = T.let(T.unsafe(nil), Regexp)

HTTP::Cookie::VERSION = T.let(T.unsafe(nil), String)

class HTTP::CookieJar
  include(::Enumerable)

  def initialize(options = T.unsafe(nil)); end

  def <<(cookie); end
  def add(cookie); end
  def cleanup(session = T.unsafe(nil)); end
  def clear; end
  def cookies(url = T.unsafe(nil)); end
  def delete(cookie); end
  def each(uri = T.unsafe(nil), &block); end
  def empty?(url = T.unsafe(nil)); end
  def load(readable, *options); end
  def parse(set_cookie, origin, options = T.unsafe(nil)); end
  def save(writable, *options); end
  def store; end

  private

  def get_impl(base, value, *args); end
  def initialize_copy(other); end

  class << self
    def const_missing(name); end
  end
end

class HTTP::CookieJar::AbstractSaver
  def initialize(options = T.unsafe(nil)); end

  def load(io, jar); end
  def save(io, jar); end

  private

  def default_options; end

  class << self
    def class_to_symbol(klass); end
    def implementation(symbol); end
    def inherited(subclass); end
  end
end

class HTTP::CookieJar::AbstractStore
  include(::MonitorMixin)
  include(::Enumerable)

  def initialize(options = T.unsafe(nil)); end

  def add(cookie); end
  def cleanup(session = T.unsafe(nil)); end
  def clear; end
  def delete(cookie); end
  def each(uri = T.unsafe(nil), &block); end
  def empty?; end

  private

  def default_options; end
  def initialize_copy(other); end

  class << self
    def class_to_symbol(klass); end
    def implementation(symbol); end
    def inherited(subclass); end
  end
end

class HTTP::CookieJar::CookiestxtSaver < ::HTTP::CookieJar::AbstractSaver
  def load(io, jar); end
  def save(io, jar); end

  private

  def cookie_to_record(cookie); end
  def default_options; end
  def parse_record(line); end
end

HTTP::CookieJar::CookiestxtSaver::False = T.let(T.unsafe(nil), String)

HTTP::CookieJar::CookiestxtSaver::HTTPONLY_PREFIX = T.let(T.unsafe(nil), String)

HTTP::CookieJar::CookiestxtSaver::RE_HTTPONLY_PREFIX = T.let(T.unsafe(nil), Regexp)

HTTP::CookieJar::CookiestxtSaver::True = T.let(T.unsafe(nil), String)

class HTTP::CookieJar::HashStore < ::HTTP::CookieJar::AbstractStore
  def initialize(options = T.unsafe(nil)); end

  def add(cookie); end
  def cleanup(session = T.unsafe(nil)); end
  def clear; end
  def default_options; end
  def delete(cookie); end
  def each(uri = T.unsafe(nil)); end

  private

  def initialize_copy(other); end
end

class HTTP::CookieJar::YAMLSaver < ::HTTP::CookieJar::AbstractSaver
  def load(io, jar); end
  def save(io, jar); end

  private

  def default_options; end
  def load_yaml(yaml); end
end
