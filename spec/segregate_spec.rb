require 'spec_helper'

describe Segregate do
  it 'should be an instance of Class' do
    expect(Segregate).to be_an_instance_of Class
  end

  describe '::new' do
  	it 'returns an instance of Segregate' do
  		expect(Segregate.new).to be_an_instance_of Segregate
  	end

    it 'has the inital values' do
      @parser = Segregate.new
      expect(@parser.request?).to be_false
      expect(@parser.response?).to be_false
      expect(@parser.uri).to be_nil
      expect(@parser.request_line).to be_nil
      expect(@parser.request_method).to be_nil
      expect(@parser.request_url).to be_nil
      expect(@parser.status_line).to be_nil
      expect(@parser.status_code).to be_nil
      expect(@parser.status_phrase).to be_nil
      expect(@parser.http_version).to eq [nil, nil]
      expect(@parser.major_http_version).to be_nil
      expect(@parser.minor_http_version).to be_nil
    end
  end

  context 'a new parser has been created' do
    before(:each) do
      @parser = Segregate.new
    end

    describe '#parse' do
      it 'accepts one argument' do
        expect(@parser).to respond_to(:parse).with(1).argument
      end

      it 'errors if an incorrect first line is received' do
        expect{@parser.parse "fail\r\n"}.to raise_error RuntimeError, "ERROR: Unknown first line: fail" 
      end

      it 'errors if an incorrect http method is received' do
        expect{@parser.parse "FAIL /endpoint HTTP/1.1\r\n"}.to raise_error RuntimeError, "ERROR: Unknown http method: FAIL" 
      end
    end

    context 'a request line has been parsed' do
      before(:each) do
        @parser.parse "GET /endpoint HTTP/1.1\r\n"
      end

      describe '#request_line' do
        it 'returns a string' do
          expect(@parser.request_line).to be_an_instance_of String
        end

        it 'returns a request line' do
          expect(@parser.request_line).to match Segregate::REQUEST_LINE
        end
      end

      describe '#status_line' do
        it 'returns nil' do
          expect(@parser.status_line).to be_nil
        end
      end

      describe '#request?' do
        it 'returns a bool' do
          expect(@parser.request?).to be_an_instance_of TrueClass
        end

        it 'returns true' do
          expect(@parser.request?).to be_true
        end
      end

      describe '#response?' do
        it 'returns a bool' do
          expect(@parser.response?).to be_an_instance_of FalseClass
        end

        it 'returns false' do
          expect(@parser.response?).to be_false
        end
      end

      describe '#http_version' do
        it 'returns an array' do
          expect(@parser.http_version).to be_an_instance_of Array
        end

        it 'returns [1, 1]' do
          expect(@parser.http_version).to eql [1,1]
        end
      end

      describe '#major_http_version' do
        it 'returns an integer' do
          expect(@parser.major_http_version).to be_an_instance_of Fixnum
        end

        it 'returns 1' do
          expect(@parser.major_http_version).to eql 1
        end
      end

      describe '#minor_http_version' do
        it 'returns an integer' do
          expect(@parser.minor_http_version).to be_an_instance_of Fixnum
        end

        it 'returns 1' do
          expect(@parser.minor_http_version).to eql 1
        end
      end

      describe '#request_method' do
        it 'returns an string' do
          expect(@parser.request_method).to be_an_instance_of String
        end

        it 'returns GET' do
          expect(@parser.request_method).to eq 'GET'
        end
      end

      describe '#request_url' do
        it 'returns an string' do
          expect(@parser.request_url).to be_an_instance_of String
        end

        it 'returns /endpoint' do
          expect(@parser.request_url).to eq '/endpoint'
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

      describe '#uri' do
        it 'returns a URI' do
          expect(@parser.uri).to be_an_instance_of URI::Generic
        end
      end
    end

    context 'a response line has been parsed' do
      before(:each) do
        @parser.parse "HTTP/1.1 200 OK\r\n"
      end

      describe '#request_line' do
        it 'returns nil' do
          expect(@parser.request_line).to be_nil
        end
      end

      describe '#status_line' do
        it 'returns a string' do
          expect(@parser.status_line).to be_an_instance_of String
        end

        it 'returns a status line' do
          expect(@parser.status_line).to match Segregate::STATUS_LINE
        end
      end

      describe '#request?' do
        it 'returns a bool' do
          expect(@parser.request?).to be_an_instance_of FalseClass
        end

        it 'returns false' do
          expect(@parser.request?).to be_false
        end
      end

      describe '#response?' do
        it 'returns a bool' do
          expect(@parser.response?).to be_an_instance_of TrueClass
        end

        it 'returns true' do
          expect(@parser.response?).to be_true
        end
      end

      describe '#http_version' do
        it 'returns an array' do
          expect(@parser.http_version).to be_an_instance_of Array
        end

        it 'returns [1, 1]' do
          expect(@parser.http_version).to eql [1,1]
        end
      end

      describe '#major_http_version' do
        it 'returns an integer' do
          expect(@parser.major_http_version).to be_an_instance_of Fixnum
        end

        it 'returns 1' do
          expect(@parser.major_http_version).to eql 1
        end
      end

      describe '#minor_http_version' do
        it 'returns an integer' do
          expect(@parser.minor_http_version).to be_an_instance_of Fixnum
        end

        it 'returns 1' do
          expect(@parser.minor_http_version).to eql 1
        end
      end

      describe '#request_method' do
        it 'returns nil' do
          expect(@parser.request_method).to be_nil
        end
      end

      describe '#request_url' do
        it 'returns nil' do
          expect(@parser.request_url).to be_nil
        end
      end

      describe '#status_code' do
        it 'returns an integer' do
          expect(@parser.status_code).to be_an_instance_of Fixnum
        end

        it 'returns 200' do
          expect(@parser.status_code).to eql 200
        end
      end

      describe '#status_phrase' do
        it 'returns an string' do
          expect(@parser.status_phrase).to be_an_instance_of String
        end

        it 'returns OK' do
          expect(@parser.status_phrase).to eq 'OK'
        end
      end

      describe '#uri' do
        it 'returns nil' do
          expect(@parser.uri).to be_nil
        end
      end
    end
  end
end