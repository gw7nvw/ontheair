# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rubyzip` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Zip
  extend(::Zip)

  def case_insensitive_match; end
  def case_insensitive_match=(_); end
  def continue_on_exists_proc; end
  def continue_on_exists_proc=(_); end
  def default_compression; end
  def default_compression=(_); end
  def force_entry_names_encoding; end
  def force_entry_names_encoding=(_); end
  def on_exists_proc; end
  def on_exists_proc=(_); end
  def reset!; end
  def setup; end
  def sort_entries; end
  def sort_entries=(_); end
  def unicode_names; end
  def unicode_names=(_); end
  def validate_entry_sizes; end
  def validate_entry_sizes=(_); end
  def warn_invalid_date; end
  def warn_invalid_date=(_); end
  def write_zip64_support; end
  def write_zip64_support=(_); end
end

Zip::CDIR_ENTRY_STATIC_HEADER_LENGTH = T.let(T.unsafe(nil), Fixnum)

Zip::CENTRAL_DIRECTORY_ENTRY_SIGNATURE = T.let(T.unsafe(nil), Fixnum)

class Zip::CentralDirectory
  include(::Enumerable)

  def initialize(entries = T.unsafe(nil), comment = T.unsafe(nil)); end

  def ==(other); end
  def comment; end
  def each(&proc); end
  def entries; end
  def get_64_e_o_c_d(buf); end
  def get_e_o_c_d(buf); end
  def read_64_e_o_c_d(buf); end
  def read_central_directory_entries(io); end
  def read_e_o_c_d(buf); end
  def read_from_stream(io); end
  def size; end
  def start_buf(io); end
  def write_to_stream(io); end
  def zip64_file?(buf); end

  private

  def write_64_e_o_c_d(io, offset, cdir_size); end
  def write_64_eocd_locator(io, zip64_eocd_offset); end
  def write_e_o_c_d(io, offset, cdir_size); end

  class << self
    def read_from_stream(io); end
  end
end

Zip::CentralDirectory::END_OF_CDS = T.let(T.unsafe(nil), Fixnum)

Zip::CentralDirectory::MAX_END_OF_CDS_SIZE = T.let(T.unsafe(nil), Fixnum)

Zip::CentralDirectory::STATIC_EOCD_SIZE = T.let(T.unsafe(nil), Fixnum)

Zip::CentralDirectory::ZIP64_END_OF_CDS = T.let(T.unsafe(nil), Fixnum)

Zip::CentralDirectory::ZIP64_EOCD_LOCATOR = T.let(T.unsafe(nil), Fixnum)

class Zip::CompressionMethodError < ::Zip::Error
end

class Zip::Compressor
  def finish; end
end

class Zip::DOSTime < ::Time
  def dos_equals(other); end
  def to_binary_dos_date; end
  def to_binary_dos_time; end

  class << self
    def parse_binary_dos_format(binaryDosDate, binaryDosTime); end
  end
end

class Zip::Decompressor
  def initialize(input_stream); end
end

Zip::Decompressor::CHUNK_SIZE = T.let(T.unsafe(nil), Fixnum)

class Zip::Decrypter
end

class Zip::Deflater < ::Zip::Compressor
  def initialize(output_stream, level = T.unsafe(nil), encrypter = T.unsafe(nil)); end

  def <<(data); end
  def crc; end
  def finish; end
  def size; end
end

class Zip::DestinationFileExistsError < ::Zip::Error
end

class Zip::Encrypter
end

class Zip::Entry
  def initialize(*args); end

  def <=>(other); end
  def ==(other); end
  def calculate_local_header_size; end
  def cdir_header_size; end
  def check_c_dir_entry_comment_size; end
  def check_c_dir_entry_signature; end
  def check_c_dir_entry_static_header_length(buf); end
  def check_name(name); end
  def clean_up; end
  def comment; end
  def comment=(_); end
  def comment_size; end
  def compressed_size; end
  def compressed_size=(_); end
  def compression_method; end
  def compression_method=(_); end
  def crc; end
  def crc=(_); end
  def directory?; end
  def dirty; end
  def dirty=(_); end
  def external_file_attributes; end
  def external_file_attributes=(_); end
  def extra; end
  def extra=(_); end
  def extra_size; end
  def extract(dest_path = T.unsafe(nil), &block); end
  def file?; end
  def file_stat(path); end
  def file_type_is?(type); end
  def filepath; end
  def follow_symlinks; end
  def follow_symlinks=(_); end
  def fstype; end
  def fstype=(_); end
  def ftype; end
  def gather_fileinfo_from_srcpath(src_path); end
  def get_extra_attributes_from_path(path); end
  def get_input_stream(&block); end
  def get_raw_input_stream(&block); end
  def gp_flags; end
  def gp_flags=(_); end
  def header_signature; end
  def header_signature=(_); end
  def internal_file_attributes; end
  def internal_file_attributes=(_); end
  def local_entry_offset; end
  def local_header_offset; end
  def local_header_offset=(_); end
  def mtime; end
  def name; end
  def name=(_); end
  def name_is_directory?; end
  def name_safe?; end
  def name_size; end
  def next_header_offset; end
  def pack_c_dir_entry; end
  def pack_local_entry; end
  def parent_as_string; end
  def read_c_dir_entry(io); end
  def read_c_dir_extra_field(io); end
  def read_local_entry(io); end
  def restore_ownership; end
  def restore_ownership=(_); end
  def restore_permissions; end
  def restore_permissions=(_); end
  def restore_times; end
  def restore_times=(_); end
  def set_default_vars_values; end
  def set_extra_attributes_on_path(dest_path); end
  def set_ftype_from_c_dir_entry; end
  def set_unix_permissions_on_path(dest_path); end
  def size; end
  def size=(_); end
  def symlink?; end
  def time; end
  def time=(value); end
  def to_s; end
  def unix_gid; end
  def unix_gid=(_); end
  def unix_perms; end
  def unix_perms=(_); end
  def unix_uid; end
  def unix_uid=(_); end
  def unpack_c_dir_entry(buf); end
  def unpack_local_entry(buf); end
  def verify_local_header_size!; end
  def write_c_dir_entry(io); end
  def write_local_entry(io, rewrite = T.unsafe(nil)); end
  def write_to_zip_output_stream(zip_output_stream); end
  def zipfile; end
  def zipfile=(_); end

  private

  def create_directory(dest_path); end
  def create_file(dest_path, _continue_on_exists_proc = T.unsafe(nil)); end
  def create_symlink(dest_path); end
  def data_descriptor_size; end
  def parse_zip64_extra(for_local_header); end
  def prep_zip64_extra(for_local_header); end
  def set_time(binary_dos_date, binary_dos_time); end

  class << self
    def read_c_dir_entry(io); end
    def read_local_entry(io); end
    def read_zip_64_long(io); end
    def read_zip_long(io); end
    def read_zip_short(io); end
  end
end

Zip::Entry::DEFLATED = T.let(T.unsafe(nil), Fixnum)

Zip::Entry::EFS = T.let(T.unsafe(nil), Fixnum)

Zip::Entry::STORED = T.let(T.unsafe(nil), Fixnum)

class Zip::EntryExistsError < ::Zip::Error
end

class Zip::EntryNameError < ::Zip::Error
end

class Zip::EntrySet
  include(::Enumerable)

  def initialize(an_enumerable = T.unsafe(nil)); end

  def <<(entry); end
  def ==(other); end
  def delete(entry); end
  def dup; end
  def each; end
  def entries; end
  def entry_order; end
  def entry_order=(_); end
  def entry_set; end
  def entry_set=(_); end
  def find_entry(entry); end
  def glob(pattern, flags = T.unsafe(nil)); end
  def include?(entry); end
  def length; end
  def parent(entry); end
  def push(entry); end
  def size; end

  protected

  def sorted_entries; end

  private

  def to_key(entry); end
end

class Zip::EntrySizeError < ::Zip::Error
end

class Zip::Error < ::StandardError
end

class Zip::ExtraField < ::Hash
  def initialize(binstr = T.unsafe(nil)); end

  def c_dir_size; end
  def create(name); end
  def create_unknown_item; end
  def extra_field_type_exist(binstr, id, len, i); end
  def extra_field_type_unknown(binstr, len, i); end
  def length; end
  def local_size; end
  def merge(binstr); end
  def ordered_values; end
  def size; end
  def to_c_dir_bin; end
  def to_local_bin; end
  def to_s; end
end

class Zip::ExtraField::Generic
  def ==(other); end
  def initial_parse(binstr); end
  def to_c_dir_bin; end
  def to_local_bin; end

  class << self
    def name; end
    def register_map; end
  end
end

Zip::ExtraField::ID_MAP = T.let(T.unsafe(nil), Hash)

class Zip::ExtraField::IUnix < ::Zip::ExtraField::Generic
  def initialize(binstr = T.unsafe(nil)); end

  def ==(other); end
  def gid; end
  def gid=(_); end
  def merge(binstr); end
  def pack_for_c_dir; end
  def pack_for_local; end
  def uid; end
  def uid=(_); end
end

Zip::ExtraField::IUnix::HEADER_ID = T.let(T.unsafe(nil), String)

class Zip::ExtraField::NTFS < ::Zip::ExtraField::Generic
  def initialize(binstr = T.unsafe(nil)); end

  def ==(other); end
  def atime; end
  def atime=(_); end
  def ctime; end
  def ctime=(_); end
  def merge(binstr); end
  def mtime; end
  def mtime=(_); end
  def pack_for_c_dir; end
  def pack_for_local; end

  private

  def from_ntfs_time(ntfs_time); end
  def parse_tags(content); end
  def to_ntfs_time(time); end
end

Zip::ExtraField::NTFS::HEADER_ID = T.let(T.unsafe(nil), String)

Zip::ExtraField::NTFS::SEC_TO_UNIX_EPOCH = T.let(T.unsafe(nil), Fixnum)

Zip::ExtraField::NTFS::WINDOWS_TICK = T.let(T.unsafe(nil), Float)

class Zip::ExtraField::OldUnix < ::Zip::ExtraField::Generic
  def initialize(binstr = T.unsafe(nil)); end

  def ==(other); end
  def atime; end
  def atime=(_); end
  def gid; end
  def gid=(_); end
  def merge(binstr); end
  def mtime; end
  def mtime=(_); end
  def pack_for_c_dir; end
  def pack_for_local; end
  def uid; end
  def uid=(_); end
end

Zip::ExtraField::OldUnix::HEADER_ID = T.let(T.unsafe(nil), String)

class Zip::ExtraField::UniversalTime < ::Zip::ExtraField::Generic
  def initialize(binstr = T.unsafe(nil)); end

  def ==(other); end
  def atime; end
  def atime=(_); end
  def ctime; end
  def ctime=(_); end
  def flag; end
  def flag=(_); end
  def merge(binstr); end
  def mtime; end
  def mtime=(_); end
  def pack_for_c_dir; end
  def pack_for_local; end
end

Zip::ExtraField::UniversalTime::HEADER_ID = T.let(T.unsafe(nil), String)

class Zip::ExtraField::Zip64 < ::Zip::ExtraField::Generic
  def initialize(binstr = T.unsafe(nil)); end

  def ==(other); end
  def compressed_size; end
  def compressed_size=(_); end
  def disk_start_number; end
  def disk_start_number=(_); end
  def merge(binstr); end
  def original_size; end
  def original_size=(_); end
  def pack_for_c_dir; end
  def pack_for_local; end
  def parse(original_size, compressed_size, relative_header_offset = T.unsafe(nil), disk_start_number = T.unsafe(nil)); end
  def relative_header_offset; end
  def relative_header_offset=(_); end

  private

  def extract(size, format); end
end

Zip::ExtraField::Zip64::HEADER_ID = T.let(T.unsafe(nil), String)

class Zip::ExtraField::Zip64Placeholder < ::Zip::ExtraField::Generic
  def initialize(_binstr = T.unsafe(nil)); end

  def pack_for_local; end
end

Zip::ExtraField::Zip64Placeholder::HEADER_ID = T.let(T.unsafe(nil), String)

Zip::FILE_TYPE_DIR = T.let(T.unsafe(nil), Fixnum)

Zip::FILE_TYPE_FILE = T.let(T.unsafe(nil), Fixnum)

Zip::FILE_TYPE_SYMLINK = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPES = T.let(T.unsafe(nil), Hash)

Zip::FSTYPE_ACORN = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_AMIGA = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_ATARI = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_ATHEOS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_BEOS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_CPM = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_FAT = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_HPFS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_MAC = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_MAC_OSX = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_MVS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_NTFS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_QDOS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_TANDEM = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_THEOS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_TOPS20 = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_UNIX = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_VFAT = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_VMS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_VM_CMS = T.let(T.unsafe(nil), Fixnum)

Zip::FSTYPE_Z_SYSTEM = T.let(T.unsafe(nil), Fixnum)

class Zip::File < ::Zip::CentralDirectory
  include(::Zip::FileSystem)

  def initialize(path_or_io, create = T.unsafe(nil), buffer = T.unsafe(nil), options = T.unsafe(nil)); end

  def add(entry, src_path, &continue_on_exists_proc); end
  def add_stored(entry, src_path, &continue_on_exists_proc); end
  def close; end
  def comment; end
  def comment=(_); end
  def commit; end
  def commit_required?; end
  def extract(entry, dest_path, &block); end
  def find_entry(entry_name); end
  def get_entry(entry); end
  def get_input_stream(entry, &aProc); end
  def get_output_stream(entry, permission_int = T.unsafe(nil), comment = T.unsafe(nil), extra = T.unsafe(nil), compressed_size = T.unsafe(nil), crc = T.unsafe(nil), compression_method = T.unsafe(nil), size = T.unsafe(nil), time = T.unsafe(nil), &aProc); end
  def glob(*args, &block); end
  def mkdir(entryName, permissionInt = T.unsafe(nil)); end
  def name; end
  def read(entry); end
  def remove(entry); end
  def rename(entry, new_name, &continue_on_exists_proc); end
  def replace(entry, srcPath); end
  def restore_ownership; end
  def restore_ownership=(_); end
  def restore_permissions; end
  def restore_permissions=(_); end
  def restore_times; end
  def restore_times=(_); end
  def to_s; end
  def write_buffer(io = T.unsafe(nil)); end

  private

  def check_entry_exists(entryName, continue_on_exists_proc, procedureName); end
  def check_file(path); end
  def directory?(newEntry, srcPath); end
  def on_success_replace; end

  class << self
    def add_buffer; end
    def foreach(aZipFileName, &block); end
    def get_partial_zip_file_name(zip_file_name, partial_zip_file_name); end
    def get_segment_count_for_split(zip_file_size, segment_size); end
    def get_segment_size_for_split(segment_size); end
    def open(file_name, create = T.unsafe(nil)); end
    def open_buffer(io, options = T.unsafe(nil)); end
    def put_split_signature(szip_file, segment_size); end
    def save_splited_part(zip_file, partial_zip_file_name, zip_file_size, szip_file_index, segment_size, segment_count); end
    def split(zip_file_name, segment_size = T.unsafe(nil), delete_zip_file = T.unsafe(nil), partial_zip_file_name = T.unsafe(nil)); end
  end
end

Zip::File::CREATE = T.let(T.unsafe(nil), TrueClass)

Zip::File::DATA_BUFFER_SIZE = T.let(T.unsafe(nil), Fixnum)

Zip::File::IO_METHODS = T.let(T.unsafe(nil), Array)

Zip::File::MAX_SEGMENT_SIZE = T.let(T.unsafe(nil), Fixnum)

Zip::File::MIN_SEGMENT_SIZE = T.let(T.unsafe(nil), Fixnum)

Zip::File::SPLIT_SIGNATURE = T.let(T.unsafe(nil), Fixnum)

Zip::File::ZIP64_EOCD_SIGNATURE = T.let(T.unsafe(nil), Fixnum)

module Zip::FileSystem
  def initialize; end

  def dir; end
  def file; end
end

class Zip::FileSystem::ZipFileNameMapper
  include(::Enumerable)

  def initialize(zipFile); end

  def each; end
  def expand_path(aPath); end
  def find_entry(fileName); end
  def get_entry(fileName); end
  def get_input_stream(fileName, &aProc); end
  def get_output_stream(fileName, permissionInt = T.unsafe(nil), &aProc); end
  def glob(pattern, *flags, &block); end
  def mkdir(fileName, permissionInt = T.unsafe(nil)); end
  def pwd; end
  def pwd=(_); end
  def read(fileName); end
  def remove(fileName); end
  def rename(fileName, newName, &continueOnExistsProc); end

  private

  def expand_to_entry(aPath); end
end

class Zip::FileSystem::ZipFsDir
  def initialize(mappedZip); end

  def chdir(aDirectoryName); end
  def chroot(*_args); end
  def delete(entryName); end
  def entries(aDirectoryName); end
  def file=(_); end
  def foreach(aDirectoryName); end
  def getwd; end
  def glob(*args, &block); end
  def mkdir(entryName, permissionInt = T.unsafe(nil)); end
  def new(aDirectoryName); end
  def open(aDirectoryName); end
  def pwd; end
  def rmdir(entryName); end
  def unlink(entryName); end
end

class Zip::FileSystem::ZipFsDirIterator
  include(::Enumerable)

  def initialize(arrayOfFileNames); end

  def close; end
  def each(&aProc); end
  def read; end
  def rewind; end
  def seek(anIntegerPosition); end
  def tell; end
end

class Zip::FileSystem::ZipFsFile
  def initialize(mappedZip); end

  def atime(fileName); end
  def basename(fileName); end
  def blockdev?(_filename); end
  def chardev?(_filename); end
  def chmod(modeInt, *filenames); end
  def chown(ownerInt, groupInt, *filenames); end
  def ctime(fileName); end
  def delete(*args); end
  def dir=(_); end
  def directory?(fileName); end
  def dirname(fileName); end
  def executable?(fileName); end
  def executable_real?(fileName); end
  def exist?(fileName); end
  def exists?(fileName); end
  def expand_path(aPath); end
  def file?(fileName); end
  def foreach(fileName, aSep = T.unsafe(nil), &aProc); end
  def ftype(fileName); end
  def grpowned?(fileName); end
  def join(*fragments); end
  def link(_fileName, _symlinkName); end
  def lstat(fileName); end
  def mtime(fileName); end
  def new(fileName, openMode = T.unsafe(nil)); end
  def open(fileName, openMode = T.unsafe(nil), permissionInt = T.unsafe(nil), &block); end
  def owned?(fileName); end
  def pipe; end
  def pipe?(_filename); end
  def popen(*args, &aProc); end
  def read(fileName); end
  def readable?(fileName); end
  def readable_real?(fileName); end
  def readlines(fileName); end
  def readlink(_fileName); end
  def rename(fileToRename, newName); end
  def setgid?(fileName); end
  def setuid?(fileName); end
  def size(fileName); end
  def size?(fileName); end
  def socket?(_fileName); end
  def split(fileName); end
  def stat(fileName); end
  def sticky?(fileName); end
  def symlink(_fileName, _symlinkName); end
  def symlink?(_fileName); end
  def truncate(_fileName, _len); end
  def umask(*args); end
  def unlink(*args); end
  def utime(modifiedTime, *fileNames); end
  def writable?(fileName); end
  def writable_real?(fileName); end
  def zero?(fileName); end

  private

  def get_entry(fileName); end
  def unix_mode_cmp(fileName, mode); end
end

class Zip::FileSystem::ZipFsFile::ZipFsStat
  def initialize(zipFsFile, entryName); end

  def atime; end
  def blksize; end
  def blockdev?; end
  def blocks; end
  def chardev?; end
  def ctime; end
  def dev; end
  def directory?; end
  def executable?; end
  def executable_real?; end
  def file?; end
  def ftype; end
  def gid; end
  def grpowned?; end
  def ino; end
  def kind_of?(t); end
  def mode; end
  def mtime; end
  def nlink; end
  def owned?; end
  def pipe?; end
  def rdev; end
  def rdev_major; end
  def rdev_minor; end
  def readable?; end
  def readable_real?; end
  def setgid?; end
  def setuid?; end
  def size; end
  def size?; end
  def socket?; end
  def sticky?; end
  def symlink?; end
  def uid; end
  def writable?; end
  def writable_real?; end
  def zero?; end

  private

  def get_entry; end

  class << self
    def delegate_to_fs_file(*methods); end
  end
end

class Zip::GPFBit3Error < ::Zip::Error
end

module Zip::IOExtras
  class << self
    def copy_stream(ostream, istream); end
    def copy_stream_n(ostream, istream, nbytes); end
  end
end

module Zip::IOExtras::AbstractInputStream
  include(::Enumerable)
  include(::Zip::IOExtras::FakeIO)

  def initialize; end

  def each(a_sep_string = T.unsafe(nil)); end
  def each_line(a_sep_string = T.unsafe(nil)); end
  def flush; end
  def gets(a_sep_string = T.unsafe(nil), number_of_bytes = T.unsafe(nil)); end
  def lineno; end
  def lineno=(_); end
  def pos; end
  def read(number_of_bytes = T.unsafe(nil), buf = T.unsafe(nil)); end
  def readline(a_sep_string = T.unsafe(nil)); end
  def readlines(a_sep_string = T.unsafe(nil)); end
  def ungetc(byte); end
end

module Zip::IOExtras::AbstractOutputStream
  include(::Zip::IOExtras::FakeIO)

  def print(*params); end
  def printf(a_format_string, *params); end
  def putc(an_object); end
  def puts(*params); end
  def write(data); end
end

Zip::IOExtras::CHUNK_SIZE = T.let(T.unsafe(nil), Fixnum)

module Zip::IOExtras::FakeIO
  def kind_of?(object); end
end

Zip::IOExtras::RANGE_ALL = T.let(T.unsafe(nil), Range)

class Zip::Inflater < ::Zip::Decompressor
  def initialize(input_stream, decrypter = T.unsafe(nil)); end

  def eof; end
  def eof?; end
  def input_finished?; end
  def produce_input; end
  def sysread(number_of_bytes = T.unsafe(nil), buf = T.unsafe(nil)); end

  private

  def internal_input_finished?; end
  def internal_produce_input(buf = T.unsafe(nil)); end
  def value_when_finished; end
end

class Zip::InputStream
  include(::Enumerable)
  include(::Zip::IOExtras::FakeIO)
  include(::Zip::IOExtras::AbstractInputStream)

  def initialize(context, offset = T.unsafe(nil), decrypter = T.unsafe(nil)); end

  def close; end
  def eof; end
  def eof?; end
  def get_next_entry; end
  def rewind; end
  def sysread(number_of_bytes = T.unsafe(nil), buf = T.unsafe(nil)); end

  protected

  def get_decompressor; end
  def get_io(io_or_file, offset = T.unsafe(nil)); end
  def input_finished?; end
  def open_entry; end
  def produce_input; end

  class << self
    def open(filename_or_io, offset = T.unsafe(nil), decrypter = T.unsafe(nil)); end
    def open_buffer(filename_or_io, offset = T.unsafe(nil)); end
  end
end

class Zip::InternalError < ::Zip::Error
end

Zip::LOCAL_ENTRY_SIGNATURE = T.let(T.unsafe(nil), Fixnum)

Zip::LOCAL_ENTRY_STATIC_HEADER_LENGTH = T.let(T.unsafe(nil), Fixnum)

Zip::LOCAL_ENTRY_TRAILING_DESCRIPTOR_LENGTH = T.let(T.unsafe(nil), Fixnum)

class Zip::NullCompressor < ::Zip::Compressor
  include(::Singleton)
  extend(::Singleton::SingletonClassMethods)

  def <<(_data); end
  def compressed_size; end
  def size; end

  class << self
    def instance; end
  end
end

module Zip::NullDecompressor

  private

  def eof; end
  def eof?; end
  def input_finished?; end
  def produce_input; end
  def sysread(_numberOfBytes = T.unsafe(nil), _buf = T.unsafe(nil)); end

  class << self
    def eof; end
    def input_finished?; end
    def produce_input; end
    def sysread(_numberOfBytes = T.unsafe(nil), _buf = T.unsafe(nil)); end
  end
end

class Zip::NullDecrypter < ::Zip::Decrypter
  include(::Zip::NullEncryption)

  def decrypt(data); end
  def reset!(_header); end
end

class Zip::NullEncrypter < ::Zip::Encrypter
  include(::Zip::NullEncryption)

  def data_descriptor(_crc32, _compressed_size, _uncomprssed_size); end
  def encrypt(data); end
  def header(_mtime); end
  def reset!; end
end

module Zip::NullEncryption
  def gp_flags; end
  def header_bytesize; end
end

module Zip::NullInputStream
  include(::Zip::NullDecompressor)
  include(::Enumerable)
  include(::Zip::IOExtras::FakeIO)
  include(::Zip::IOExtras::AbstractInputStream)
end

class Zip::OutputStream
  include(::Zip::IOExtras::FakeIO)
  include(::Zip::IOExtras::AbstractOutputStream)

  def initialize(file_name, stream = T.unsafe(nil), encrypter = T.unsafe(nil)); end

  def <<(data); end
  def close; end
  def close_buffer; end
  def comment; end
  def comment=(_); end
  def copy_raw_entry(entry); end
  def put_next_entry(entry_name, comment = T.unsafe(nil), extra = T.unsafe(nil), compression_method = T.unsafe(nil), level = T.unsafe(nil)); end

  protected

  def finish; end

  private

  def finalize_current_entry; end
  def get_compressor(entry, level); end
  def init_next_entry(entry, level = T.unsafe(nil)); end
  def update_local_headers; end
  def write_central_directory; end

  class << self
    def open(file_name, encrypter = T.unsafe(nil)); end
    def write_buffer(io = T.unsafe(nil), encrypter = T.unsafe(nil)); end
  end
end

class Zip::PassThruCompressor < ::Zip::Compressor
  def initialize(outputStream); end

  def <<(data); end
  def crc; end
  def size; end
end

class Zip::PassThruDecompressor < ::Zip::Decompressor
  def initialize(input_stream, chars_to_read); end

  def eof; end
  def eof?; end
  def input_finished?; end
  def produce_input; end
  def sysread(number_of_bytes = T.unsafe(nil), buf = T.unsafe(nil)); end
end

class Zip::StreamableDirectory < ::Zip::Entry
  def initialize(zipfile, entry, srcPath = T.unsafe(nil), permissionInt = T.unsafe(nil)); end
end

class Zip::StreamableStream
  def initialize(entry); end

  def clean_up; end
  def get_input_stream; end
  def get_output_stream; end
  def write_to_zip_output_stream(aZipOutputStream); end
end

class Zip::TraditionalDecrypter < ::Zip::Decrypter
  include(::Zip::TraditionalEncryption)

  def decrypt(data); end
  def reset!(header); end

  private

  def decode(n); end
end

class Zip::TraditionalEncrypter < ::Zip::Encrypter
  include(::Zip::TraditionalEncryption)

  def data_descriptor(crc32, compressed_size, uncomprssed_size); end
  def encrypt(data); end
  def header(mtime); end
  def reset!; end

  private

  def encode(n); end
end

module Zip::TraditionalEncryption
  def initialize(password); end

  def gp_flags; end
  def header_bytesize; end

  protected

  def decrypt_byte; end
  def reset_keys!; end
  def update_keys(n); end
end

Zip::VERSION_MADE_BY = T.let(T.unsafe(nil), Fixnum)

Zip::VERSION_NEEDED_TO_EXTRACT = T.let(T.unsafe(nil), Fixnum)

Zip::VERSION_NEEDED_TO_EXTRACT_ZIP64 = T.let(T.unsafe(nil), Fixnum)

Zip::ZipCompressionMethodError = Zip::CompressionMethodError

Zip::ZipDestinationFileExistsError = Zip::DestinationFileExistsError

Zip::ZipEntryExistsError = Zip::EntryExistsError

Zip::ZipEntryNameError = Zip::EntryNameError

Zip::ZipError = Zip::Error

Zip::ZipInternalError = Zip::InternalError
