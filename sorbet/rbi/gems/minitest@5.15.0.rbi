# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `minitest` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Minitest
  class << self
    def __run(reporter, options); end
    def after_run(&block); end
    def autorun; end
    def backtrace_filter; end
    def backtrace_filter=(_); end
    def clock_time; end
    def extensions; end
    def extensions=(_); end
    def filter_backtrace(bt); end
    def info_signal; end
    def info_signal=(_); end
    def init_plugins(options); end
    def load_plugins; end
    def parallel_executor; end
    def parallel_executor=(_); end
    def process_args(args = T.unsafe(nil)); end
    def reporter; end
    def reporter=(_); end
    def run(args = T.unsafe(nil)); end
    def run_one_method(klass, method_name); end
  end
end

class Minitest::AbstractReporter
  include(::Mutex_m)

  def lock; end
  def locked?; end
  def passed?; end
  def prerecord(klass, name); end
  def record(result); end
  def report; end
  def start; end
  def synchronize(&block); end
  def try_lock; end
  def unlock; end
end

class Minitest::Assertion < ::Exception
  def error; end
  def location; end
  def result_code; end
  def result_label; end
end

module Minitest::Assertions
  def _synchronize; end
  def assert(test, msg = T.unsafe(nil)); end
  def assert_empty(obj, msg = T.unsafe(nil)); end
  def assert_equal(exp, act, msg = T.unsafe(nil)); end
  def assert_in_delta(exp, act, delta = T.unsafe(nil), msg = T.unsafe(nil)); end
  def assert_in_epsilon(exp, act, epsilon = T.unsafe(nil), msg = T.unsafe(nil)); end
  def assert_includes(collection, obj, msg = T.unsafe(nil)); end
  def assert_instance_of(cls, obj, msg = T.unsafe(nil)); end
  def assert_kind_of(cls, obj, msg = T.unsafe(nil)); end
  def assert_match(matcher, obj, msg = T.unsafe(nil)); end
  def assert_nil(obj, msg = T.unsafe(nil)); end
  def assert_operator(o1, op, o2 = T.unsafe(nil), msg = T.unsafe(nil)); end
  def assert_output(stdout = T.unsafe(nil), stderr = T.unsafe(nil)); end
  def assert_path_exists(path, msg = T.unsafe(nil)); end
  def assert_predicate(o1, op, msg = T.unsafe(nil)); end
  def assert_raises(*exp); end
  def assert_respond_to(obj, meth, msg = T.unsafe(nil)); end
  def assert_same(exp, act, msg = T.unsafe(nil)); end
  def assert_send(send_ary, m = T.unsafe(nil)); end
  def assert_silent; end
  def assert_throws(sym, msg = T.unsafe(nil)); end
  def capture_io; end
  def capture_subprocess_io; end
  def diff(exp, act); end
  def exception_details(e, msg); end
  def fail_after(y, m, d, msg); end
  def flunk(msg = T.unsafe(nil)); end
  def message(msg = T.unsafe(nil), ending = T.unsafe(nil), &default); end
  def mu_pp(obj); end
  def mu_pp_for_diff(obj); end
  def pass(_msg = T.unsafe(nil)); end
  def refute(test, msg = T.unsafe(nil)); end
  def refute_empty(obj, msg = T.unsafe(nil)); end
  def refute_equal(exp, act, msg = T.unsafe(nil)); end
  def refute_in_delta(exp, act, delta = T.unsafe(nil), msg = T.unsafe(nil)); end
  def refute_in_epsilon(a, b, epsilon = T.unsafe(nil), msg = T.unsafe(nil)); end
  def refute_includes(collection, obj, msg = T.unsafe(nil)); end
  def refute_instance_of(cls, obj, msg = T.unsafe(nil)); end
  def refute_kind_of(cls, obj, msg = T.unsafe(nil)); end
  def refute_match(matcher, obj, msg = T.unsafe(nil)); end
  def refute_nil(obj, msg = T.unsafe(nil)); end
  def refute_operator(o1, op, o2 = T.unsafe(nil), msg = T.unsafe(nil)); end
  def refute_path_exists(path, msg = T.unsafe(nil)); end
  def refute_predicate(o1, op, msg = T.unsafe(nil)); end
  def refute_respond_to(obj, meth, msg = T.unsafe(nil)); end
  def refute_same(exp, act, msg = T.unsafe(nil)); end
  def skip(msg = T.unsafe(nil), bt = T.unsafe(nil)); end
  def skip_until(y, m, d, msg); end
  def skipped?; end
  def things_to_diff(exp, act); end

  class << self
    def diff; end
    def diff=(o); end
  end
end

Minitest::Assertions::E = T.let(T.unsafe(nil), String)

Minitest::Assertions::UNDEFINED = T.let(T.unsafe(nil), Object)

class Minitest::BacktraceFilter
  def filter(bt); end
end

Minitest::BacktraceFilter::MT_RE = T.let(T.unsafe(nil), Regexp)

class Minitest::CompositeReporter < ::Minitest::AbstractReporter
  def initialize(*reporters); end

  def <<(reporter); end
  def io; end
  def passed?; end
  def prerecord(klass, name); end
  def record(result); end
  def report; end
  def reporters; end
  def reporters=(_); end
  def start; end
end

Minitest::ENCS = T.let(T.unsafe(nil), TrueClass)

module Minitest::Guard
  def jruby?(platform = T.unsafe(nil)); end
  def maglev?(platform = T.unsafe(nil)); end
  def mri?(platform = T.unsafe(nil)); end
  def osx?(platform = T.unsafe(nil)); end
  def rubinius?(platform = T.unsafe(nil)); end
  def windows?(platform = T.unsafe(nil)); end
end

module Minitest::Parallel
end

class Minitest::Parallel::Executor
  def initialize(size); end

  def <<(work); end
  def shutdown; end
  def size; end
  def start; end
end

module Minitest::Parallel::Test
  def _synchronize; end
end

module Minitest::Parallel::Test::ClassMethods
  def run_one_method(klass, method_name, reporter); end
  def test_order; end
end

class Minitest::ProgressReporter < ::Minitest::Reporter
  def prerecord(klass, name); end
  def record(result); end
end

module Minitest::Reportable
  def class_name; end
  def error?; end
  def location; end
  def passed?; end
  def result_code; end
  def skipped?; end
end

class Minitest::Reporter < ::Minitest::AbstractReporter
  def initialize(io = T.unsafe(nil), options = T.unsafe(nil)); end

  def io; end
  def io=(_); end
  def options; end
  def options=(_); end
end

class Minitest::Result < ::Minitest::Runnable
  include(::Minitest::Reportable)

  def class_name; end
  def klass; end
  def klass=(_); end
  def source_location; end
  def source_location=(_); end
  def to_s; end

  class << self
    def from(runnable); end
  end
end

class Minitest::Runnable
  def initialize(name); end

  def assertions; end
  def assertions=(_); end
  def failure; end
  def failures; end
  def failures=(_); end
  def marshal_dump; end
  def marshal_load(ary); end
  def name; end
  def name=(o); end
  def passed?; end
  def result_code; end
  def run; end
  def skipped?; end
  def time; end
  def time=(_); end
  def time_it; end

  class << self
    def inherited(klass); end
    def methods_matching(re); end
    def on_signal(name, action); end
    def reset; end
    def run(reporter, options = T.unsafe(nil)); end
    def run_one_method(klass, method_name, reporter); end
    def runnable_methods; end
    def runnables; end
    def with_info_handler(reporter, &block); end
  end
end

Minitest::Runnable::SIGNALS = T.let(T.unsafe(nil), Hash)

class Minitest::Skip < ::Minitest::Assertion
  def result_label; end
end

class Minitest::StatisticsReporter < ::Minitest::Reporter
  def initialize(io = T.unsafe(nil), options = T.unsafe(nil)); end

  def assertions; end
  def assertions=(_); end
  def count; end
  def count=(_); end
  def errors; end
  def errors=(_); end
  def failures; end
  def failures=(_); end
  def passed?; end
  def record(result); end
  def report; end
  def results; end
  def results=(_); end
  def skips; end
  def skips=(_); end
  def start; end
  def start_time; end
  def start_time=(_); end
  def total_time; end
  def total_time=(_); end
end

class Minitest::SummaryReporter < ::Minitest::StatisticsReporter
  def aggregated_results(io); end
  def old_sync; end
  def old_sync=(_); end
  def report; end
  def start; end
  def statistics; end
  def summary; end
  def sync; end
  def sync=(_); end
  def to_s; end

  private

  def binary_string; end
end

class Minitest::Test < ::Minitest::Runnable
  include(::Minitest::Assertions)
  include(::Minitest::Reportable)
  include(::Minitest::Test::LifecycleHooks)
  include(::Minitest::Guard)
  extend(::Minitest::Guard)

  def capture_exceptions; end
  def class_name; end
  def run; end
  def sanitize_exception(e); end
  def with_info_handler(&block); end

  class << self
    def i_suck_and_my_tests_are_order_dependent!; end
    def io_lock; end
    def io_lock=(_); end
    def make_my_diffs_pretty!; end
    def parallelize_me!; end
    def runnable_methods; end
    def test_order; end
  end
end

module Minitest::Test::LifecycleHooks
  def after_setup; end
  def after_teardown; end
  def before_setup; end
  def before_teardown; end
  def setup; end
  def teardown; end
end

Minitest::Test::PASSTHROUGH_EXCEPTIONS = T.let(T.unsafe(nil), Array)

Minitest::Test::TEARDOWN_METHODS = T.let(T.unsafe(nil), Array)

class Minitest::UnexpectedError < ::Minitest::Assertion
  def initialize(error); end

  def backtrace; end
  def error; end
  def error=(_); end
  def message; end
  def result_label; end
end

class Minitest::Unit
  class << self
    def after_tests(&b); end
    def autorun; end
  end
end

class Minitest::Unit::TestCase < ::Minitest::Test
  class << self
    def inherited(klass); end
  end
end

Minitest::Unit::VERSION = T.let(T.unsafe(nil), String)

Minitest::VERSION = T.let(T.unsafe(nil), String)
