# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `thread_safe` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

class SynchronizedDelegator < ::SimpleDelegator
  def initialize(obj); end

  def method_missing(method, *args, &block); end
  def setup; end
  def teardown; end
end

module ThreadSafe
end

ThreadSafe::Array = Array

class ThreadSafe::AtomicReferenceCacheBackend
  extend(::ThreadSafe::Util::Volatile)

  def initialize(options = T.unsafe(nil)); end

  def [](key); end
  def []=(key, value); end
  def clear; end
  def compute(key); end
  def compute_if_absent(key); end
  def compute_if_present(key); end
  def delete(key); end
  def delete_pair(key, value); end
  def each_pair; end
  def empty?; end
  def get_and_set(key, value); end
  def get_or_default(key, else_value = T.unsafe(nil)); end
  def key?(key); end
  def merge_pair(key, value); end
  def replace_if_exists(key, new_value); end
  def replace_pair(key, old_value, new_value); end
  def size; end

  private

  def attempt_compute(key, hash, current_table, i, node, node_hash); end
  def attempt_get_and_set(key, value, hash, current_table, i, node, node_hash); end
  def attempt_internal_compute_if_absent(key, hash, current_table, i, node, node_hash); end
  def attempt_internal_replace(key, expected_old_value, hash, current_table, i, node, node_hash); end
  def check_for_resize; end
  def decrement_size(by = T.unsafe(nil)); end
  def find_value_in_node_list(node, key, hash, pure_hash); end
  def increment_size; end
  def initialize_copy(other); end
  def initialize_table; end
  def internal_compute(key, &block); end
  def internal_replace(key, expected_old_value = T.unsafe(nil), &block); end
  def key_hash(key); end
  def lock_and_clean_up_reverse_forwarders(old_table, old_table_size, new_table, i, forwarder); end
  def rebuild(table); end
  def split_bin(new_table, i, node, node_hash); end
  def split_old_bin(table, new_table, i, node, node_hash, forwarder); end
  def table_size_for(entry_count); end
  def try_await_lock(current_table, i, node); end
  def try_in_resize_lock(current_table, size_ctrl); end
end

ThreadSafe::AtomicReferenceCacheBackend::DEFAULT_CAPACITY = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::HASH_BITS = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::LOCKED = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::MAX_CAPACITY = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::MOVED = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::NOW_RESIZING = T.let(T.unsafe(nil), Fixnum)

class ThreadSafe::AtomicReferenceCacheBackend::Node
  include(::ThreadSafe::Util::CheapLockable)
  extend(::ThreadSafe::Util::Volatile)

  def initialize(hash, key, value, next_node = T.unsafe(nil)); end

  def key; end
  def key?(key); end
  def locked?; end
  def matches?(key, hash); end
  def pure_hash; end
  def try_await_lock(table, i); end
  def try_lock_via_hash(node_hash = T.unsafe(nil)); end
  def unlock_via_hash(locked_hash, node_hash); end

  private

  def force_aquire_lock(table, i); end

  class << self
    def locked_hash?(hash); end
  end
end

ThreadSafe::AtomicReferenceCacheBackend::Node::HASH_BITS = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::Node::LOCKED = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::Node::MOVED = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::Node::SPIN_LOCK_ATTEMPTS = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::Node::WAITING = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::AtomicReferenceCacheBackend::TRANSFER_BUFFER_SIZE = T.let(T.unsafe(nil), Fixnum)

class ThreadSafe::AtomicReferenceCacheBackend::Table < ::ThreadSafe::Util::PowerOfTwoTuple
  def cas_new_node(i, hash, key, value); end
  def delete_node_at(i, node, predecessor_node); end
  def try_lock_via_hash(i, node, node_hash); end
  def try_to_cas_in_computed(i, hash, key); end
end

ThreadSafe::AtomicReferenceCacheBackend::WAITING = T.let(T.unsafe(nil), Fixnum)

class ThreadSafe::Cache < ::ThreadSafe::MriCacheBackend
  def initialize(options = T.unsafe(nil), &block); end

  def [](key); end
  def each_key; end
  def each_value; end
  def empty?; end
  def fetch(key, default_value = T.unsafe(nil)); end
  def fetch_or_store(key, default_value = T.unsafe(nil)); end
  def get(key); end
  def key(value); end
  def keys; end
  def marshal_dump; end
  def marshal_load(hash); end
  def put(key, value); end
  def put_if_absent(key, value); end
  def values; end

  private

  def initialize_copy(other); end
  def populate_from(hash); end
  def raise_fetch_no_key; end
  def validate_options_hash!(options); end
end

ThreadSafe::ConcurrentCacheBackend = ThreadSafe::MriCacheBackend

ThreadSafe::Hash = Hash

class ThreadSafe::MriCacheBackend < ::ThreadSafe::NonConcurrentCacheBackend
  def []=(key, value); end
  def clear; end
  def compute(key); end
  def compute_if_absent(key); end
  def compute_if_present(key); end
  def delete(key); end
  def delete_pair(key, value); end
  def get_and_set(key, value); end
  def merge_pair(key, value); end
  def replace_if_exists(key, new_value); end
  def replace_pair(key, old_value, new_value); end
end

ThreadSafe::MriCacheBackend::WRITE_LOCK = T.let(T.unsafe(nil), Thread::Mutex)

ThreadSafe::NULL = T.let(T.unsafe(nil), Object)

class ThreadSafe::NonConcurrentCacheBackend
  def initialize(options = T.unsafe(nil)); end

  def [](key); end
  def []=(key, value); end
  def clear; end
  def compute(key); end
  def compute_if_absent(key); end
  def compute_if_present(key); end
  def delete(key); end
  def delete_pair(key, value); end
  def each_pair; end
  def get_and_set(key, value); end
  def get_or_default(key, default_value); end
  def key?(key); end
  def merge_pair(key, value); end
  def replace_if_exists(key, new_value); end
  def replace_pair(key, old_value, new_value); end
  def size; end
  def value?(value); end

  private

  def _get(key); end
  def _set(key, value); end
  def dupped_backend; end
  def initialize_copy(other); end
  def pair?(key, expected_value); end
  def store_computed_value(key, new_value); end
end

class ThreadSafe::SynchronizedCacheBackend < ::ThreadSafe::NonConcurrentCacheBackend
  include(::Mutex_m)

  def [](key); end
  def []=(key, value); end
  def clear; end
  def compute(key); end
  def compute_if_absent(key); end
  def compute_if_present(key); end
  def delete(key); end
  def delete_pair(key, value); end
  def get_and_set(key, value); end
  def get_or_default(key, default_value); end
  def key?(key); end
  def lock; end
  def locked?; end
  def merge_pair(key, value); end
  def replace_if_exists(key, new_value); end
  def replace_pair(key, old_value, new_value); end
  def size; end
  def synchronize(&block); end
  def try_lock; end
  def unlock; end
  def value?(value); end

  private

  def dupped_backend; end
end

module ThreadSafe::Util
end

class ThreadSafe::Util::Adder < ::ThreadSafe::Util::Striped64
  def add(x); end
  def decrement; end
  def increment; end
  def reset; end
  def sum; end
end

ThreadSafe::Util::AtomicReference = ThreadSafe::Util::FullLockingAtomicReference

ThreadSafe::Util::CPU_COUNT = T.let(T.unsafe(nil), Fixnum)

module ThreadSafe::Util::CheapLockable
  extend(::ThreadSafe::Util::Volatile)


  private

  def cheap_broadcast; end
  def cheap_synchronize; end
  def cheap_wait; end
end

ThreadSafe::Util::FIXNUM_BIT_SIZE = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::Util::MAX_INT = T.let(T.unsafe(nil), Fixnum)

class ThreadSafe::Util::PowerOfTwoTuple < ::ThreadSafe::Util::VolatileTuple
  def initialize(size); end

  def hash_to_index(hash); end
  def next_in_size_table; end
  def volatile_get_by_hash(hash); end
  def volatile_set_by_hash(hash, value); end
end

class ThreadSafe::Util::Striped64
  extend(::ThreadSafe::Util::Volatile)

  def initialize; end

  def busy?; end
  def retry_update(x, hash_code, was_uncontended); end

  private

  def cas_base_computed; end
  def expand_table_unless_stale(current_cells); end
  def free?; end
  def hash_code; end
  def hash_code=(hash); end
  def internal_reset(initial_value); end
  def try_in_busy; end
  def try_initialize_cells(x, hash); end
  def try_to_install_new_cell(new_cell, hash); end
end

class ThreadSafe::Util::Striped64::Cell < ::ThreadSafe::Util::FullLockingAtomicReference
  def cas(old_value, new_value); end
  def cas_computed; end
  def padding_; end
end

ThreadSafe::Util::Striped64::THREAD_LOCAL_KEY = T.let(T.unsafe(nil), Symbol)

module ThreadSafe::Util::Volatile
  def attr_volatile(*attr_names); end
end

class ThreadSafe::Util::VolatileTuple
  include(::Enumerable)

  def initialize(size); end

  def cas(i, old_value, new_value); end
  def compare_and_set(i, old_value, new_value); end
  def each; end
  def size; end
  def volatile_get(i); end
  def volatile_set(i, value); end
end

ThreadSafe::Util::VolatileTuple::Tuple = Array

module ThreadSafe::Util::XorShiftRandom
  extend(::ThreadSafe::Util::XorShiftRandom)

  def get; end
  def xorshift(x); end
end

ThreadSafe::Util::XorShiftRandom::MAX_XOR_SHIFTABLE_INT = T.let(T.unsafe(nil), Fixnum)

ThreadSafe::VERSION = T.let(T.unsafe(nil), String)

class ThreadSafe::Util::FullLockingAtomicReference
  def initialize(value = T.unsafe(nil)); end

  def compare_and_set(old_value, new_value); end
  def get; end
  def set(new_value); end
  def value; end
  def value=(new_value); end
end

module Threadsafe
  class << self
    def const_missing(name); end
  end
end
