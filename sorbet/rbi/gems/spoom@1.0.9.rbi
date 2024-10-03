# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `spoom` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Spoom
  class << self
    sig { params(cmd: String, path: String, capture_err: T::Boolean, arg: String).returns([String, T::Boolean]) }
    def exec(cmd, *arg, path: T.unsafe(nil), capture_err: T.unsafe(nil)); end
  end
end

module Spoom::Cli
end

class Spoom::Cli::Bump < ::Thor
  include(::Spoom::Cli::Helper)

  sig { params(directory: String).void }
  def bump(directory = T.unsafe(nil)); end
  def config_files(path: T.unsafe(nil)); end
  def help(command = T.unsafe(nil), subcommand = T.unsafe(nil)); end
  def print_changes(files, command:, from: T.unsafe(nil), to: T.unsafe(nil), dry: T.unsafe(nil), path: T.unsafe(nil)); end
  def undo_changes(files, from_strictness); end
end

class Spoom::Cli::Config < ::Thor
  include(::Spoom::Cli::Helper)

  def help(command = T.unsafe(nil), subcommand = T.unsafe(nil)); end
  def show; end
end

class Spoom::Cli::Coverage < ::Thor
  include(::Spoom::Cli::Helper)

  def bundle_install(path, sha); end
  def help(command = T.unsafe(nil), subcommand = T.unsafe(nil)); end
  def message_no_data(file); end
  def open(file = T.unsafe(nil)); end
  def parse_time(string, option); end
  def report; end
  def snapshot; end
  def timeline; end
end

Spoom::Cli::Coverage::DATA_DIR = T.let(T.unsafe(nil), String)

module Spoom::Cli::Helper
  include(::Thor::Shell)

  sig { params(string: String).returns(String) }
  def blue(string); end
  sig { returns(T::Boolean) }
  def color?; end
  sig { params(string: String, color: Symbol).returns(String) }
  def colorize(string, color); end
  sig { returns(String) }
  def exec_path; end
  sig { params(string: String).returns(String) }
  def gray(string); end
  sig { params(string: String).returns(String) }
  def green(string); end
  sig { params(string: String).returns(String) }
  def highlight(string); end
  sig { void }
  def in_sorbet_project!; end
  sig { returns(T::Boolean) }
  def in_sorbet_project?; end
  sig { params(string: String).returns(String) }
  def red(string); end
  sig { params(message: String).void }
  def say(message); end
  sig { params(message: String, status: T.nilable(String), nl: T::Boolean).void }
  def say_error(message, status: T.unsafe(nil), nl: T.unsafe(nil)); end
  sig { returns(Spoom::Sorbet::Config) }
  def sorbet_config; end
  sig { returns(String) }
  def sorbet_config_file; end
  sig { params(string: String).returns(String) }
  def yellow(string); end
end

Spoom::Cli::Helper::HIGHLIGHT_COLOR = T.let(T.unsafe(nil), Symbol)

class Spoom::Cli::LSP < ::Thor
  include(::Spoom::Cli::Helper)

  def defs(file, line, col); end
  def find(query); end
  def help(command = T.unsafe(nil), subcommand = T.unsafe(nil)); end
  def hover(file, line, col); end
  def list; end
  def lsp_client; end
  def refs(file, line, col); end
  def run(&block); end
  def show; end
  def sigs(file, line, col); end
  def symbol_printer; end
  def symbols(file); end
  def to_uri(path); end
  def types(file, line, col); end
end

class Spoom::Cli::Main < ::Thor
  include(::Spoom::Cli::Helper)

  def __print_version; end
  def bump(*args); end
  def config(*args); end
  def coverage(*args); end
  def files; end
  def lsp(*args); end
  def tc(*args); end

  class << self
    def exit_on_failure?; end
  end
end

class Spoom::Cli::Run < ::Thor
  include(::Spoom::Cli::Helper)

  def colorize_message(message); end
  def format_error(error, format); end
  def help(command = T.unsafe(nil), subcommand = T.unsafe(nil)); end
  def tc(*arg); end
end

Spoom::Cli::Run::DEFAULT_FORMAT = T.let(T.unsafe(nil), String)

Spoom::Cli::Run::SORT_CODE = T.let(T.unsafe(nil), String)

Spoom::Cli::Run::SORT_ENUM = T.let(T.unsafe(nil), Array)

Spoom::Cli::Run::SORT_LOC = T.let(T.unsafe(nil), String)

module Spoom::Coverage
  class << self
    sig { params(snapshots: T::Array[Spoom::Coverage::Snapshot], palette: Spoom::Coverage::D3::ColorPalette, path: String).returns(Spoom::Coverage::Report) }
    def report(snapshots, palette:, path: T.unsafe(nil)); end
    sig { params(path: String).returns(Spoom::FileTree) }
    def sigils_tree(path: T.unsafe(nil)); end
    sig { params(path: String, rbi: T::Boolean, sorbet_bin: T.nilable(String)).returns(Spoom::Coverage::Snapshot) }
    def snapshot(path: T.unsafe(nil), rbi: T.unsafe(nil), sorbet_bin: T.unsafe(nil)); end
    sig { params(path: String).returns(Spoom::Sorbet::Config) }
    def sorbet_config(path: T.unsafe(nil)); end
  end
end

module Spoom::Coverage::Cards
end

class Spoom::Coverage::Cards::Card < ::Spoom::Coverage::Template
  sig { params(template: String, title: T.nilable(String), body: T.nilable(String)).void }
  def initialize(template: T.unsafe(nil), title: T.unsafe(nil), body: T.unsafe(nil)); end

  def body; end
  sig { returns(T.nilable(String)) }
  def title; end
end

Spoom::Coverage::Cards::Card::TEMPLATE = T.let(T.unsafe(nil), String)

class Spoom::Coverage::Cards::Erb < ::Spoom::Coverage::Cards::Card
  abstract!

  sig { void }
  def initialize; end

  sig { abstract.returns(String) }
  def erb; end
  sig { override.returns(String) }
  def html; end
end

class Spoom::Coverage::Cards::Map < ::Spoom::Coverage::Cards::Card
  sig { params(sigils_tree: Spoom::FileTree, title: String).void }
  def initialize(sigils_tree:, title: T.unsafe(nil)); end
end

class Spoom::Coverage::Cards::Snapshot < ::Spoom::Coverage::Cards::Card
  sig { params(snapshot: Spoom::Coverage::Snapshot, title: String).void }
  def initialize(snapshot:, title: T.unsafe(nil)); end

  sig { returns(Spoom::Coverage::D3::Pie::Calls) }
  def pie_calls; end
  sig { returns(Spoom::Coverage::D3::Pie::Sigils) }
  def pie_sigils; end
  sig { returns(Spoom::Coverage::D3::Pie::Sigs) }
  def pie_sigs; end
  sig { returns(Spoom::Coverage::Snapshot) }
  def snapshot; end
end

Spoom::Coverage::Cards::Snapshot::TEMPLATE = T.let(T.unsafe(nil), String)

class Spoom::Coverage::Cards::SorbetIntro < ::Spoom::Coverage::Cards::Erb
  sig { params(sorbet_intro_commit: T.nilable(String), sorbet_intro_date: T.nilable(Time)).void }
  def initialize(sorbet_intro_commit: T.unsafe(nil), sorbet_intro_date: T.unsafe(nil)); end

  sig { override.returns(String) }
  def erb; end
end

class Spoom::Coverage::Cards::Timeline < ::Spoom::Coverage::Cards::Card
  sig { params(title: String, timeline: Spoom::Coverage::D3::Timeline).void }
  def initialize(title:, timeline:); end
end

class Spoom::Coverage::Cards::Timeline::Calls < ::Spoom::Coverage::Cards::Timeline
  sig { params(snapshots: T::Array[Spoom::Coverage::Snapshot], title: String).void }
  def initialize(snapshots:, title: T.unsafe(nil)); end
end

class Spoom::Coverage::Cards::Timeline::Runtimes < ::Spoom::Coverage::Cards::Timeline
  sig { params(snapshots: T::Array[Spoom::Coverage::Snapshot], title: String).void }
  def initialize(snapshots:, title: T.unsafe(nil)); end
end

class Spoom::Coverage::Cards::Timeline::Sigils < ::Spoom::Coverage::Cards::Timeline
  sig { params(snapshots: T::Array[Spoom::Coverage::Snapshot], title: String).void }
  def initialize(snapshots:, title: T.unsafe(nil)); end
end

class Spoom::Coverage::Cards::Timeline::Sigs < ::Spoom::Coverage::Cards::Timeline
  sig { params(snapshots: T::Array[Spoom::Coverage::Snapshot], title: String).void }
  def initialize(snapshots:, title: T.unsafe(nil)); end
end

class Spoom::Coverage::Cards::Timeline::Versions < ::Spoom::Coverage::Cards::Timeline
  sig { params(snapshots: T::Array[Spoom::Coverage::Snapshot], title: String).void }
  def initialize(snapshots:, title: T.unsafe(nil)); end
end

module Spoom::Coverage::D3
  class << self
    sig { params(palette: Spoom::Coverage::D3::ColorPalette).returns(String) }
    def header_script(palette); end
    sig { returns(String) }
    def header_style; end
  end
end

class Spoom::Coverage::D3::Base
  abstract!

  sig { params(id: String, data: T.untyped).void }
  def initialize(id, data); end

  sig { returns(String) }
  def html; end
  sig { returns(String) }
  def id; end
  sig { abstract.returns(String) }
  def script; end
  sig { returns(String) }
  def tooltip; end

  class << self
    sig { returns(String) }
    def header_script; end
    sig { returns(String) }
    def header_style; end
  end
end

Spoom::Coverage::D3::COLOR_FALSE = T.let(T.unsafe(nil), String)

Spoom::Coverage::D3::COLOR_IGNORE = T.let(T.unsafe(nil), String)

Spoom::Coverage::D3::COLOR_STRICT = T.let(T.unsafe(nil), String)

Spoom::Coverage::D3::COLOR_STRONG = T.let(T.unsafe(nil), String)

Spoom::Coverage::D3::COLOR_TRUE = T.let(T.unsafe(nil), String)

class Spoom::Coverage::D3::CircleMap < ::Spoom::Coverage::D3::Base
  sig { override.returns(String) }
  def script; end

  class << self
    sig { returns(String) }
    def header_script; end
    sig { returns(String) }
    def header_style; end
  end
end

class Spoom::Coverage::D3::CircleMap::Sigils < ::Spoom::Coverage::D3::CircleMap
  sig { params(id: String, sigils_tree: Spoom::FileTree).void }
  def initialize(id, sigils_tree); end

  sig { params(node: Spoom::FileTree::Node).returns(Float) }
  def tree_node_score(node); end
  sig { params(node: Spoom::FileTree::Node).returns(T.nilable(String)) }
  def tree_node_strictness(node); end
  sig { params(node: Spoom::FileTree::Node).returns(T::Hash[Symbol, T.untyped]) }
  def tree_node_to_json(node); end
end

class Spoom::Coverage::D3::ColorPalette < ::T::Struct
  prop :ignore, String
  prop :false, String
  prop :true, String
  prop :strict, String
  prop :strong, String

  class << self
    def inherited(s); end
  end
end

class Spoom::Coverage::D3::Pie < ::Spoom::Coverage::D3::Base
  abstract!

  sig { params(id: String, title: String, data: T.untyped).void }
  def initialize(id, title, data); end

  sig { override.returns(String) }
  def script; end

  class << self
    sig { returns(String) }
    def header_script; end
    sig { returns(String) }
    def header_style; end
  end
end

class Spoom::Coverage::D3::Pie::Calls < ::Spoom::Coverage::D3::Pie
  sig { params(id: String, title: String, snapshot: Spoom::Coverage::Snapshot).void }
  def initialize(id, title, snapshot); end

  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Pie::Sigils < ::Spoom::Coverage::D3::Pie
  sig { params(id: String, title: String, snapshot: Spoom::Coverage::Snapshot).void }
  def initialize(id, title, snapshot); end

  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Pie::Sigs < ::Spoom::Coverage::D3::Pie
  sig { params(id: String, title: String, snapshot: Spoom::Coverage::Snapshot).void }
  def initialize(id, title, snapshot); end

  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Timeline < ::Spoom::Coverage::D3::Base
  abstract!

  sig { params(id: String, data: T.untyped, keys: T::Array[String]).void }
  def initialize(id, data, keys); end

  sig { params(y: String, color: String, curve: String).returns(String) }
  def area(y:, color: T.unsafe(nil), curve: T.unsafe(nil)); end
  sig { params(y: String, color: String, curve: String).returns(String) }
  def line(y:, color: T.unsafe(nil), curve: T.unsafe(nil)); end
  sig { abstract.returns(String) }
  def plot; end
  sig { params(y: String).returns(String) }
  def points(y:); end
  sig { override.returns(String) }
  def script; end
  sig { returns(String) }
  def x_scale; end
  sig { returns(String) }
  def x_ticks; end
  sig { params(min: String, max: String, ticks: String).returns(String) }
  def y_scale(min:, max:, ticks:); end
  sig { params(ticks: String, format: String, padding: Integer).returns(String) }
  def y_ticks(ticks:, format:, padding:); end

  class << self
    sig { returns(String) }
    def header_script; end
    sig { returns(String) }
    def header_style; end
  end
end

class Spoom::Coverage::D3::Timeline::Calls < ::Spoom::Coverage::D3::Timeline::Stacked
  sig { params(id: String, snapshots: T::Array[Spoom::Coverage::Snapshot]).void }
  def initialize(id, snapshots); end

  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Timeline::Runtimes < ::Spoom::Coverage::D3::Timeline
  sig { params(id: String, snapshots: T::Array[Spoom::Coverage::Snapshot]).void }
  def initialize(id, snapshots); end

  sig { override.returns(String) }
  def plot; end
  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Timeline::Sigils < ::Spoom::Coverage::D3::Timeline::Stacked
  sig { params(id: String, snapshots: T::Array[Spoom::Coverage::Snapshot]).void }
  def initialize(id, snapshots); end

  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Timeline::Sigs < ::Spoom::Coverage::D3::Timeline::Stacked
  sig { params(id: String, snapshots: T::Array[Spoom::Coverage::Snapshot]).void }
  def initialize(id, snapshots); end

  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::D3::Timeline::Stacked < ::Spoom::Coverage::D3::Timeline
  abstract!

  def initialize(*args, &blk); end

  sig { override.params(y: String, color: String, curve: String).returns(String) }
  def line(y:, color: T.unsafe(nil), curve: T.unsafe(nil)); end
  sig { override.returns(String) }
  def plot; end
  sig { override.returns(String) }
  def script; end
end

class Spoom::Coverage::D3::Timeline::Versions < ::Spoom::Coverage::D3::Timeline
  sig { params(id: String, snapshots: T::Array[Spoom::Coverage::Snapshot]).void }
  def initialize(id, snapshots); end

  sig { override.returns(String) }
  def plot; end
  sig { override.returns(String) }
  def tooltip; end
end

class Spoom::Coverage::Page < ::Spoom::Coverage::Template
  abstract!

  sig { params(title: String, palette: Spoom::Coverage::D3::ColorPalette, template: String).void }
  def initialize(title:, palette:, template: T.unsafe(nil)); end

  sig { returns(String) }
  def body_html; end
  sig { abstract.returns(T::Array[Spoom::Coverage::Cards::Card]) }
  def cards; end
  sig { returns(String) }
  def footer_html; end
  sig { returns(String) }
  def header_html; end
  sig { returns(String) }
  def header_script; end
  sig { returns(String) }
  def header_style; end
  sig { returns(Spoom::Coverage::D3::ColorPalette) }
  def palette; end
  sig { returns(String) }
  def title; end
end

Spoom::Coverage::Page::TEMPLATE = T.let(T.unsafe(nil), String)

class Spoom::Coverage::Report < ::Spoom::Coverage::Page
  sig { params(project_name: String, palette: Spoom::Coverage::D3::ColorPalette, snapshots: T::Array[Spoom::Coverage::Snapshot], sigils_tree: Spoom::FileTree, sorbet_intro_commit: T.nilable(String), sorbet_intro_date: T.nilable(Time)).void }
  def initialize(project_name:, palette:, snapshots:, sigils_tree:, sorbet_intro_commit: T.unsafe(nil), sorbet_intro_date: T.unsafe(nil)); end

  sig { override.returns(T::Array[Spoom::Coverage::Cards::Card]) }
  def cards; end
  sig { override.returns(String) }
  def header_html; end
  sig { returns(String) }
  def project_name; end
  sig { returns(Spoom::FileTree) }
  def sigils_tree; end
  sig { returns(T::Array[Spoom::Coverage::Snapshot]) }
  def snapshots; end
  sig { returns(T.nilable(String)) }
  def sorbet_intro_commit; end
  sig { returns(T.nilable(Time)) }
  def sorbet_intro_date; end
end

class Spoom::Coverage::Snapshot < ::T::Struct
  prop :timestamp, Integer
  prop :version_static, T.nilable(String)
  prop :version_runtime, T.nilable(String)
  prop :duration, Integer
  prop :commit_sha, T.nilable(String)
  prop :commit_timestamp, T.nilable(Integer)
  prop :files, Integer
  prop :modules, Integer
  prop :classes, Integer
  prop :singleton_classes, Integer
  prop :methods_without_sig, Integer
  prop :methods_with_sig, Integer
  prop :calls_untyped, Integer
  prop :calls_typed, Integer
  prop :sigils, T::Hash[String, Integer]

  sig { params(out: T.any(IO, StringIO), colors: T::Boolean, indent_level: Integer).void }
  def print(out: T.unsafe(nil), colors: T.unsafe(nil), indent_level: T.unsafe(nil)); end
  sig { params(arg: T.untyped).returns(String) }
  def to_json(*arg); end

  class << self
    sig { params(json: String).returns(Spoom::Coverage::Snapshot) }
    def from_json(json); end
    sig { params(obj: T::Hash[String, T.untyped]).returns(Spoom::Coverage::Snapshot) }
    def from_obj(obj); end
    def inherited(s); end
  end
end

Spoom::Coverage::Snapshot::STRICTNESSES = T.let(T.unsafe(nil), Array)

class Spoom::Coverage::SnapshotPrinter < ::Spoom::Printer
  sig { params(snapshot: Spoom::Coverage::Snapshot).void }
  def print_snapshot(snapshot); end

  private

  sig { params(value: T.nilable(Integer), total: T.nilable(Integer)).returns(String) }
  def percent(value, total); end
  sig { params(hash: T::Hash[String, Integer], total: Integer).void }
  def print_map(hash, total); end
end

class Spoom::Coverage::Template
  abstract!

  sig { params(template: String).void }
  def initialize(template:); end

  sig { returns(String) }
  def erb; end
  sig { returns(Binding) }
  def get_binding; end
  sig { returns(String) }
  def html; end
end

class Spoom::Error < ::StandardError
end

class Spoom::FileTree
  sig { params(paths: T::Enumerable[String], strip_prefix: T.nilable(String)).void }
  def initialize(paths = T.unsafe(nil), strip_prefix: T.unsafe(nil)); end

  sig { params(path: String).returns(Spoom::FileTree::Node) }
  def add_path(path); end
  sig { params(paths: T::Enumerable[String]).void }
  def add_paths(paths); end
  sig { returns(T::Array[Spoom::FileTree::Node]) }
  def nodes; end
  sig { returns(T::Array[String]) }
  def paths; end
  sig { params(out: T.any(IO, StringIO), show_strictness: T::Boolean, colors: T::Boolean, indent_level: Integer).void }
  def print(out: T.unsafe(nil), show_strictness: T.unsafe(nil), colors: T.unsafe(nil), indent_level: T.unsafe(nil)); end
  sig { returns(T::Array[Spoom::FileTree::Node]) }
  def roots; end
  sig { returns(T.nilable(String)) }
  def strip_prefix; end

  private

  sig { params(node: Spoom::FileTree::Node, collected_nodes: T::Array[Spoom::FileTree::Node]).returns(T::Array[Spoom::FileTree::Node]) }
  def collect_nodes(node, collected_nodes = T.unsafe(nil)); end
end

class Spoom::FileTree::Node < ::T::Struct
  const :parent, T.nilable(Spoom::FileTree::Node)
  const :name, String
  const :children, T::Hash[String, Spoom::FileTree::Node]

  sig { returns(String) }
  def path; end

  class << self
    def inherited(s); end
  end
end

class Spoom::FileTree::TreePrinter < ::Spoom::Printer
  sig { params(tree: Spoom::FileTree, out: T.any(IO, StringIO), show_strictness: T::Boolean, colors: T::Boolean, indent_level: Integer).void }
  def initialize(tree:, out: T.unsafe(nil), show_strictness: T.unsafe(nil), colors: T.unsafe(nil), indent_level: T.unsafe(nil)); end

  sig { params(node: Spoom::FileTree::Node).void }
  def print_node(node); end
  sig { params(nodes: T::Array[Spoom::FileTree::Node]).void }
  def print_nodes(nodes); end
  sig { void }
  def print_tree; end
  sig { returns(Spoom::FileTree) }
  def tree; end

  private

  sig { params(node: Spoom::FileTree::Node).returns(T.nilable(String)) }
  def node_strictness(node); end
  sig { params(strictness: T.nilable(String)).returns(Symbol) }
  def strictness_color(strictness); end
end

module Spoom::Git
  class << self
    sig { params(path: String, arg: String).returns([String, String, T::Boolean]) }
    def checkout(*arg, path: T.unsafe(nil)); end
    sig { params(sha: String, path: String).returns(T.nilable(Time)) }
    def commit_time(sha, path: T.unsafe(nil)); end
    sig { params(sha: String, path: String).returns(T.nilable(Integer)) }
    def commit_timestamp(sha, path: T.unsafe(nil)); end
    sig { params(path: String, arg: String).returns([String, String, T::Boolean]) }
    def diff(*arg, path: T.unsafe(nil)); end
    sig { params(timestamp: String).returns(Time) }
    def epoch_to_time(timestamp); end
    sig { params(command: String, path: String, arg: String).returns([String, String, T::Boolean]) }
    def exec(command, *arg, path: T.unsafe(nil)); end
    sig { params(path: String).returns(T.nilable(String)) }
    def last_commit(path: T.unsafe(nil)); end
    sig { params(path: String, arg: String).returns([String, String, T::Boolean]) }
    def log(*arg, path: T.unsafe(nil)); end
    sig { params(path: String, arg: String).returns([String, String, T::Boolean]) }
    def rev_parse(*arg, path: T.unsafe(nil)); end
    sig { params(path: String, arg: String).returns([String, String, T::Boolean]) }
    def show(*arg, path: T.unsafe(nil)); end
    sig { params(path: String).returns(T.nilable(String)) }
    def sorbet_intro_commit(path: T.unsafe(nil)); end
    sig { params(path: String).returns(T::Boolean) }
    def workdir_clean?(path: T.unsafe(nil)); end
  end
end

module Spoom::LSP
end

class Spoom::LSP::Client
  def initialize(sorbet_bin, *sorbet_args, path: T.unsafe(nil)); end

  def close; end
  def definitions(uri, line, column); end
  def document_symbols(uri); end
  def hover(uri, line, column); end
  def next_id; end
  def open(workspace_path); end
  def read; end
  def read_raw; end
  def references(uri, line, column, include_decl = T.unsafe(nil)); end
  def send(message); end
  def send_raw(json_string); end
  def signatures(uri, line, column); end
  def symbols(query); end
  def type_definitions(uri, line, column); end
end

class Spoom::LSP::Diagnostic < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :range, Spoom::LSP::Range
  const :code, Integer
  const :message, String
  const :informations, Object

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

class Spoom::LSP::DocumentSymbol < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :name, String
  const :detail, T.nilable(String)
  const :kind, Integer
  const :location, T.nilable(Spoom::LSP::Location)
  const :range, T.nilable(Spoom::LSP::Range)
  const :children, T::Array[Spoom::LSP::DocumentSymbol]

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def kind_string; end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

Spoom::LSP::DocumentSymbol::SYMBOL_KINDS = T.let(T.unsafe(nil), Hash)

class Spoom::LSP::Error < ::StandardError
end

class Spoom::LSP::Error::AlreadyOpen < ::Spoom::LSP::Error
end

class Spoom::LSP::Error::BadHeaders < ::Spoom::LSP::Error
end

class Spoom::LSP::Error::Diagnostics < ::Spoom::LSP::Error
  def initialize(uri, diagnostics); end

  def diagnostics; end
  def uri; end

  class << self
    def from_json(json); end
  end
end

class Spoom::LSP::Hover < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :contents, String
  const :range, T.nilable(T::Range[T.untyped])

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

class Spoom::LSP::Location < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :uri, String
  const :range, Spoom::LSP::Range

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

class Spoom::LSP::Message
  def initialize; end

  def as_json; end
  def jsonrpc; end
  def to_json(*args); end
end

class Spoom::LSP::Notification < ::Spoom::LSP::Message
  def initialize(method, params); end

  def method; end
  def params; end
end

class Spoom::LSP::Position < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :line, Integer
  const :char, Integer

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

module Spoom::LSP::PrintableSymbol
  interface!

  sig { abstract.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
end

class Spoom::LSP::Range < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :start, Spoom::LSP::Position
  const :end, Spoom::LSP::Position

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

class Spoom::LSP::Request < ::Spoom::LSP::Message
  def initialize(id, method, params); end

  def id; end
  def method; end
  def params; end
end

class Spoom::LSP::ResponseError < ::Spoom::LSP::Error
  def initialize(code, message, data); end

  def code; end
  def data; end
  def message; end

  class << self
    def from_json(json); end
  end
end

class Spoom::LSP::SignatureHelp < ::T::Struct
  include(::Spoom::LSP::PrintableSymbol)

  const :label, T.nilable(String)
  const :doc, Object
  const :params, T::Array[T.untyped]

  sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
  def accept_printer(printer); end
  def to_s; end

  class << self
    def from_json(json); end
    def inherited(s); end
  end
end

class Spoom::LSP::SymbolPrinter < ::Spoom::Printer
  sig { params(out: T.any(IO, StringIO), colors: T::Boolean, indent_level: Integer, prefix: T.nilable(String)).void }
  def initialize(out: T.unsafe(nil), colors: T.unsafe(nil), indent_level: T.unsafe(nil), prefix: T.unsafe(nil)); end

  sig { params(uri: String).returns(String) }
  def clean_uri(uri); end
  def prefix; end
  def prefix=(_); end
  sig { params(objects: T::Array[Spoom::LSP::PrintableSymbol]).void }
  def print_list(objects); end
  sig { params(object: T.nilable(Spoom::LSP::PrintableSymbol)).void }
  def print_object(object); end
  sig { params(objects: T::Array[Spoom::LSP::PrintableSymbol]).void }
  def print_objects(objects); end
  def seen; end
  def seen=(_); end
end

class Spoom::Printer
  abstract!

  sig { params(out: T.any(IO, StringIO), colors: T::Boolean, indent_level: Integer).void }
  def initialize(out: T.unsafe(nil), colors: T.unsafe(nil), indent_level: T.unsafe(nil)); end

  sig { params(string: String, color: Symbol).returns(String) }
  def colorize(string, color); end
  sig { void }
  def dedent; end
  sig { void }
  def indent; end
  sig { returns(T.any(IO, StringIO)) }
  def out; end
  def out=(_); end
  sig { params(string: T.nilable(String)).void }
  def print(string); end
  sig { params(string: T.nilable(String), color: Symbol, colors: Symbol).void }
  def print_colored(string, color, *colors); end
  sig { params(string: T.nilable(String)).void }
  def printl(string); end
  sig { void }
  def printn; end
  sig { void }
  def printt; end
end

Spoom::SPOOM_PATH = T.let(T.unsafe(nil), String)

module Spoom::Sorbet
  class << self
    sig { params(path: String, capture_err: T::Boolean, sorbet_bin: T.nilable(String), arg: String).returns([String, T::Boolean]) }
    def srb(*arg, path: T.unsafe(nil), capture_err: T.unsafe(nil), sorbet_bin: T.unsafe(nil)); end
    sig { params(config: Spoom::Sorbet::Config, path: String).returns(T::Array[String]) }
    def srb_files(config, path: T.unsafe(nil)); end
    sig { params(path: String, capture_err: T::Boolean, sorbet_bin: T.nilable(String), arg: String).returns(T.nilable(T::Hash[String, Integer])) }
    def srb_metrics(*arg, path: T.unsafe(nil), capture_err: T.unsafe(nil), sorbet_bin: T.unsafe(nil)); end
    sig { params(path: String, capture_err: T::Boolean, sorbet_bin: T.nilable(String), arg: String).returns([String, T::Boolean]) }
    def srb_tc(*arg, path: T.unsafe(nil), capture_err: T.unsafe(nil), sorbet_bin: T.unsafe(nil)); end
    sig { params(path: String, capture_err: T::Boolean, sorbet_bin: T.nilable(String), arg: String).returns(T.nilable(String)) }
    def srb_version(*arg, path: T.unsafe(nil), capture_err: T.unsafe(nil), sorbet_bin: T.unsafe(nil)); end
    sig { params(gem: String, path: String).returns(T.nilable(String)) }
    def version_from_gemfile_lock(gem: T.unsafe(nil), path: T.unsafe(nil)); end
  end
end

Spoom::Sorbet::BIN_PATH = T.let(T.unsafe(nil), String)

Spoom::Sorbet::CONFIG_PATH = T.let(T.unsafe(nil), String)

class Spoom::Sorbet::Config
  sig { void }
  def initialize; end

  def allowed_extensions; end
  sig { returns(Spoom::Sorbet::Config) }
  def copy; end
  def ignore; end
  sig { returns(String) }
  def options_string; end
  sig { returns(T::Array[String]) }
  def paths; end

  class << self
    sig { params(sorbet_config_path: String).returns(Spoom::Sorbet::Config) }
    def parse_file(sorbet_config_path); end
    sig { params(sorbet_config: String).returns(Spoom::Sorbet::Config) }
    def parse_string(sorbet_config); end

    private

    sig { params(line: String).returns(String) }
    def parse_option(line); end
  end
end

module Spoom::Sorbet::Errors
  class << self
    sig { params(errors: T::Array[Spoom::Sorbet::Errors::Error]).returns(T::Array[Spoom::Sorbet::Errors::Error]) }
    def sort_errors_by_code(errors); end
  end
end

class Spoom::Sorbet::Errors::Error
  include(::Comparable)

  sig { params(file: T.nilable(String), line: T.nilable(Integer), message: T.nilable(String), code: T.nilable(Integer), more: T::Array[String]).void }
  def initialize(file, line, message, code, more = T.unsafe(nil)); end

  sig { params(other: T.untyped).returns(Integer) }
  def <=>(other); end
  def code; end
  sig { returns(T.nilable(String)) }
  def file; end
  sig { returns(T.nilable(Integer)) }
  def line; end
  def message; end
  sig { returns(T::Array[String]) }
  def more; end
  sig { returns(String) }
  def to_s; end
end

class Spoom::Sorbet::Errors::Parser
  sig { void }
  def initialize; end

  sig { params(output: String).returns(T::Array[Spoom::Sorbet::Errors::Error]) }
  def parse(output); end

  private

  sig { params(line: String).void }
  def append_error(line); end
  sig { void }
  def close_error; end
  sig { params(line: String).returns(T.nilable(Spoom::Sorbet::Errors::Error)) }
  def match_error_line(line); end
  sig { params(error: Spoom::Sorbet::Errors::Error).void }
  def open_error(error); end

  class << self
    sig { params(output: String).returns(T::Array[Spoom::Sorbet::Errors::Error]) }
    def parse_string(output); end
  end
end

Spoom::Sorbet::Errors::Parser::ERROR_LINE_MATCH_REGEX = T.let(T.unsafe(nil), Regexp)

Spoom::Sorbet::Errors::Parser::HEADER = T.let(T.unsafe(nil), Array)

Spoom::Sorbet::GEM_PATH = T.let(T.unsafe(nil), String)

module Spoom::Sorbet::MetricsParser
  class << self
    sig { params(path: String, prefix: String).returns(T::Hash[String, Integer]) }
    def parse_file(path, prefix = T.unsafe(nil)); end
    sig { params(obj: T::Hash[String, T.untyped], prefix: String).returns(T::Hash[String, Integer]) }
    def parse_hash(obj, prefix = T.unsafe(nil)); end
    sig { params(string: String, prefix: String).returns(T::Hash[String, Integer]) }
    def parse_string(string, prefix = T.unsafe(nil)); end
  end
end

Spoom::Sorbet::MetricsParser::DEFAULT_PREFIX = T.let(T.unsafe(nil), String)

module Spoom::Sorbet::Sigils
  class << self
    sig { params(path: T.any(Pathname, String), new_strictness: String).returns(T::Boolean) }
    def change_sigil_in_file(path, new_strictness); end
    sig { params(path_list: T::Array[String], new_strictness: String).returns(T::Array[String]) }
    def change_sigil_in_files(path_list, new_strictness); end
    sig { params(path: T.any(Pathname, String)).returns(T.nilable(String)) }
    def file_strictness(path); end
    sig { params(directory: T.any(Pathname, String), strictness: String, extension: String).returns(T::Array[String]) }
    def files_with_sigil_strictness(directory, strictness, extension: T.unsafe(nil)); end
    sig { params(strictness: String).returns(String) }
    def sigil_string(strictness); end
    sig { params(content: String).returns(T.nilable(String)) }
    def strictness_in_content(content); end
    sig { params(content: String, new_strictness: String).returns(String) }
    def update_sigil(content, new_strictness); end
    sig { params(strictness: String).returns(T::Boolean) }
    def valid_strictness?(strictness); end
  end
end

Spoom::Sorbet::Sigils::SIGIL_REGEXP = T.let(T.unsafe(nil), Regexp)

Spoom::Sorbet::Sigils::STRICTNESS_FALSE = T.let(T.unsafe(nil), String)

Spoom::Sorbet::Sigils::STRICTNESS_IGNORE = T.let(T.unsafe(nil), String)

Spoom::Sorbet::Sigils::STRICTNESS_INTERNAL = T.let(T.unsafe(nil), String)

Spoom::Sorbet::Sigils::STRICTNESS_STRICT = T.let(T.unsafe(nil), String)

Spoom::Sorbet::Sigils::STRICTNESS_STRONG = T.let(T.unsafe(nil), String)

Spoom::Sorbet::Sigils::STRICTNESS_TRUE = T.let(T.unsafe(nil), String)

Spoom::Sorbet::Sigils::VALID_STRICTNESS = T.let(T.unsafe(nil), Array)

class Spoom::Timeline
  sig { params(from: Time, to: Time, path: String).void }
  def initialize(from, to, path: T.unsafe(nil)); end

  sig { params(dates: T::Array[Time]).returns(T::Array[String]) }
  def commits_for_dates(dates); end
  sig { returns(T::Array[Time]) }
  def months; end
  sig { returns(T::Array[String]) }
  def ticks; end
end

Spoom::VERSION = T.let(T.unsafe(nil), String)
