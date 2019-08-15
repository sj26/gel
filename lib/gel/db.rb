# frozen_string_literal: true

require "monitor"

class Gel::DB
  def initialize(root, name)
    @root = root
    @name = name
    @path = File.join("#{root}/#{name}")
    @transaction = nil
    @monitor = Monitor.new
  end

  if Monitor.method_defined?(:mon_owned?) # Ruby 2.4+
    def owned?
      @monitor.mon_owned?
    end
  else
    def owned?
      @monitor.instance_variable_get(:@mon_owner) == Thread.current
    end
  end

  def write?
    owned? && @transaction == :write
  end

  def read?
    owned? && @transaction
  end

  def nested?
    owned? && @transaction
  end

  def writing
    if write?
      yield
    elsif nested?
      raise
    else
      @monitor.synchronize do
        begin
          @transaction = :write

          Dir.mkdir(@path) unless Dir.exist?(@path)

          yield
        ensure
          @transaction = nil
        end
      end
    end
  end

  def reading
    if read?
      yield
    elsif nested?
      raise
    else
      @monitor.synchronize do
        begin
          @transaction = :read

          yield
        ensure
          @transaction = nil
        end
      end
    end
  end

  def each_key
    reading do
      Dir.each_child(@path) do |filename|
        yield unmangle(filename)
      end
    end
  end

  def key?(key)
    reading do
      subpath = File.join @path, mangle(key)
      File.exist? subpath
    end
  end

  def [](key)
    reading do
      subpath = File.join @path, mangle(key)
      begin
        Marshal.load File.binread(subpath)
      rescue Errno::ENOENT
      end
    end
  end

  def []=(key, value)
    writing do
      subpath = File.join @path, mangle(key)
      if value
        File.binwrite subpath, Marshal.dump(value)
      elsif File.exist? subpath
        File.unlink subpath
      end
    end
  end

  private

  def marshal_dump
    [@root, @name]
  end

  def marshal_load((root, name))
    initialize(root, name)
  end

  def mangle(key)
    [key].pack("m").chomp
  end

  def unmangle(filename)
    filename.unpack1("m")
  end
end
