# == Schema Information
#
# Table name: properties
#
#  id           :bigint           not null, primary key
#  baths        :integer          not null
#  beds         :integer          not null
#  description  :text             not null
#  nightly_rate :decimal(10, 2)   not null
#  pets         :boolean          not null
#  smoking      :boolean          not null
#  square_feet  :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  address_id   :bigint           not null
#  manager_id   :bigint           not null
#
# Indexes
#
#  index_properties_on_address_id  (address_id)
#  index_properties_on_manager_id  (manager_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (manager_id => users.id)
#
require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
