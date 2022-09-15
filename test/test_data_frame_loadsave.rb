# frozen_string_literal: true

require 'test_helper'

class DataFrameLoadSaveTest < Test::Unit::TestCase
  include Helper

  module SaveLoadFormatTests
    def test_default
      tmpfile = create_output('.arrow')
      @df.save(tmpfile)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile))
    end

    def test_arrow_file
      tmpfile = create_output('.arrow')
      @df.save(tmpfile, format: :arrow_file)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :arrow_file))
    end

    def test_batch
      tmpfile = create_output('.arrow')
      @df.save(tmpfile, format: :batch)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :batch))
    end

    def test_arrows
      tmpfile = create_output('.arrows')
      @df.save(tmpfile, format: :arrows)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :arrows))
    end

    def test_arrow_streaming
      tmpfile = create_output('.arrows')
      @df.save(tmpfile, format: :arrow_streaming)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :arrow_streaming))
    end

    def test_stream
      tmpfile = create_output('.arrows')
      @df.save(tmpfile, format: :stream)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :stream))
    end

    def test_csv
      tmpfile = create_output('.csv')
      @df.save(tmpfile, format: :csv)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :csv, schema: @df.table.schema))
    end

    def test_csv_gz
      tmpfile = create_output('.csv.gz')
      @df.save(tmpfile, format: :csv, compression: :gzip)
      assert_equal(@df,
                   RedAmber::DataFrame.load(tmpfile, format: :csv, compression: :gzip,
                                                     schema: @df.table.schema))
    end

    def test_tsv
      tmpfile = create_output('.tsv')
      @df.save(tmpfile, format: :tsv)
      assert_equal(@df, RedAmber::DataFrame.load(tmpfile, format: :tsv, schema: @df.table.schema))
    end
  end

  sub_test_case('#load and #save') do
    def setup
      @df = RedAmber::DataFrame.new(x: [1, 2, 3])
    end

    sub_test_case('path') do
      sub_test_case(':format') do
        include SaveLoadFormatTests

        def create_output(extension)
          @file = Tempfile.new(['red-arrow', extension])
          @file.path
        end

        sub_test_case('save: auto detect') do
          test('arrow') do
            tmpfile = create_output('.arrow')
            @df.save(tmpfile)
            assert_equal(@df,
                         RedAmber::DataFrame.load(tmpfile, format: :arrow,
                                                           schema: @df.table.schema))
          end

          test('arrows') do
            tmpfile = create_output('.arrows')
            @df.save(tmpfile)
            assert_equal(@df,
                         RedAmber::DataFrame.load(tmpfile, format: :arrows,
                                                           schema: @df.table.schema))
          end

          test('csv') do
            tmpfile = create_output('.csv')
            @df.save(tmpfile)
            assert_equal(@df,
                         RedAmber::DataFrame.load(tmpfile, format: :csv, schema: @df.table.schema))
          end

          test('csv.gz') do
            tmpfile = create_output('.csv.gz')
            @df.save(tmpfile)
            assert_equal(@df,
                         RedAmber::DataFrame.load(tmpfile, format: :csv, compression: :gzip,
                                                           schema: @df.table.schema))
          end

          test('tsv') do
            tmpfile = create_output('.tsv')
            @df.save(tmpfile)
            assert_equal(@df,
                         RedAmber::DataFrame.load(tmpfile, format: :tsv, schema: @df.table.schema))
          end
        end

        sub_test_case('load: auto detect') do
          test('arrow: file') do
            tmpfile = create_output('.arrow')
            @df.save(tmpfile, format: :arrow_file)
            assert_equal(@df, RedAmber::DataFrame.load(tmpfile))
          end

          test('arrow: streaming') do
            tmpfile = create_output('.arrow')
            @df.save(tmpfile, format: :arrows)
            assert_equal(@df, RedAmber::DataFrame.load(tmpfile))
          end

          test('arrows') do
            tmpfile = create_output('.arrows')
            @df.save(tmpfile, format: :arrows)
            assert_equal(@df, RedAmber::DataFrame.load(tmpfile))
          end

          test('csv') do
            path = entity_path / 'with_header.csv'
            table = RedAmber::DataFrame.load(path, skip_lines: /^\#/)
            assert_equal(<<~TABLE, table.to_s)
                name         age
                <string> <uint8>
              0 Yasuko        68
              1 Rui           49
              2 Hinata        28
            TABLE
          end

          test('csv_empty') do
            path = entity_path / 'empty.csv'
            table = RedAmber::DataFrame.load(path, skip_lines: /^\#/)
            assert_equal('', table.to_s)
          end

          test('csv_two_empty_lines') do
            path = entity_path / 'empty2.csv'
            table = RedAmber::DataFrame.load(path, skip_lines: /^\#/)
            assert_equal('', table.to_s)
          end

          test('csv.gz') do
            file = Tempfile.new(['red-arrow', '.csv.gz'])
            file.close
            Zlib::GzipWriter.open(file.path) do |gz|
              gz.write(<<~CSV)
                name,age
                Yasuko,68
                Rui,49
                Hinata,28
              CSV
            end
            assert_equal(<<~TABLE, RedAmber::DataFrame.load(file.path).to_s)
                name         age
                <string> <int64>
              0 Yasuko        68
              1 Rui           49
              2 Hinata        28
            TABLE
          end

          test('tsv') do
            file = Tempfile.new(['red-arrow', '.tsv'])
            file.puts(<<~TSV)
              name\tage
              Yasuko\t68
              Rui\t49
              Hinata\t28
            TSV
            file.close
            table = RedAmber::DataFrame.load(file.path)
            assert_equal(<<~TABLE, table.to_s)
                name         age
                <string> <int64>
              0 Yasuko        68
              1 Rui           49
              2 Hinata        28
            TABLE
          end
        end
      end
    end

    sub_test_case('Buffer') do
      sub_test_case(':format') do
        include SaveLoadFormatTests

        def create_output(_)
          Arrow::ResizableBuffer.new(1024)
        end
      end
    end

    sub_test_case('URI') do
      def start_web_server(path, data, content_type)
        $stderr = StringIO.new
        http_server =
          WEBrick::HTTPServer.new(Port: 0, Logger: WEBrick::Log.new(nil, WEBrick::BasicLog::WARN))
        http_server.mount_proc(path) do |_, response|
          response.body = data
          response.content_type = content_type
        end
        http_server_thread = Thread.new do
          http_server.start
        end
        begin
          Timeout.timeout(1) do
            yield(http_server[:Port])
          end
        ensure
          http_server.shutdown
          http_server_thread.join
          $stderr = STDERR
        end
      end

      data('Arrow File',
           ['arrow', 'application/vnd.apache.arrow.file'])
      data('Arrow Stream',
           ['arrows', 'application/vnd.apache.arrow.stream'])
      data('CSV',
           ['csv', 'text/csv'])
      def test_http(data)
        extension, content_type = data
        tmpfile = Arrow::ResizableBuffer.new(1024)
        @df.save(tmpfile, format: extension.to_sym)
        path = "/data.#{extension}"
        start_web_server(path, tmpfile.data.to_s, content_type) do |port|
          input = URI("http://127.0.0.1:#{port}#{path}")
          loaded_df = RedAmber::DataFrame.load(input)
          assert_equal(@df.to_h, loaded_df.to_h)
        end
      end
    end
  end
end
