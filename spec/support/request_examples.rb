# frozen_string_literal: true

module RequestExamples
  include Minitest::Spec::DSL

  def self.included(base)
    base.class_eval do
      let(:device_options) do
        {
          host: SNMPHOST,
          port: SNMPPORT
        }
      end
      let(:protocol_options) { {} }
      let(:extra_options) { {} }
      let(:options) { protocol_options.merge(device_options).merge(extra_options) }

      subject { NETSNMP::Client.new(**options) }

      describe "#get" do
        let(:result) { subject.get(oid: get_oid) }
        it "fetches the varbinds for a given oid" do
          assert_equal(get_result, result)
        end
        describe "with multiple oids" do
          let(:result) { subject.get({ oid: get_oid }, oid: next_oid) }
          it "returns the results for both" do
            assert_instance_of(Array, result)
            assert_includes(result, get_result)
            assert_includes(result, next_result)
          end
        end
      end

      describe "#get_next" do
        let(:varbind) { subject.get_next(oid: get_oid) }
        it "fetches the varbinds for the next oid" do
          oid, result = varbind
          assert result.start_with?(next_result)
          assert_equal(next_oid, oid)
        end
      end

      describe "#walk" do
        let(:result) { subject.walk(oid: walk_oid) }
        it "fetches the varbinds for the next oid" do
          result.each do |oid, val|
            match = walk_result[oid]
            case match
            when String
              assert_equal(match, val.to_s)
            when Regexp
              assert_match(match, val.to_s)
            else
              next
            end
          end
        end
      end
    end
  end
end
