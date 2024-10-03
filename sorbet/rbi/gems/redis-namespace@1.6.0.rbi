# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `redis-namespace` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

class Redis
  include(::MonitorMixin)

  def initialize(options = T.unsafe(nil)); end

  def _bpop(cmd, args, &blk); end
  def _client; end
  def _eval(cmd, args); end
  def _exists(*keys); end
  def _scan(command, cursor, args, match: T.unsafe(nil), count: T.unsafe(nil), type: T.unsafe(nil), &block); end
  def append(key, value); end
  def asking; end
  def auth(*args); end
  def bgrewriteaof; end
  def bgsave; end
  def bitcount(key, start = T.unsafe(nil), stop = T.unsafe(nil)); end
  def bitop(operation, destkey, *keys); end
  def bitpos(key, bit, start = T.unsafe(nil), stop = T.unsafe(nil)); end
  def blpop(*args); end
  def brpop(*args); end
  def brpoplpush(source, destination, deprecated_timeout = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def bzpopmax(*args); end
  def bzpopmin(*args); end
  def call(*command); end
  def client(subcommand = T.unsafe(nil), *args); end
  def close; end
  def cluster(subcommand, *args); end
  def commit; end
  def config(action, *args); end
  def connected?; end
  def connection; end
  def dbsize; end
  def debug(*args); end
  def decr(key); end
  def decrby(key, decrement); end
  def del(*keys); end
  def discard; end
  def disconnect!; end
  def dump(key); end
  def dup; end
  def echo(value); end
  def eval(*args); end
  def evalsha(*args); end
  def exec; end
  def exists(*keys); end
  def exists?(*keys); end
  def expire(key, seconds); end
  def expireat(key, unix_time); end
  def flushall(options = T.unsafe(nil)); end
  def flushdb(options = T.unsafe(nil)); end
  def geoadd(key, *member); end
  def geodist(key, member1, member2, unit = T.unsafe(nil)); end
  def geohash(key, member); end
  def geopos(key, member); end
  def georadius(*args, **geoptions); end
  def georadiusbymember(*args, **geoptions); end
  def get(key); end
  def getbit(key, offset); end
  def getrange(key, start, stop); end
  def getset(key, value); end
  def hdel(key, *fields); end
  def hexists(key, field); end
  def hget(key, field); end
  def hgetall(key); end
  def hincrby(key, field, increment); end
  def hincrbyfloat(key, field, increment); end
  def hkeys(key); end
  def hlen(key); end
  def hmget(key, *fields, &blk); end
  def hmset(key, *attrs); end
  def hscan(key, cursor, **options); end
  def hscan_each(key, **options, &block); end
  def hset(key, *attrs); end
  def hsetnx(key, field, value); end
  def hvals(key); end
  def id; end
  def incr(key); end
  def incrby(key, increment); end
  def incrbyfloat(key, increment); end
  def info(cmd = T.unsafe(nil)); end
  def inspect; end
  def keys(pattern = T.unsafe(nil)); end
  def lastsave; end
  def lindex(key, index); end
  def linsert(key, where, pivot, value); end
  def llen(key); end
  def lpop(key, count = T.unsafe(nil)); end
  def lpush(key, value); end
  def lpushx(key, value); end
  def lrange(key, start, stop); end
  def lrem(key, count, value); end
  def lset(key, index, value); end
  def ltrim(key, start, stop); end
  def mapped_hmget(key, *fields); end
  def mapped_hmset(key, hash); end
  def mapped_mget(*keys); end
  def mapped_mset(hash); end
  def mapped_msetnx(hash); end
  def method_missing(command, *args); end
  def mget(*keys, &blk); end
  def migrate(key, options); end
  def monitor(&block); end
  def move(key, db); end
  def mset(*args); end
  def msetnx(*args); end
  def multi; end
  def object(*args); end
  def persist(key); end
  def pexpire(key, milliseconds); end
  def pexpireat(key, ms_unix_time); end
  def pfadd(key, member); end
  def pfcount(*keys); end
  def pfmerge(dest_key, *source_key); end
  def ping(message = T.unsafe(nil)); end
  def pipelined; end
  def psetex(key, ttl, value); end
  def psubscribe(*channels, &block); end
  def psubscribe_with_timeout(timeout, *channels, &block); end
  def pttl(key); end
  def publish(channel, message); end
  def pubsub(subcommand, *args); end
  def punsubscribe(*channels); end
  def queue(*command); end
  def quit; end
  def randomkey; end
  def rename(old_name, new_name); end
  def renamenx(old_name, new_name); end
  def restore(key, ttl, serialized_value, replace: T.unsafe(nil)); end
  def rpop(key, count = T.unsafe(nil)); end
  def rpoplpush(source, destination); end
  def rpush(key, value); end
  def rpushx(key, value); end
  def sadd(key, member); end
  def save; end
  def scan(cursor, **options); end
  def scan_each(**options, &block); end
  def scard(key); end
  def script(subcommand, *args); end
  def sdiff(*keys); end
  def sdiffstore(destination, *keys); end
  def select(db); end
  def sentinel(subcommand, *args); end
  def set(key, value, ex: T.unsafe(nil), px: T.unsafe(nil), nx: T.unsafe(nil), xx: T.unsafe(nil), keepttl: T.unsafe(nil)); end
  def setbit(key, offset, value); end
  def setex(key, ttl, value); end
  def setnx(key, value); end
  def setrange(key, offset, value); end
  def shutdown; end
  def sinter(*keys); end
  def sinterstore(destination, *keys); end
  def sismember(key, member); end
  def slaveof(host, port); end
  def slowlog(subcommand, length = T.unsafe(nil)); end
  def smembers(key); end
  def smove(source, destination, member); end
  def sort(key, by: T.unsafe(nil), limit: T.unsafe(nil), get: T.unsafe(nil), order: T.unsafe(nil), store: T.unsafe(nil)); end
  def spop(key, count = T.unsafe(nil)); end
  def srandmember(key, count = T.unsafe(nil)); end
  def srem(key, member); end
  def sscan(key, cursor, **options); end
  def sscan_each(key, **options, &block); end
  def strlen(key); end
  def subscribe(*channels, &block); end
  def subscribe_with_timeout(timeout, *channels, &block); end
  def subscribed?; end
  def sunion(*keys); end
  def sunionstore(destination, *keys); end
  def sync; end
  def synchronize; end
  def time; end
  def ttl(key); end
  def type(key); end
  def unlink(*keys); end
  def unsubscribe(*channels); end
  def unwatch; end
  def watch(*keys); end
  def with_reconnect(val = T.unsafe(nil), &blk); end
  def without_reconnect(&blk); end
  def xack(key, group, *ids); end
  def xadd(key, entry, approximate: T.unsafe(nil), maxlen: T.unsafe(nil), id: T.unsafe(nil)); end
  def xautoclaim(key, group, consumer, min_idle_time, start, count: T.unsafe(nil), justid: T.unsafe(nil)); end
  def xclaim(key, group, consumer, min_idle_time, *ids, **opts); end
  def xdel(key, *ids); end
  def xgroup(subcommand, key, group, id_or_consumer = T.unsafe(nil), mkstream: T.unsafe(nil)); end
  def xinfo(subcommand, key, group = T.unsafe(nil)); end
  def xlen(key); end
  def xpending(key, group, *args); end
  def xrange(key, start = T.unsafe(nil), range_end = T.unsafe(nil), count: T.unsafe(nil)); end
  def xread(keys, ids, count: T.unsafe(nil), block: T.unsafe(nil)); end
  def xreadgroup(group, consumer, keys, ids, count: T.unsafe(nil), block: T.unsafe(nil), noack: T.unsafe(nil)); end
  def xrevrange(key, range_end = T.unsafe(nil), start = T.unsafe(nil), count: T.unsafe(nil)); end
  def xtrim(key, maxlen, approximate: T.unsafe(nil)); end
  def zadd(key, *args, nx: T.unsafe(nil), xx: T.unsafe(nil), ch: T.unsafe(nil), incr: T.unsafe(nil)); end
  def zcard(key); end
  def zcount(key, min, max); end
  def zincrby(key, increment, member); end
  def zinter(*keys, weights: T.unsafe(nil), aggregate: T.unsafe(nil), with_scores: T.unsafe(nil)); end
  def zinterstore(destination, keys, weights: T.unsafe(nil), aggregate: T.unsafe(nil)); end
  def zlexcount(key, min, max); end
  def zpopmax(key, count = T.unsafe(nil)); end
  def zpopmin(key, count = T.unsafe(nil)); end
  def zrange(key, start, stop, withscores: T.unsafe(nil), with_scores: T.unsafe(nil)); end
  def zrangebylex(key, min, max, limit: T.unsafe(nil)); end
  def zrangebyscore(key, min, max, withscores: T.unsafe(nil), with_scores: T.unsafe(nil), limit: T.unsafe(nil)); end
  def zrank(key, member); end
  def zrem(key, member); end
  def zremrangebyrank(key, start, stop); end
  def zremrangebyscore(key, min, max); end
  def zrevrange(key, start, stop, withscores: T.unsafe(nil), with_scores: T.unsafe(nil)); end
  def zrevrangebylex(key, max, min, limit: T.unsafe(nil)); end
  def zrevrangebyscore(key, max, min, withscores: T.unsafe(nil), with_scores: T.unsafe(nil), limit: T.unsafe(nil)); end
  def zrevrank(key, member); end
  def zscan(key, cursor, **options); end
  def zscan_each(key, **options, &block); end
  def zscore(key, member); end
  def zunionstore(destination, keys, weights: T.unsafe(nil), aggregate: T.unsafe(nil)); end

  private

  def _geoarguments(*args, options: T.unsafe(nil), sort: T.unsafe(nil), count: T.unsafe(nil)); end
  def _subscription(method, timeout, channels, block); end
  def _xread(args, keys, ids, blocking_timeout_msec); end

  class << self
    def current; end
    def current=(_); end
    def exists_returns_integer; end
    def exists_returns_integer=(value); end
  end
end

Redis::Boolify = T.let(T.unsafe(nil), Proc)

Redis::BoolifySet = T.let(T.unsafe(nil), Proc)

Redis::Floatify = T.let(T.unsafe(nil), Proc)

Redis::FloatifyPairs = T.let(T.unsafe(nil), Proc)

Redis::Hashify = T.let(T.unsafe(nil), Proc)

Redis::HashifyClusterNodeInfo = T.let(T.unsafe(nil), Proc)

Redis::HashifyClusterNodes = T.let(T.unsafe(nil), Proc)

Redis::HashifyClusterSlaves = T.let(T.unsafe(nil), Proc)

Redis::HashifyClusterSlots = T.let(T.unsafe(nil), Proc)

Redis::HashifyInfo = T.let(T.unsafe(nil), Proc)

Redis::HashifyStreamAutoclaim = T.let(T.unsafe(nil), Proc)

Redis::HashifyStreamAutoclaimJustId = T.let(T.unsafe(nil), Proc)

Redis::HashifyStreamEntries = T.let(T.unsafe(nil), Proc)

Redis::HashifyStreamPendingDetails = T.let(T.unsafe(nil), Proc)

Redis::HashifyStreamPendings = T.let(T.unsafe(nil), Proc)

Redis::HashifyStreams = T.let(T.unsafe(nil), Proc)

class Redis::Namespace
  def initialize(namespace, options = T.unsafe(nil)); end

  def _client; end
  def call_with_namespace(command, *args, &block); end
  def client; end
  def deprecations?; end
  def eval(*args); end
  def exec; end
  def inspect; end
  def keys(query = T.unsafe(nil)); end
  def method_missing(command, *args, &block); end
  def multi(&block); end
  def namespace(desired_namespace = T.unsafe(nil)); end
  def namespace=(_); end
  def pipelined(&block); end
  def redis; end
  def respond_to?(command, include_private = T.unsafe(nil)); end
  def self_respond_to?(*_); end
  def type(key); end
  def warning; end
  def warning=(_); end
  def warning?; end

  private

  def add_namespace(key); end
  def call_site; end
  def clone_args(arg); end
  def create_enumerator(&block); end
  def namespaced_block(command, &block); end
  def rem_namespace(key); end
  def respond_to_missing?(command, include_all = T.unsafe(nil)); end
end

Redis::Namespace::ADMINISTRATIVE_COMMANDS = T.let(T.unsafe(nil), Hash)

Redis::Namespace::COMMANDS = T.let(T.unsafe(nil), Hash)

Redis::Namespace::DEPRECATED_COMMANDS = T.let(T.unsafe(nil), Hash)

Redis::Namespace::HELPER_COMMANDS = T.let(T.unsafe(nil), Hash)

Redis::Namespace::NAMESPACED_COMMANDS = T.let(T.unsafe(nil), Hash)

Redis::Namespace::TRANSACTION_COMMANDS = T.let(T.unsafe(nil), Hash)

Redis::Namespace::VERSION = T.let(T.unsafe(nil), String)

Redis::Noop = T.let(T.unsafe(nil), Proc)

Redis::VERSION = T.let(T.unsafe(nil), String)
