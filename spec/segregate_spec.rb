require 'spec_helper'

describe Segregate do
  it 'should be an instance of Class' do
    expect(Segregate).to be_an_instance_of Class
  end

  describe '::new' do
    it "creates a new parser" do
      expect(Segregate.new).to be_an_instance_of Segregate
    end
  end

  context 'a new parser has been created' do
    before(:each) do
      @parser = Segregate.new
    end

    describe '#parse_data' do
      it 'can accept partial first lines' do
        @parser.parse_data "GET /endpoint"
        @parser.parse_data " HTTP/1.1\r\n"
        expect(@parser.request_line).to eq "GET /endpoint HTTP/1.1"
      end

      it 'can accept partial headers' do
        @parser.parse_data "GET /endpoint HTTP/1.1\r\n"
        @parser.parse_data "host: www.goo"
        @parser.parse_data "gle.com\r\n"
        expect(@parser.headers['host']).to eq 'www.google.com'
      end

      it 'can accept partial body' do
        @parser.parse_data "GET /endpoint HTTP/1.1\r\n"
        @parser.parse_data "transfer-encoding: chunked\r\n\r\n"
        @parser.parse_data "9\r\n"
        @parser.parse_data "12345"
        @parser.parse_data "6789\r\n"
        expect(@parser.body).to eq "123456789"
      end

      it 'can accept partial body' do
        @parser.parse_data "GET /endpoint HTTP/1.1\r\n"
        @parser.parse_data "content-length: 9\r\n\r\n"
        @parser.parse_data "12345"
        @parser.parse_data "6789\r\n"
        expect(@parser.body).to eq "123456789"
      end
    end

    describe '#uri' do
      it 'returns nil' do
        expect(@parser.uri).to be_nil
      end
    end

    describe '#type' do
      it 'is a symbol' do
        expect(@parser.type).to be_an_instance_of Symbol
      end

      it 'is in a unknown state' do
        expect(@parser.type).to be :unknown
      end
    end

    describe '#state' do
      it 'is a symbol' do
        expect(@parser.state).to be_an_instance_of Symbol
      end

      it 'is in a first line state' do
        expect(@parser.state).to be :first_line
      end
    end

    describe '#http_version' do
      it 'returns [nil, nil]' do
        expect(@parser.http_version).to eq [nil, nil]
      end
    end

    describe '#request_method' do
      it 'returns nil' do
        expect(@parser.request_method).to be_nil
      end
    end

    describe '#status_code' do
      it 'returns nil' do
        expect(@parser.status_code).to be_nil
      end
    end

    describe '#status_phrase' do
      it 'returns nil' do
        expect(@parser.status_phrase).to be_nil
      end
    end

    describe '#first_line' do
      it 'is an instance of first line parser' do
        expect(@parser.first_line).to be_an_instance_of Segregate::FirstLineParser
      end

      it 'is ready' do
        expect(@parser.first_line.state).to be :ready
      end
    end

    describe '#headers' do
      it 'is an instance of header parser' do
        expect(@parser.headers).to be_an_instance_of Segregate::HeaderParser
      end

      it 'is ready' do
        expect(@parser.headers.state).to be :ready
      end
    end

    describe '#body' do
      it 'is nil' do
        expect(@parser.body).to be_nil
      end
    end

    describe '#request?' do
      it 'returns false' do
        expect(@parser.request?).to be false
      end
    end

    describe '#response?' do
      it 'returns false' do
        expect(@parser.response?).to be false
      end
    end

    describe '#unknown?' do
      it 'returns true' do
        expect(@parser.unknown?).to be true
      end
    end

    describe '#request_line' do
      it 'returns nil' do
        expect(@parser.request_line).to be_nil
      end
    end

    describe '#status_line' do
      it 'returns nil' do
        expect(@parser.status_line).to be_nil
      end
    end

    describe '#unknown_line' do
      it 'returns empty' do
        expect(@parser.unknown_line).to be_nil
      end
    end

    describe '#request_url' do
      it 'returns nil' do
        expect(@parser.request_url).to be_nil
      end
    end

    describe '#major_http_version' do
      it 'returns nil' do
        expect(@parser.major_http_version).to be_nil
      end
    end

    describe '#minor_http_version' do
      it 'returns nil' do
        expect(@parser.minor_http_version).to be_nil
      end
    end

    context 'a request line has been parsed' do
      before(:each) do
        @parser.parse_data "GET /endpoint HTTP/1.1\r\n"
      end

      describe '#uri' do
        it 'is an instance of URI' do
          expect(@parser.uri).to be_an_instance_of URI::Generic
        end
      end

      describe '#respond_to?' do
        it 'responds to segregate methods' do
          expect(@parser.respond_to?(:request_line)).to be true
        end

        it 'responds to uri methods' do
          expect(@parser.respond_to?(:hostname)).to be true
        end
      end

      describe '#type' do
        it 'is in a request state' do
          expect(@parser.type).to be :request
        end
      end

      describe '#state' do
        it 'is in a headers state' do
          expect(@parser.state).to be :headers
        end
      end

      describe '#http_version' do
        it 'returns [1, 1]' do
          expect(@parser.http_version).to eq [1, 1]
        end
      end

      describe '#request_method' do
        it 'returns GET' do
          expect(@parser.request_method).to eq 'GET'
        end
      end

      describe '#status_code' do
        it 'returns nil' do
          expect(@parser.status_code).to be_nil
        end
      end

      describe '#status_phrase' do
        it 'returns nil' do
          expect(@parser.status_phrase).to be_nil
        end
      end

      describe '#headers' do
        it 'is ready' do
          expect(@parser.headers.state).to be :ready
        end
      end

      describe '#body' do
        it 'is nil' do
          expect(@parser.body).to be_nil
        end
      end

      describe '#request?' do
        it 'returns false' do
          expect(@parser.request?).to be true
        end
      end

      describe '#response?' do
        it 'returns false' do
          expect(@parser.response?).to be false
        end
      end

      describe '#unknown?' do
        it 'returns false' do
          expect(@parser.unknown?).to be false
        end
      end

      describe '#request_line' do
        it 'returns a valid request line' do
          expect(@parser.request_line).to match Segregate::FirstLineParser::FirstLineHelpers::REQUEST_LINE
        end
      end

      describe '#status_line' do
        it 'returns nil' do
          expect(@parser.status_line).to be_nil
        end
      end

      describe '#unknown_line' do
        it 'returns nil' do
          expect(@parser.unknown_line).to be_nil
        end
      end

      describe '#request_url' do
        it 'returns /endpoint' do
          expect(@parser.request_url).to eq '/endpoint'
        end
      end

      describe '#major_http_version' do
        it 'returns 1' do
          expect(@parser.major_http_version).to eq 1
        end
      end

      describe '#minor_http_version' do
        it 'returns 1' do
          expect(@parser.minor_http_version).to eq 1
        end
      end

      context 'headers have been parsed' do
        before(:each) do
          @parser.parse_data "host: www.google.com\r\ncontent-length: 10\r\n\r\n"
        end

        describe '#state' do
          it 'is in a body state' do
            expect(@parser.state).to eq :body
          end
        end

        describe '#headers' do
          it 'has the correct keys' do
            expect(@parser.headers.keys).to eq ['host', 'content-length']
          end

          it 'has the correct values' do
            expect(@parser.headers.values).to eq ['www.google.com', '10']
          end
        end

        describe '#body' do
          it 'is not nil' do
            expect(@parser.body).to_not be_nil
          end
        end

        context 'a body has been parsed' do
          before(:each) do
            @parser.parse_data "1234567890\r\n"
          end

          describe '#state' do
            it 'is in a done state' do
              expect(@parser.state).to eq :done
            end
          end

          describe '#body' do
            it 'has the correct data' do
              expect(@parser.body).to eq '1234567890'
            end
          end

          describe '#to_s' do
            it 'returns the message in string form' do
              expect(@parser.to_s).to eq "GET /endpoint HTTP/1.1\r\nhost: www.google.com\r\ncontent-length: 10\r\n\r\n1234567890\r\n\r\n"
            end
          end

          describe '#major_http_version=' do
            it 'updates the major http version' do
              @parser.major_http_version = 2
              expect(@parser.request_line).to eq 'GET /endpoint HTTP/2.1'
            end
          end

          describe '#minor_http_version=' do
            it 'updates the minor http version' do
              @parser.minor_http_version = 2
              expect(@parser.request_line).to eq 'GET /endpoint HTTP/1.2'
            end
          end

          describe '#request_method=' do
            it 'updates the request method' do
              @parser.request_method = 'POST'
              expect(@parser.request_line).to eq 'POST /endpoint HTTP/1.1'
            end
          end

          describe '#path=' do
            it 'updates the request url' do
              @parser.path = '/new/endpoint'
              expect(@parser.request_line).to eq 'GET /new/endpoint HTTP/1.1'
            end
          end

          describe '#body=' do
            it 'updates the body' do
              @parser.body = 'this is the body'
              expect(@parser.to_s).to eq "GET /endpoint HTTP/1.1\r\nhost: www.google.com\r\ncontent-length: 16\r\n\r\nthis is the body\r\n\r\n"
            end
          end
        end
      end

      context 'non body headers have been parsed' do
        before(:each) do
          @parser.parse_data "host: www.google.com\r\naccept: *\r\n\r\n"
        end

        describe '#state' do
          it 'is in a done state' do
            expect(@parser.state).to eq :done
          end
        end

        describe '#headers' do
          it 'has the correct keys' do
            expect(@parser.headers.keys).to eq ['host', 'accept']
          end

          it 'has the correct values' do
            expect(@parser.headers.values).to eq ['www.google.com', '*']
          end
        end

        describe '#body' do
          it 'is nil' do
            expect(@parser.body).to be_nil
          end
        end
      end
    end

    context 'a status line has been parsed' do
      before(:each) do
        @parser.parse_data "HTTP/1.1 200 OK\r\n"
      end

      describe '#uri' do
        it 'returns nil' do
          expect(@parser.uri).to be_nil
        end
      end

      describe '#type' do
        it 'is in a request state' do
          expect(@parser.type).to eq :response
        end
      end

      describe '#state' do
        it 'is in a headers state' do
          expect(@parser.state).to eq :headers
        end
      end

      describe '#http_version' do
        it 'returns [1, 1]' do
          expect(@parser.http_version).to eq [1, 1]
        end
      end

      describe '#request_method' do
        it 'returns nil' do
          expect(@parser.request_method).to be_nil
        end
      end

      describe '#status_code' do
        it 'returns 200' do
          expect(@parser.status_code).to eq 200
        end
      end

      describe '#status_phrase' do
        it 'returns OK' do
          expect(@parser.status_phrase).to eq 'OK'
        end
      end

      describe '#headers' do
        it 'is empty' do
          expect(@parser.headers).to be_empty
        end
      end

      describe '#body' do
        it 'is nil' do
          expect(@parser.body).to be_nil
        end
      end

      describe '#request?' do
        it 'returns false' do
          expect(@parser.request?).to be false
        end
      end

      describe '#response?' do
        it 'returns true' do
          expect(@parser.response?).to be true
        end
      end

      describe '#unknown?' do
        it 'returns false' do
          expect(@parser.unknown?).to be false
        end
      end

      describe '#request_line' do
        it 'returns nil' do
          expect(@parser.request_line).to be_nil
        end
      end

      describe '#status_line' do
        it 'returns a valid status line' do
          expect(@parser.status_line).to match Segregate::FirstLineParser::FirstLineHelpers::STATUS_LINE
        end
      end

      describe '#unknown_line' do
        it 'returns nil' do
          expect(@parser.unknown_line).to be_nil
        end
      end

      describe '#request_url' do
        it 'returns nil' do
          expect(@parser.request_url).to be_nil
        end
      end

      describe '#major_http_version' do
        it 'returns 1' do
          expect(@parser.major_http_version).to eq 1
        end
      end

      describe '#minor_http_version' do
        it 'returns 1' do
          expect(@parser.minor_http_version).to eq 1
        end
      end

      context 'headers have been parsed' do
        before(:each) do
          @parser.parse_data "host: www.google.com\r\ntransfer-encoding: chunked\r\n\r\n"
        end

        describe '#state' do
          it 'is in a body state' do
            expect(@parser.state).to eq :body
          end
        end

        describe '#headers' do
          it 'has the correct keys' do
            expect(@parser.headers.keys).to eq ['host', 'transfer-encoding']
          end

          it 'has the correct values' do
            expect(@parser.headers.values).to eq ['www.google.com', 'chunked']
          end
        end

        describe '#body' do
          it 'is empty' do
            expect(@parser.body).to be_empty
          end
        end

        context 'a body has been parsed' do
          before(:each) do
            @parser.parse_data "9\r\n123456789\r\n0\r\n\r\n"
          end

          describe '#state' do
            it 'is in a done state' do
              expect(@parser.state).to eq :done
            end
          end

          describe '#body' do
            it 'has the correct data' do
              expect(@parser.body).to eq '123456789'
            end
          end

          describe '#to_s' do
            it 'returns the message in string form' do
              expect(@parser.to_s).to eq "HTTP/1.1 200 OK\r\nhost: www.google.com\r\ntransfer-encoding: chunked\r\n\r\n9\r\n123456789\r\n0\r\n\r\n"
            end
          end

          describe '#major_http_version=' do
            it 'updates the major http version' do
              @parser.major_http_version = 2
              expect(@parser.status_line).to eq 'HTTP/2.1 200 OK'
            end
          end

          describe '#minor_http_version=' do
            it 'updates the minor http version' do
              @parser.minor_http_version = 2
              expect(@parser.status_line).to eq 'HTTP/1.2 200 OK'
            end
          end

          describe '#status_code=' do
            it 'updates the status code' do
              @parser.status_code = 404
              expect(@parser.status_line).to eq 'HTTP/1.1 404 OK'
            end
          end

          describe '#status_phrase=' do
            it 'updates the status phrase' do
              @parser.status_phrase = 'not found'
              expect(@parser.status_line).to eq 'HTTP/1.1 200 not found'
            end
          end

          describe '#body=' do
            it 'updates the body' do
              @parser.body = 'this is the body'
              expect(@parser.to_s).to eq "HTTP/1.1 200 OK\r\nhost: www.google.com\r\ntransfer-encoding: chunked\r\n\r\n10\r\nthis is the body\r\n0\r\n\r\n"
            end
          end
        end
      end

      context 'non body headers have been parsed' do
        before(:each) do
          @parser.parse_data "host: www.google.com\r\naccept: *\r\n\r\n"
        end

        describe '#state' do
          it 'is in a done state' do
            expect(@parser.state).to eq :done
          end
        end

        describe '#headers' do
          it 'has the correct keys' do
            expect(@parser.headers.keys).to eq ['host', 'accept']
          end

          it 'has the correct values' do
            expect(@parser.headers.values).to eq ['www.google.com', '*']
          end
        end

        describe '#body' do
          it 'is nil' do
            expect(@parser.body).to be_nil
          end
        end
      end
    end
  end
end
