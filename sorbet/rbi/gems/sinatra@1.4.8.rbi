# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `sinatra` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

class Rack::Builder
  include(::Sinatra::Delegator)

  def initialize(default_app = T.unsafe(nil), &block); end

  def call(env); end
  def map(path, &block); end
  def run(app); end
  def to_app; end
  def use(middleware, *args, &block); end

  private

  def generate_map(default_app, mapping); end

  class << self
    def app(default_app = T.unsafe(nil), &block); end
    def new_from_string(builder_script, file = T.unsafe(nil)); end
    def parse_file(config, opts = T.unsafe(nil)); end
  end
end

module Sinatra
  class << self
    def helpers(*extensions, &block); end
    def new(base = T.unsafe(nil), &block); end
    def register(*extensions, &block); end
    def use(*args, &block); end
  end
end

class Sinatra::Application < ::Sinatra::Base
  include(::WillPaginate::I18n)
  include(::WillPaginate::ViewHelpers)
  include(::WillPaginate::Sinatra::Helpers)
  extend(::WillPaginate::Sinatra)

  class << self
    def app_file; end
    def app_file=(val); end
    def app_file?; end
    def logging; end
    def logging=(val); end
    def logging?; end
    def method_override; end
    def method_override=(val); end
    def method_override?; end
    def register(*extensions, &block); end
    def run; end
    def run=(val); end
    def run?; end
    def session_secret; end
    def session_secret=(val); end
    def session_secret?; end
  end
end

class Sinatra::Base
  include(::Rack::Utils)
  include(::Sinatra::Helpers)
  include(::Sinatra::Templates)

  def initialize(app = T.unsafe(nil)); end

  def app; end
  def app=(_); end
  def call(env); end
  def call!(env); end
  def env; end
  def env=(_); end
  def forward; end
  def halt(*response); end
  def options; end
  def params; end
  def params=(_); end
  def pass(&block); end
  def request; end
  def request=(_); end
  def response; end
  def response=(_); end
  def settings; end
  def template_cache; end

  private

  def dispatch!; end
  def dump_errors!(boom); end
  def error_block!(key, *block_params); end
  def filter!(type, base = T.unsafe(nil)); end
  def force_encoding(*args); end
  def handle_exception!(boom); end
  def indifferent_hash; end
  def indifferent_params(object); end
  def invoke; end
  def process_route(pattern, keys, conditions, block = T.unsafe(nil), values = T.unsafe(nil)); end
  def route!(base = T.unsafe(nil), pass_block = T.unsafe(nil)); end
  def route_eval; end
  def route_missing; end
  def static!(options = T.unsafe(nil)); end

  class << self
    def absolute_redirects; end
    def absolute_redirects=(val); end
    def absolute_redirects?; end
    def add_charset; end
    def add_charset=(val); end
    def add_charset?; end
    def add_filter(type, path = T.unsafe(nil), options = T.unsafe(nil), &block); end
    def after(path = T.unsafe(nil), options = T.unsafe(nil), &block); end
    def app_file; end
    def app_file=(val); end
    def app_file?; end
    def before(path = T.unsafe(nil), options = T.unsafe(nil), &block); end
    def bind; end
    def bind=(val); end
    def bind?; end
    def build(app); end
    def call(env); end
    def caller_files; end
    def caller_locations; end
    def condition(name = T.unsafe(nil), &block); end
    def configure(*envs); end
    def default_encoding; end
    def default_encoding=(val); end
    def default_encoding?; end
    def delete(path, opts = T.unsafe(nil), &bk); end
    def development?; end
    def disable(*opts); end
    def dump_errors; end
    def dump_errors=(val); end
    def dump_errors?; end
    def empty_path_info; end
    def empty_path_info=(val); end
    def empty_path_info?; end
    def enable(*opts); end
    def environment; end
    def environment=(val); end
    def environment?; end
    def error(*codes, &block); end
    def errors; end
    def extensions; end
    def filters; end
    def force_encoding(data, encoding = T.unsafe(nil)); end
    def get(path, opts = T.unsafe(nil), &block); end
    def handler_name; end
    def handler_name=(val); end
    def handler_name?; end
    def head(path, opts = T.unsafe(nil), &bk); end
    def helpers(*extensions, &block); end
    def inline_templates=(file = T.unsafe(nil)); end
    def layout(name = T.unsafe(nil), &block); end
    def link(path, opts = T.unsafe(nil), &bk); end
    def lock; end
    def lock=(val); end
    def lock?; end
    def logging; end
    def logging=(val); end
    def logging?; end
    def method_override; end
    def method_override=(val); end
    def method_override?; end
    def methodoverride=(val); end
    def methodoverride?; end
    def middleware; end
    def mime_type(type, value = T.unsafe(nil)); end
    def mime_types(type); end
    def new(*args, &bk); end
    def new!(*_); end
    def not_found(&block); end
    def options(path, opts = T.unsafe(nil), &bk); end
    def patch(path, opts = T.unsafe(nil), &bk); end
    def port; end
    def port=(val); end
    def port?; end
    def post(path, opts = T.unsafe(nil), &bk); end
    def prefixed_redirects; end
    def prefixed_redirects=(val); end
    def prefixed_redirects?; end
    def production?; end
    def protection; end
    def protection=(val); end
    def protection?; end
    def prototype; end
    def public=(value); end
    def public_dir; end
    def public_dir=(value); end
    def public_folder; end
    def public_folder=(val); end
    def public_folder?; end
    def put(path, opts = T.unsafe(nil), &bk); end
    def quit!; end
    def raise_errors; end
    def raise_errors=(val); end
    def raise_errors?; end
    def register(*extensions, &block); end
    def reload_templates; end
    def reload_templates=(val); end
    def reload_templates?; end
    def reset!; end
    def root; end
    def root=(val); end
    def root?; end
    def routes; end
    def run; end
    def run!(options = T.unsafe(nil), &block); end
    def run=(val); end
    def run?; end
    def running?; end
    def running_server; end
    def running_server=(val); end
    def running_server?; end
    def server; end
    def server=(val); end
    def server?; end
    def session_secret; end
    def session_secret=(val); end
    def session_secret?; end
    def sessions; end
    def sessions=(val); end
    def sessions?; end
    def set(option, value = T.unsafe(nil), ignore_setter = T.unsafe(nil), &block); end
    def settings; end
    def show_exceptions; end
    def show_exceptions=(val); end
    def show_exceptions?; end
    def start!(options = T.unsafe(nil), &block); end
    def static; end
    def static=(val); end
    def static?; end
    def static_cache_control; end
    def static_cache_control=(val); end
    def static_cache_control?; end
    def stop!; end
    def template(name, &block); end
    def templates; end
    def test?; end
    def threaded; end
    def threaded=(val); end
    def threaded?; end
    def traps; end
    def traps=(val); end
    def traps?; end
    def unlink(path, opts = T.unsafe(nil), &bk); end
    def use(middleware, *args, &block); end
    def use_code; end
    def use_code=(val); end
    def use_code?; end
    def views; end
    def views=(val); end
    def views?; end
    def x_cascade; end
    def x_cascade=(val); end
    def x_cascade?; end

    private

    def agent(pattern); end
    def cleaned_caller(keep = T.unsafe(nil)); end
    def compile(path); end
    def compile!(verb, path, block, options = T.unsafe(nil)); end
    def define_singleton(name, content = T.unsafe(nil)); end
    def detect_rack_handler; end
    def encoded(char); end
    def escaped(char, enc = T.unsafe(nil)); end
    def generate_method(method_name, &block); end
    def host_name(pattern); end
    def inherited(subclass); end
    def invoke_hook(name, *args); end
    def provides(*types); end
    def route(verb, path, options = T.unsafe(nil), &block); end
    def safe_ignore(ignore); end
    def setup_common_logger(builder); end
    def setup_custom_logger(builder); end
    def setup_default_middleware(builder); end
    def setup_logging(builder); end
    def setup_middleware(builder); end
    def setup_null_logger(builder); end
    def setup_protection(builder); end
    def setup_sessions(builder); end
    def setup_traps; end
    def start_server(handler, server_settings, handler_name); end
    def synchronize(&block); end
    def user_agent(pattern); end
    def warn(message); end
  end
end

Sinatra::Base::URI_INSTANCE = T.let(T.unsafe(nil), URI::RFC2396_Parser)

class Sinatra::CommonLogger < ::Rack::CommonLogger
  def call(env); end
end

module Sinatra::Delegator

  private

  def after(*args, &block); end
  def before(*args, &block); end
  def configure(*args, &block); end
  def delete(*args, &block); end
  def development?(*args, &block); end
  def disable(*args, &block); end
  def enable(*args, &block); end
  def error(*args, &block); end
  def get(*args, &block); end
  def head(*args, &block); end
  def helpers(*args, &block); end
  def layout(*args, &block); end
  def link(*args, &block); end
  def mime_type(*args, &block); end
  def not_found(*args, &block); end
  def options(*args, &block); end
  def patch(*args, &block); end
  def post(*args, &block); end
  def production?(*args, &block); end
  def put(*args, &block); end
  def register(*args, &block); end
  def set(*args, &block); end
  def settings(*args, &block); end
  def template(*args, &block); end
  def test?(*args, &block); end
  def unlink(*args, &block); end
  def use(*args, &block); end

  class << self
    def delegate(*methods); end
    def target; end
    def target=(_); end
  end
end

module Sinatra::Ext
  class << self
    def get_handler(str); end
  end
end

class Sinatra::ExtendedRack < ::Struct
  def call(env); end

  private

  def after_response(&block); end
  def async?(status, headers, body); end
  def setup_close(env, status, headers, body); end
end

module Sinatra::Helpers
  def attachment(filename = T.unsafe(nil), disposition = T.unsafe(nil)); end
  def back; end
  def body(value = T.unsafe(nil), &block); end
  def cache_control(*values); end
  def client_error?; end
  def content_type(type = T.unsafe(nil), params = T.unsafe(nil)); end
  def error(code, body = T.unsafe(nil)); end
  def etag(value, options = T.unsafe(nil)); end
  def expires(amount, *values); end
  def headers(hash = T.unsafe(nil)); end
  def informational?; end
  def last_modified(time); end
  def logger; end
  def mime_type(type); end
  def not_found(body = T.unsafe(nil)); end
  def not_found?; end
  def redirect(uri, *args); end
  def redirect?; end
  def send_file(path, opts = T.unsafe(nil)); end
  def server_error?; end
  def session; end
  def status(value = T.unsafe(nil)); end
  def stream(keep_open = T.unsafe(nil)); end
  def success?; end
  def time_for(value); end
  def to(addr = T.unsafe(nil), absolute = T.unsafe(nil), add_script_name = T.unsafe(nil)); end
  def uri(addr = T.unsafe(nil), absolute = T.unsafe(nil), add_script_name = T.unsafe(nil)); end
  def url(addr = T.unsafe(nil), absolute = T.unsafe(nil), add_script_name = T.unsafe(nil)); end

  private

  def etag_matches?(list, new_resource = T.unsafe(nil)); end
  def with_params(temp_params); end
end

Sinatra::Helpers::ETAG_KINDS = T.let(T.unsafe(nil), Array)

class Sinatra::Helpers::Stream
  def initialize(scheduler = T.unsafe(nil), keep_open = T.unsafe(nil), &back); end

  def <<(data); end
  def callback(&block); end
  def close; end
  def closed?; end
  def each(&front); end
  def errback(&block); end

  class << self
    def defer(*_); end
    def schedule(*_); end
  end
end

class Sinatra::NotFound < ::NameError
  def http_status; end
end

class Sinatra::Request < ::Rack::Request
  def accept; end
  def accept?(type); end
  def forwarded?; end
  def idempotent?; end
  def link?; end
  def preferred_type(*types); end
  def safe?; end
  def secure?; end
  def unlink?; end
end

class Sinatra::Request::AcceptEntry
  def initialize(entry); end

  def <=>(other); end
  def entry; end
  def method_missing(*args, &block); end
  def params; end
  def params=(_); end
  def priority; end
  def respond_to?(*args); end
  def to_s(full = T.unsafe(nil)); end
  def to_str; end
end

Sinatra::Request::HEADER_PARAM = T.let(T.unsafe(nil), Regexp)

Sinatra::Request::HEADER_VALUE_WITH_PARAMS = T.let(T.unsafe(nil), Regexp)

class Sinatra::Response < ::Rack::Response
  def initialize(*_); end

  def body=(value); end
  def each; end
  def finish; end

  private

  def calculate_content_length?; end
  def drop_body?; end
  def drop_content_info?; end
end

Sinatra::Response::DROP_BODY_RESPONSES = T.let(T.unsafe(nil), Array)

class Sinatra::ShowExceptions < ::Rack::ShowExceptions
  def initialize(app); end

  def call(env); end

  private

  def frame_class(frame); end
  def prefers_plain_text?(env); end
end

Sinatra::ShowExceptions::TEMPLATE = T.let(T.unsafe(nil), String)

module Sinatra::Templates
  def initialize; end

  def asciidoc(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def builder(template = T.unsafe(nil), options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def coffee(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def creole(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def erb(template, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def erubis(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def find_template(views, name, engine); end
  def haml(template, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def less(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def liquid(template, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def markaby(template = T.unsafe(nil), options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def markdown(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def mediawiki(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def nokogiri(template = T.unsafe(nil), options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def rabl(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def radius(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def rdoc(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def sass(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def scss(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def slim(template, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def stylus(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def textile(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end
  def wlang(template, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def yajl(template, options = T.unsafe(nil), locals = T.unsafe(nil)); end

  private

  def compile_template(engine, data, options, views); end
  def render(engine, data, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
  def render_ruby(engine, template, options = T.unsafe(nil), locals = T.unsafe(nil), &block); end
end

module Sinatra::Templates::ContentTyped
  def content_type; end
  def content_type=(_); end
end

Sinatra::VERSION = T.let(T.unsafe(nil), String)

class Sinatra::Wrapper
  def initialize(stack, instance); end

  def call(env); end
  def helpers; end
  def inspect; end
  def settings; end
end