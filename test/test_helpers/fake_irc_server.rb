require "socket"
require "openssl"

class FakeIrcServer
  def self.ssl_context
    @ssl_context ||= begin
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=127.0.0.1")
      cert.public_key = key.public_key
      cert.not_before = Time.now - 60
      cert.not_after = Time.now + 3600
      cert.sign(key, OpenSSL::Digest.new("SHA256"))

      context = OpenSSL::SSL::SSLContext.new
      context.cert = cert
      context.key = key
      context
    end
  end

  attr_reader :lines

  def initialize(ssl: false, welcome: true)
    @tcp_server = TCPServer.new("127.0.0.1", 0)
    @ssl = ssl
    @welcome = welcome
    @lines = Queue.new
    @raw_connection = nil
    @connection = nil
  end

  def port
    @tcp_server.addr[1]
  end

  def config
    { address: "127.0.0.1", port: port, ssl: @ssl, ssl_verify: false, nickname: "tester" }
  end

  def start
    @thread = Thread.new do
      @raw_connection = @tcp_server.accept
      @connection = @ssl ? accept_ssl(@raw_connection) : @raw_connection
      read_lines
    end
    self
  end

  def send_line(line)
    @connection.write("#{line}\r\n")
  end

  def wait_for_line(pattern, timeout: 2)
    deadline = Time.now + timeout
    while Time.now < deadline
      line = @lines.pop(timeout: 0.05)
      return line if line&.match?(pattern)
    end
    nil
  end

  def drop
    @raw_connection.close
  end

  def close
    @raw_connection.close if @raw_connection && !@raw_connection.closed?
    @tcp_server.close unless @tcp_server.closed?
    @thread&.kill
  end

  private

  def read_lines
    while (line = @connection.gets)
      line = line.chomp
      @lines << line
      send_line(":fake.server 001 tester :Welcome") if @welcome && line.start_with?("USER ")
    end
  rescue IOError, SystemCallError, OpenSSL::SSL::SSLError
    nil
  end

  def accept_ssl(tcp)
    ssl = OpenSSL::SSL::SSLSocket.new(tcp, self.class.ssl_context)
    ssl.sync_close = true
    ssl.accept
    ssl
  end
end
