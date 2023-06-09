# frozen_string_literal: true

module RedAmber
  # Mix-in for the class DataFrame
  module DataFrameLoadSave
    # Enable `self.load` as class method of DataFrame
    def self.included(klass)
      klass.extend ClassMethods
    end

    # Enable `self.load` as class method of DataFrame
    module ClassMethods
      # Load DataFrame via Arrow::Table.load.
      #
      # Format is automatically detected by extension.
      # @!method load(input, format: nil, compression: nil, schema: nil, skip_lines: nil)
      # @param input [path]
      #   source path.
      # @param format [:arrow_file, :batch, :arrows, :arrow_stream, :stream, :csv, :tsv]
      #   format specifier.
      # @param compression [:gzip, nil]
      #   compression type.
      # @param schema [Arrow::Schema]
      #   schema of table.
      # @param skip_lines [Regexp]
      #   pattern of rows to skip.
      # @return [DataFrame]
      #   loaded DataFrame.
      # @example Load a tsv file
      #   DataFrame.load("file.tsv")
      #
      # @example Load a csv.gz file
      #   DataFrame.load("file.csv.gz")
      #
      # @example Load from URI
      #   DataFrame.load(URI("https://some_uri/file.csv"))
      #
      # @example Load from a Buffer
      #   DataFrame.load(Arrow::Buffer.new(<<~BUFFER), format: :csv)
      #     name,age
      #     Yasuko,68
      #     Rui,49
      #     Hinata,28
      #   BUFFER
      #
      # @example Load from a Buffer skipping comment line
      #   DataFrame.load(Arrow::Buffer.new(<<~BUFFER), format: :csv, skip_lines: /\A#/)
      #     # comment
      #     name,age
      #     Yasuko,68
      #     Rui,49
      #     Hinata,28
      #   BUFFER
      #
      def load(input, **options)
        DataFrame.new(Arrow::Table.load(input, options))
      end
    end

    # Save DataFrame
    #
    # Format is automatically detected by extension.
    # @!method save(output, format: nil, compression: nil, schema: nil, skip_lines: nil)
    # @param output [path]
    #   output path.
    # @param format [:arrow_file, :batch, :arrows, :arrow_stream, :stream, :csv, :tsv]
    #   format specifier.
    # @param compression [:gzip, nil]
    #   compression type.
    # @param schema [Arrow::Schema]
    #   schema of table.
    # @param skip_lines [Regexp]
    #   pattern of rows to skip.
    # @return [DataFrame]
    #   self.
    # @example Save a csv file
    #   DataFrame.save("file.csv")
    #
    # @example Save a csv.gz file
    #   DataFrame.save("file.csv.gz")
    #
    # @example Save an arrow file
    #   DataFrame.save("file.arrow")
    #
    def save(output, **options)
      @table.save(output, options)
      self
    end

    # Save and reload to cast automatically
    # via tsv format file temporally as default.
    #
    # @param format [Symbol]
    #   format specifier.
    # @return [DataFrame]
    #   reloaded DataFrame.
    #
    # @note experimental feature
    def auto_cast(format: :tsv)
      return self if empty?

      buffer = Arrow::ResizableBuffer.new(1024)
      save(buffer, format: format)
      DataFrame.load(buffer, format: format)
    end
  end
end
