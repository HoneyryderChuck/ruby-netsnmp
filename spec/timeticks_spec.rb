# frozen_string_literal: true

require_relative "spec_helper"

# from https://ask.wireshark.org/questions/14002/how-to-decode-timeticks-hundreds-seconds-to-readable-date-time
class NETSNMPTimetickSpec < Minitest::Spec
  include NETSNMP

  subject { Timetick.new(1525917187) }

  describe "as an integer" do
    it { assert_equal(1525917188, (1 + subject).to_i) }
  end

  describe "as an embedded string" do
    it { assert_equal("Timeticks: (1525917187) 176 days, 14:39:31.87", subject.to_s) }
  end
end
