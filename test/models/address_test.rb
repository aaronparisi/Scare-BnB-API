# == Schema Information
#
# Table name: addresses
#
#  id         :bigint           not null, primary key
#  city       :string           not null
#  line_1     :string           not null
#  line_2     :string
#  state      :string           not null
#  zip        :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class AddressTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
