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
class Property < ApplicationRecord
  validates :baths, :beds, :description, :nightly_rate, :square_feet, presence: true
  validates :pets, :smoking, inclusion: { in: [true, false] }

  belongs_to :address
  belongs_to :manager, class_name: :User, foreign_key: "manager_id"

  has_many :bookings, class_name: :Booking, foreign_key: "property_id"
  has_many :guests, through: :bookings, source: :guest
end
