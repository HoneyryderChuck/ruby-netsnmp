# frozen_string_literal: true

module NETSNMP
  module Encryption
    using XorExtensions

    class DES
      # @rbs!
      #   @priv_key: String
      #   @local: Integer

      #: (String priv_key, ?local: Integer) -> void
      def initialize(priv_key, local: 0)
        @priv_key = priv_key
        @local = local
      end

      #: (String decrypted_data, engine_boots: Integer, **untyped) -> [String, String]
      def encrypt(decrypted_data, engine_boots:, **)
        cipher = OpenSSL::Cipher.new("des-cbc")

        iv, salt = generate_encryption_key(engine_boots)

        cipher.encrypt
        cipher.iv = iv
        cipher.key = des_key

        if (diff = decrypted_data.length % 8) != 0
          decrypted_data << ("\x00" * (8 - diff))
        end

        encrypted_data = cipher.update(decrypted_data) + cipher.final
        [encrypted_data, salt]
      end

      #: (String encrypted_data, salt: String, **untyped) -> String
      def decrypt(encrypted_data, salt:, **)
        raise Error, "invalid priv salt received" unless (salt.length % 8).zero?
        raise Error, "invalid encrypted PDU received" unless (encrypted_data.length % 8).zero?

        cipher = OpenSSL::Cipher.new("des-cbc")
        cipher.padding = 0

        iv = generate_decryption_key(salt)

        cipher.decrypt
        cipher.key = des_key
        cipher.iv = iv
        decrypted_data = cipher.update(encrypted_data) + cipher.final

        hlen, bodylen = OpenSSL::ASN1.traverse(decrypted_data) { |_, _, x, y, *| break x, y } #: [Integer, Integer]
        decrypted_data.byteslice(0, hlen + bodylen) || "".b
      end

      private

      # 8.1.1.1
      #: (Integer boots) -> [String, String]
      def generate_encryption_key(boots)
        pre_iv = @priv_key[8, 8] #: String
        salt = [0xff & (boots >> 24),
                0xff & (boots >> 16),
                0xff & (boots >> 8),
                0xff &  boots,
                0xff & (@local >> 24),
                0xff & (@local >> 16),
                0xff & (@local >> 8),
                0xff &  @local].pack("c*")
        @local = @local == 0xffffffff ? 0 : @local + 1

        iv = pre_iv.xor(salt)
        [iv, salt]
      end

      #: (String salt) -> String
      def generate_decryption_key(salt)
        pre_iv = @priv_key[8, 8] #: String
        pre_iv.xor(salt)
      end

      #: -> String
      def des_key
        @priv_key[0, 8] || "".b
      end
    end
  end
end
