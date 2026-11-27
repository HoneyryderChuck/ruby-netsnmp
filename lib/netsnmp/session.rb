# frozen_string_literal: true

module NETSNMP
  # Let's just remind that there is no session in snmp, this is just an abstraction.
  #
  class Session
    include Loggable

    # @rbs!
    #   interface _Transport
    #     def close: () -> void
    #
    #     def send: (String payload) -> String
    #   end
    #
    #   @transport: _Transport
    #   @proxy: bool?
    #   @version: 0 | 1 | 3
    #   @community: String?

    TIMEOUT = 2

    # @param [Hash] opts the options set
    #
    #: (?version: snmp_version, ?community: String, **untyped) -> void
    def initialize(version: 1, community: "public", **options)
      @version = case version
                 when Integer then version # assume the use know what he's doing
                 when /v?1/ then 0
                 when /v?2c?/ then 1
                 when /v?3/ then 3
                 else
                   raise "unsupported snmp version (#{version})"
                 end
      @community = community
      validate(**options)
      initialize_logger(**options)
    end

    # Closes the session
    #: -> void
    def close
      # if the transport came as an argument,
      # then let the outer realm care for its lifecycle
      @transport.close unless @proxy
    end

    # @param [Symbol] type the type of PDU (:get, :set, :getnext)
    # @param [Array<Hashes>] vars collection of options to generate varbinds (see {NETSMP::Varbind.new} for all the possible options)
    #
    # @return [NETSNMP::PDU] a pdu
    #
    #: (pdu_type, *untyped) -> PDU
    def build_pdu(type, *vars)
      PDU.build(type, version: @version, community: @community, varbinds: vars)
    end

    # send a pdu, receives a pdu
    #
    # @param [NETSNMP::PDU, #to_der] an encodable request pdu
    #
    # @return [NETSNMP::PDU] the response pdu
    #
    #: (PDU) -> PDU
    def send(pdu)
      log { "sending request..." }
      log(level: 2) { pdu.to_hex }
      encoded_request = pdu.to_der
      log { Hexdump.dump(encoded_request) }
      encoded_response = @transport.send(encoded_request)
      log { "received response" }
      log { Hexdump.dump(encoded_response) }
      response_pdu = PDU.decode(encoded_response)
      log(level: 2) { response_pdu.to_hex }
      response_pdu
    end

    private

    #: (?host: String?, ?port: Integer, ?proxy: _Transport, ?timeout: Integer, **untyped) -> void
    def validate(host: nil, port: 161, proxy: nil, timeout: TIMEOUT, **)
      if proxy
        @proxy = true
        @transport = proxy
      else
        raise "you must provide an hostname/ip under :host" unless host

        @transport = Transport.new(host, port.to_i, timeout: timeout)
      end
    end

    class Transport
      MAXPDUSIZE = 0xffff + 1 #: Integer

      # @rbs!
      #   @socket: UDPSocket
      #   @destaddr: String
      #   @timeout: Integer

      #: (String host, Integer port, timeout: Integer) -> void
      def initialize(host, port, timeout:)
        @socket = UDPSocket.new
        @destaddr = Socket.sockaddr_in(port, host)
        @timeout = timeout
      end

      #: -> void
      def close
        @socket.close
      end

      #: (String pdu_der) -> String
      def send(payload)
        write(payload)
        recv
      end

      SOCK_FLAGS = Socket.const_defined?(:MSG_DONTWAIT) ? Socket::MSG_DONTWAIT : 0 #: Integer

      if RUBY_ENGINE == "jruby"
        # @rbs skip
        def write(payload)
          perform_io do
            @socket.send(payload, SOCK_FLAGS, @destaddr)
          end
        end

        # @rbs skip
        def recv(bytesize = MAXPDUSIZE)
          perform_io do
            datagram, = @socket.recv_nonblock(bytesize, SOCK_FLAGS)
            datagram
          end
        end
      else
        #: (String data) -> void
        def write(payload)
          perform_io do
            @socket.sendmsg(payload, SOCK_FLAGS, @destaddr)
          end
        end

        #: (?Integer size) -> String
        def recv(bytesize = MAXPDUSIZE)
          perform_io do
            datagram, = @socket.recvmsg_nonblock(bytesize, SOCK_FLAGS)
            datagram
          end
        end
      end

      private

      #: [U] { () -> U } -> U
      def perform_io
        loop do
          begin
            return yield
          rescue IO::WaitReadable
            wait(:wait_readable)
          rescue IO::WaitWritable
            wait(:wait_writable)
          end
        end
      end

      #: (:wait_readable | :wait_writable) -> void
      def wait(mode)
        return if @socket.__send__(mode, @timeout)

        raise Timeout::Error, "Timeout after #{@timeout} seconds"
      end
    end
  end
end
