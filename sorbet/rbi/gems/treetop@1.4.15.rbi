# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `treetop` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

class IntervalSkipList
  def initialize; end

  def containing(n); end
  def delete(marker); end
  def empty?; end
  def expire(range, length_change); end
  def insert(range, marker); end
  def max_height; end
  def overlapping(range); end
  def probability; end

  protected

  def can_ascend_from?(node, level); end
  def can_descend_from?(level); end
  def containing_with_node(n); end
  def delete_node(key); end
  def find(key, path); end
  def head; end
  def insert_node(key); end
  def make_path; end
  def mark_forward_path_at_level(node, level, marker); end
  def next_node_at_level_inside_range?(node, level, range); end
  def next_node_at_level_outside_range?(node, level, range); end
  def next_node_height; end
  def node_inside_range?(node, range); end
  def nodes; end
  def ranges; end
  def unmark_forward_path_at_level(node, level, marker); end
end

class IntervalSkipList::HeadNode
  def initialize(height); end

  def forward; end
  def forward_markers; end
  def height; end
  def top_level; end
end

class IntervalSkipList::Node < ::IntervalSkipList::HeadNode
  def initialize(key, height, path); end

  def all_forward_markers; end
  def delete(path); end
  def endpoint_of; end
  def key; end
  def key=(_); end
  def markers; end
  def propagate_length_change(length_change); end

  protected

  def can_be_promoted_higher?(marker, level); end
  def delete_marker_from_path(marker, level, terminus); end
  def demote_inbound_markers(path); end
  def demote_markers(path); end
  def demote_outbound_markers(path); end
  def forward_node_with_marker_at_or_above_level?(marker, level); end
  def place_marker_on_inbound_path(marker, level, terminus); end
  def place_marker_on_outbound_path(marker, level, terminus); end
  def promote_markers(path); end
  def update_forward_pointers(path); end
end

class String
  include(::Comparable)
  include(::Colorize::InstanceMethods)
  include(::JSON::Ext::Generator::GeneratorMethods::String)
  extend(::Colorize::ClassMethods)
  extend(::JSON::Ext::Generator::GeneratorMethods::String::Extend)

  def column_of(index); end
  def line_of(index); end
  def tabto(n); end
  def treetop_camelize; end
end

String::BLANK_RE = T.let(T.unsafe(nil), Regexp)

module Treetop
  class << self
    def load(path); end
    def load_from_string(s); end
  end
end

module Treetop::Compiler
end

Treetop::Compiler::AUTOGENERATED = T.let(T.unsafe(nil), String)

class Treetop::Compiler::AndPredicate < ::Treetop::Compiler::Predicate
  def when_failure; end
  def when_success; end
end

class Treetop::Compiler::AnythingSymbol < ::Treetop::Compiler::AtomicExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
end

class Treetop::Compiler::AtomicExpression < ::Treetop::Compiler::ParsingExpression
  def inline_modules; end
  def single_quote(string); end
end

class Treetop::Compiler::CharacterClass < ::Treetop::Compiler::AtomicExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def grounded_regexp(string); end
end

class Treetop::Compiler::Choice < ::Treetop::Compiler::ParsingExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def compile_alternatives(alternatives); end
end

class Treetop::Compiler::DeclarationSequence < ::Treetop::Runtime::SyntaxNode
  def compile(builder); end
  def rules; end
end

class Treetop::Compiler::Grammar < ::Treetop::Runtime::SyntaxNode
  def compile; end
  def indent_level; end
  def parser_name; end
end

class Treetop::Compiler::GrammarCompiler
  def compile(source_path, target_path = T.unsafe(nil)); end
  def ruby_source(source_path); end
  def ruby_source_from_string(s); end
end

class Treetop::Compiler::InlineModule < ::Treetop::Runtime::SyntaxNode
  include(::Treetop::Compiler::InlineModuleMixin)

  def compile(index, builder, rule); end
  def ruby_code; end
end

module Treetop::Compiler::InlineModuleMixin
  def compile(index, builder, rule); end
  def module_name; end
end

class Treetop::Compiler::LexicalAddressSpace
  def initialize; end

  def next_address; end
  def reset_addresses; end
end

module Treetop::Compiler::Metagrammar
  include(::Treetop::Runtime)

  def _nt_alpha_char; end
  def _nt_alphanumeric_char; end
  def _nt_alternative; end
  def _nt_anything_symbol; end
  def _nt_atomic; end
  def _nt_bracket_expression; end
  def _nt_character_class; end
  def _nt_choice; end
  def _nt_comment_to_eol; end
  def _nt_declaration; end
  def _nt_declaration_sequence; end
  def _nt_double_quoted_string; end
  def _nt_grammar; end
  def _nt_grammar_name; end
  def _nt_include_declaration; end
  def _nt_inline_module; end
  def _nt_keyword_inside_grammar; end
  def _nt_label; end
  def _nt_labeled_expression_sequence_body; end
  def _nt_labeled_sequence_primary; end
  def _nt_module_declaration; end
  def _nt_module_or_grammar; end
  def _nt_named_label; end
  def _nt_node_class_declarations; end
  def _nt_node_class_expression; end
  def _nt_non_space_char; end
  def _nt_nonterminal; end
  def _nt_null_label; end
  def _nt_occurrence_range; end
  def _nt_optional_suffix; end
  def _nt_optionally_labeled_sequence_primary; end
  def _nt_parenthesized_expression; end
  def _nt_parsing_expression; end
  def _nt_parsing_rule; end
  def _nt_predicate_block; end
  def _nt_prefix; end
  def _nt_primary; end
  def _nt_quoted_string; end
  def _nt_repetition_suffix; end
  def _nt_require_statement; end
  def _nt_sequence; end
  def _nt_sequence_body; end
  def _nt_sequence_primary; end
  def _nt_single_quoted_string; end
  def _nt_space; end
  def _nt_suffix; end
  def _nt_terminal; end
  def _nt_trailing_inline_module; end
  def _nt_treetop_file; end
  def _nt_unlabeled_sequence_primary; end
  def _nt_variable_length_sequence_body; end
  def _nt_white; end
  def root; end
end

module Treetop::Compiler::Metagrammar::BracketExpression0
end

module Treetop::Compiler::Metagrammar::CharacterClass0
end

module Treetop::Compiler::Metagrammar::CharacterClass1
end

module Treetop::Compiler::Metagrammar::CharacterClass2
end

module Treetop::Compiler::Metagrammar::CharacterClass3
  def characters; end
end

module Treetop::Compiler::Metagrammar::CharacterClass4
  def characters; end
end

module Treetop::Compiler::Metagrammar::Choice0
  def alternative; end
end

module Treetop::Compiler::Metagrammar::Choice1
  def head; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::Choice2
  def alternatives; end
  def inline_modules; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::CommentToEol0
end

module Treetop::Compiler::Metagrammar::CommentToEol1
end

module Treetop::Compiler::Metagrammar::DeclarationSequence0
  def declaration; end
  def space; end
end

module Treetop::Compiler::Metagrammar::DeclarationSequence1
  def head; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::DeclarationSequence2
  def declarations; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::DeclarationSequence3
  def compile(builder); end
end

module Treetop::Compiler::Metagrammar::DoubleQuotedString0
end

module Treetop::Compiler::Metagrammar::DoubleQuotedString1
  def string; end
end

module Treetop::Compiler::Metagrammar::Grammar0
  def space; end
end

module Treetop::Compiler::Metagrammar::Grammar1
  def declaration_sequence; end
  def grammar_name; end
  def space1; end
  def space2; end
end

module Treetop::Compiler::Metagrammar::GrammarName0
end

module Treetop::Compiler::Metagrammar::IncludeDeclaration0
  def space; end
end

module Treetop::Compiler::Metagrammar::IncludeDeclaration1
  def compile(builder); end
end

module Treetop::Compiler::Metagrammar::InlineModule0
end

module Treetop::Compiler::Metagrammar::InlineModule1
end

module Treetop::Compiler::Metagrammar::KeywordInsideGrammar0
end

module Treetop::Compiler::Metagrammar::LabeledExpressionSequenceBody0
  def head; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::LabeledSequencePrimary0
  def named_label; end
  def sequence_primary; end
end

module Treetop::Compiler::Metagrammar::LabeledSequencePrimary1
  def compile(lexical_address, builder); end
  def inline_modules; end
  def label_name; end
end

module Treetop::Compiler::Metagrammar::ModuleDeclaration0
end

module Treetop::Compiler::Metagrammar::ModuleDeclaration1
end

module Treetop::Compiler::Metagrammar::ModuleDeclaration2
  def name; end
  def space1; end
  def space2; end
end

module Treetop::Compiler::Metagrammar::ModuleDeclaration3
  def space; end
end

module Treetop::Compiler::Metagrammar::ModuleDeclaration4
  def module_contents; end
  def prefix; end
  def suffix; end
end

module Treetop::Compiler::Metagrammar::ModuleDeclaration5
  def compile; end
  def parser_name; end
end

module Treetop::Compiler::Metagrammar::NamedLabel0
  def alpha_char; end
end

module Treetop::Compiler::Metagrammar::NamedLabel1
end

module Treetop::Compiler::Metagrammar::NamedLabel2
  def name; end
end

module Treetop::Compiler::Metagrammar::NodeClassDeclarations0
  def node_class_expression; end
  def trailing_inline_module; end
end

module Treetop::Compiler::Metagrammar::NodeClassDeclarations1
  def inline_module; end
  def inline_module_name; end
  def inline_modules; end
  def node_class_name; end
end

module Treetop::Compiler::Metagrammar::NodeClassExpression0
end

module Treetop::Compiler::Metagrammar::NodeClassExpression1
  def space; end
end

module Treetop::Compiler::Metagrammar::NodeClassExpression2
  def node_class_name; end
end

module Treetop::Compiler::Metagrammar::NodeClassExpression3
  def node_class_name; end
end

module Treetop::Compiler::Metagrammar::NonSpaceChar0
end

module Treetop::Compiler::Metagrammar::Nonterminal0
  def alpha_char; end
end

module Treetop::Compiler::Metagrammar::Nonterminal1
end

module Treetop::Compiler::Metagrammar::NullLabel0
  def name; end
end

module Treetop::Compiler::Metagrammar::OccurrenceRange0
  def max; end
  def min; end
end

module Treetop::Compiler::Metagrammar::ParenthesizedExpression0
  def parsing_expression; end
end

module Treetop::Compiler::Metagrammar::ParenthesizedExpression1
  def inline_modules; end
end

module Treetop::Compiler::Metagrammar::ParsingRule0
  def space; end
end

module Treetop::Compiler::Metagrammar::ParsingRule1
  def nonterminal; end
  def parsing_expression; end
  def space1; end
  def space2; end
  def space3; end
end

module Treetop::Compiler::Metagrammar::PredicateBlock0
  def inline_module; end
end

module Treetop::Compiler::Metagrammar::Primary0
  def atomic; end
  def prefix; end
end

module Treetop::Compiler::Metagrammar::Primary1
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def inline_module_name; end
  def inline_modules; end
  def prefixed_expression; end
end

module Treetop::Compiler::Metagrammar::Primary2
  def predicate_block; end
  def prefix; end
end

module Treetop::Compiler::Metagrammar::Primary3
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def inline_modules; end
  def prefixed_expression; end
end

module Treetop::Compiler::Metagrammar::Primary4
  def atomic; end
  def node_class_declarations; end
  def suffix; end
end

module Treetop::Compiler::Metagrammar::Primary5
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def inline_module_name; end
  def inline_modules; end
  def node_class_name; end
  def optional_expression; end
end

module Treetop::Compiler::Metagrammar::Primary6
  def atomic; end
  def node_class_declarations; end
end

module Treetop::Compiler::Metagrammar::Primary7
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def inline_module_name; end
  def inline_modules; end
  def node_class_name; end
end

module Treetop::Compiler::Metagrammar::QuotedString0
  def string; end
end

module Treetop::Compiler::Metagrammar::RequireStatement0
  def prefix; end
end

module Treetop::Compiler::Metagrammar::Sequence0
  def node_class_declarations; end
  def sequence_body; end
end

module Treetop::Compiler::Metagrammar::Sequence1
  def inline_module_name; end
  def inline_modules; end
  def sequence_elements; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::SequencePrimary0
  def atomic; end
  def prefix; end
end

module Treetop::Compiler::Metagrammar::SequencePrimary1
  def compile(lexical_address, builder); end
  def inline_module_name; end
  def inline_modules; end
  def prefixed_expression; end
end

module Treetop::Compiler::Metagrammar::SequencePrimary2
  def predicate_block; end
  def prefix; end
end

module Treetop::Compiler::Metagrammar::SequencePrimary3
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def inline_modules; end
  def prefixed_expression; end
end

module Treetop::Compiler::Metagrammar::SequencePrimary4
  def atomic; end
  def suffix; end
end

module Treetop::Compiler::Metagrammar::SequencePrimary5
  def compile(lexical_address, builder); end
  def inline_module_name; end
  def inline_modules; end
  def node_class_name; end
end

module Treetop::Compiler::Metagrammar::SingleQuotedString0
end

module Treetop::Compiler::Metagrammar::SingleQuotedString1
  def string; end
end

module Treetop::Compiler::Metagrammar::TrailingInlineModule0
  def inline_module; end
  def space; end
end

module Treetop::Compiler::Metagrammar::TrailingInlineModule1
  def inline_module_name; end
  def inline_modules; end
end

module Treetop::Compiler::Metagrammar::TrailingInlineModule2
  def inline_module; end
  def inline_module_name; end
  def inline_modules; end
end

module Treetop::Compiler::Metagrammar::TreetopFile0
  def require_statement; end
end

module Treetop::Compiler::Metagrammar::TreetopFile1
  def module_or_grammar; end
  def prefix; end
  def requires; end
  def suffix; end
end

module Treetop::Compiler::Metagrammar::TreetopFile2
  def compile; end
end

module Treetop::Compiler::Metagrammar::UnlabeledSequencePrimary0
  def null_label; end
  def sequence_primary; end
end

module Treetop::Compiler::Metagrammar::UnlabeledSequencePrimary1
  def compile(lexical_address, builder); end
  def inline_modules; end
  def label_name; end
end

module Treetop::Compiler::Metagrammar::VariableLengthSequenceBody0
  def optionally_labeled_sequence_primary; end
  def space; end
end

module Treetop::Compiler::Metagrammar::VariableLengthSequenceBody1
  def head; end
  def tail; end
end

module Treetop::Compiler::Metagrammar::VariableLengthSequenceBody2
  def tail; end
end

class Treetop::Compiler::MetagrammarParser < ::Treetop::Runtime::CompiledParser
  include(::Treetop::Compiler::Metagrammar)
end

class Treetop::Compiler::Nonterminal < ::Treetop::Compiler::AtomicExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
end

class Treetop::Compiler::NotPredicate < ::Treetop::Compiler::Predicate
  def when_failure; end
  def when_success; end
end

class Treetop::Compiler::OccurrenceRange < ::Treetop::Compiler::Repetition
  def compile(address, builder, parent_expression); end
end

class Treetop::Compiler::OneOrMore < ::Treetop::Compiler::Repetition
  def compile(address, builder, parent_expression); end
  def max; end
end

class Treetop::Compiler::Optional < ::Treetop::Compiler::ParsingExpression
  def compile(address, builder, parent_expression); end
end

class Treetop::Compiler::ParenthesizedExpression < ::Treetop::Compiler::ParsingExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
end

class Treetop::Compiler::ParsingExpression < ::Treetop::Runtime::SyntaxNode
  def accumulate_subexpression_result; end
  def accumulator_var; end
  def address; end
  def assign_failure(start_index_var); end
  def assign_lazily_instantiated_node; end
  def assign_result(value_ruby); end
  def begin_comment(expression); end
  def builder; end
  def compile(address, builder, parent_expression); end
  def declared_module_name; end
  def decorated?; end
  def end_comment(expression); end
  def epsilon_node; end
  def extend_result(module_name); end
  def extend_result_with_declared_module; end
  def extend_result_with_inline_module; end
  def init_value(var_symbol); end
  def inline_module_name; end
  def node_class_name; end
  def obtain_new_subexpression_address; end
  def on_one_line(expression); end
  def optional_arg(arg); end
  def parent_expression; end
  def reset_index; end
  def result_var; end
  def start_index_var; end
  def subexpression_address; end
  def subexpression_result_var; end
  def subexpression_success?; end
  def use_vars(*var_symbols); end
  def var(var_symbol); end
  def var_initialization; end
  def var_symbols; end
end

class Treetop::Compiler::ParsingRule < ::Treetop::Runtime::SyntaxNode
  def compile(builder); end
  def compile_inline_module_declarations(builder); end
  def generate_cache_lookup(builder); end
  def generate_cache_storage(builder, result_var); end
  def generate_method_definition(builder); end
  def method_name; end
  def name; end
end

class Treetop::Compiler::Predicate < ::Treetop::Compiler::ParsingExpression
  def assign_failure; end
  def assign_success; end
  def compile(address, builder, parent_expression); end
end

class Treetop::Compiler::PredicateBlock < ::Treetop::Compiler::ParsingExpression
  def compile(index, builder, parent_expression = T.unsafe(nil)); end
end

class Treetop::Compiler::Repetition < ::Treetop::Compiler::ParsingExpression
  def assign_and_extend_result; end
  def compile(address, builder, parent_expression); end
  def inline_module_name; end
end

class Treetop::Compiler::RubyBuilder
  def initialize; end

  def <<(ruby_line); end
  def accumulate(left, right); end
  def address_space; end
  def assign(left, right); end
  def break; end
  def class_declaration(name, &block); end
  def else_(&block); end
  def extend(var, module_name); end
  def if_(condition, &block); end
  def if__(condition, &block); end
  def in(depth = T.unsafe(nil)); end
  def indented(depth = T.unsafe(nil)); end
  def level; end
  def loop(&block); end
  def method_declaration(name, &block); end
  def module_declaration(name, &block); end
  def newline; end
  def next_address; end
  def out(depth = T.unsafe(nil)); end
  def reset_addresses; end
  def ruby; end

  private

  def indent; end
end

class Treetop::Compiler::Sequence < ::Treetop::Compiler::ParsingExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
  def compile_sequence_elements(elements); end
  def node_class_name; end
  def sequence_element_accessor_module; end
  def sequence_element_accessor_module_name; end
end

class Treetop::Compiler::SequenceElementAccessorModule
  include(::Treetop::Compiler::InlineModuleMixin)

  def initialize(sequence_elements); end

  def compile(idx, builder, rule); end
  def sequence_elements; end
end

class Treetop::Compiler::Terminal < ::Treetop::Compiler::AtomicExpression
  def compile(address, builder, parent_expression = T.unsafe(nil)); end
end

class Treetop::Compiler::TransientPrefix < ::Treetop::Compiler::ParsingExpression
  def compile(address, builder, parent_expression); end
end

class Treetop::Compiler::TreetopFile < ::Treetop::Runtime::SyntaxNode
  def compile; end
end

class Treetop::Compiler::ZeroOrMore < ::Treetop::Compiler::Repetition
  def compile(address, builder, parent_expression); end
  def max; end
end

module Treetop::Polyglot
end

Treetop::Polyglot::VALID_GRAMMAR_EXT = T.let(T.unsafe(nil), Array)

Treetop::Polyglot::VALID_GRAMMAR_EXT_REGEXP = T.let(T.unsafe(nil), Regexp)

module Treetop::Runtime
end

class Treetop::Runtime::CompiledParser
  include(::Treetop::Runtime)

  def initialize; end

  def consume_all_input; end
  def consume_all_input=(_); end
  def consume_all_input?; end
  def failure_column; end
  def failure_index; end
  def failure_line; end
  def failure_reason; end
  def index; end
  def input; end
  def max_terminal_failure_index; end
  def parse(input, options = T.unsafe(nil)); end
  def root=(_); end
  def terminal_failures; end

  protected

  def has_terminal?(terminal, regex, index); end
  def index=(_); end
  def input_length; end
  def instantiate_node(node_type, *args); end
  def node_cache; end
  def parse_anything(node_class = T.unsafe(nil), inline_module = T.unsafe(nil)); end
  def prepare_to_parse(input); end
  def reset_index; end
  def terminal_parse_failure(expected_string); end
end

class Treetop::Runtime::SyntaxNode
  def initialize(input, interval, elements = T.unsafe(nil)); end

  def <=>(other); end
  def dot_id; end
  def elements; end
  def empty?; end
  def extension_modules; end
  def input; end
  def inspect(indent = T.unsafe(nil)); end
  def interval; end
  def nonterminal?; end
  def parent; end
  def parent=(_); end
  def terminal?; end
  def text_value; end
  def write_dot(io); end
  def write_dot_file(fname); end
end

class Treetop::Runtime::TerminalParseFailure
  def initialize(index, expected_string); end

  def expected_string; end
  def index; end
  def to_s; end
end