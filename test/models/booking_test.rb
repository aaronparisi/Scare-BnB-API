# == Schema Information
#
# Table name: bookings
#
#  id          :bigint           not null, primary key
#  end_date    :date             not null
#  start_date  :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  guest_id    :bigint           not null
#  property_id :bigint           not null
#
# Indexes
#
#  index_bookings_on_guest_id     (guest_id)
#  index_bookings_on_property_id  (property_id)
#
# Foreign Keys
#
#  fk_rails_...  (guest_id => users.id)
#  fk_rails_...  (property_id => properties.id)
#
require "test_helper"

class BookingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
