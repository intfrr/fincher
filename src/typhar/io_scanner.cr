module Typhar
  class IOScanner
    @last_match : ::Regex::MatchData?
    @line_offset = 0
    @line_start_offset : Int32 | Int64 = 0
    @line_size = 0

    getter io
    getter last_match
    forward_missing_to io

    def initialize(@io : Typhar::IO)
    end

    def initialize(io : IOScanner)
      @io = io.io
      @last_match = io.last_match
    end

    def scan_until(pattern)
      last_match = @last_match

      if last_match
        last_match = scan_next(pattern, last_match.post_match)
      end

      unless last_match
        each_line { |line| break if scan_next(pattern, line) }
      end

      @last_match
    end

    def each_line
      io.each_line do |line|
        @line_start_offset = io.pos - line.bytesize
        @line_offset = 0
        @line_size = line.size
        yield line
      end
    end

    def offset
      line_start_offset = @line_start_offset
      line_offset = @line_offset

      if line_start_offset > 0 || line_offset > 0
        line_start_offset + line_offset
      else
        io.pos
      end
    end

    def pos
      offset
    end

    def size
      case _io = io
      when ::IO::FileDescriptor
        _io.stat.size
      else
        _io.size
      end
    end

    def inspect(stream : ::IO)
      stream << "#<IOScanner "
      stream << offset << "/" << size
      if last_match = @last_match
        stream << " @last_match=\"" << last_match.inspect << "\" "
      end
      stream << ">"
    end

    private def scan_next(pattern, str)
      if m = pattern.match(str)
        @line_offset += m.string.bytesize - m.post_match.size
        @last_match = m
      else
        @last_match = nil
      end

      @last_match
    end
  end
end