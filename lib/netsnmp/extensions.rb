# frozen_string_literal: true

module NETSNMP
  module ASNExtensions
    ASN_COLORS = {
      OpenSSL::ASN1::Sequence => 34, # blue
      OpenSSL::ASN1::OctetString => 32, # green
      OpenSSL::ASN1::Integer => 33, # yellow
      OpenSSL::ASN1::ObjectId => 35, # magenta
      OpenSSL::ASN1::ASN1Data => 36 # cyan
    }.freeze #: Hash[singleton(OpenSSL::ASN1::ASN1Data), Integer]

    # basic types
    ASN_COLORS.each_key do |klass|
      refine(klass) do
        #: -> String
        # @rbs skip
        def to_hex
          "#{colorize_hex} (#{value.to_s.inspect})"
        end
      end
    end

    # composite types
    # @rbs skip
    refine(OpenSSL::ASN1::Sequence) do
      #: -> String
      def to_hex
        values = value.map(&:to_der).join
        hex_values = value.map(&:to_hex).map { |s| s.gsub(/(\t+)/) { "\t#{Regexp.last_match(1)}" } }.map { |s| "\n\t#{s}" }.join
        der = to_der
        der = der.sub(values, "")

        "#{colorize_hex(der)}#{hex_values}"
      end
    end

    # @rbs skip
    refine(OpenSSL::ASN1::ASN1Data) do
      attr_reader :label #: Symbol | String

      #: (Symbol | String) -> self
      def with_label(label)
        @label = label
        self
      end

      #: -> String
      def to_hex
        case value
        when Array
          values = value.map(&:to_der).join
          hex_values = value.map(&:to_hex)
                            .map { |s| s.gsub(/(\t+)/) { "\t#{Regexp.last_match(1)}" } }
                            .map { |s| "\n\t#{s}" }.join
          der = to_der
          der = der.sub(values, "")
        else
          der = to_der
          hex_values = nil
        end

        "#{colorize_hex(der)}#{hex_values}"
      end

      private

      #: (?String) -> String
      def colorize_hex(der = to_der)
        hex = Hexdump.dump(der, separator: " ")
        lbl = @label || self.class.name.split("::").last
        "#{lbl}: \e[#{ASN_COLORS[self.class]}m#{hex}\e[0m"
      end
    end
  end
end
