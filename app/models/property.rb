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
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  manager_id   :bigint           not null
#
# Indexes
#
#  index_properties_on_manager_id  (manager_id)
#
# Foreign Keys
#
#  fk_rails_...  (manager_id => users.id)
#
class Property < ApplicationRecord
  validates :baths, :beds, :description, :nightly_rate, :square_feet, :title, presence: true
  validates :pets, :smoking, inclusion: { in: [true, false] }

  belongs_to :manager, class_name: :User, foreign_key: "manager_id"

  has_many :bookings, class_name: :Booking, foreign_key: "property_id", dependent: :destroy
  has_many :guests, through: :bookings, source: :guest

  has_one :address, class_name: :Address, foreign_key: "property_id", dependent: :destroy  # ? is this appropriate here?

  has_many_attached :images

  def is_available?(startDate, endDate)
    # returns true if property has no conflicting bookings,
    # else, false
    ret = self.bookings
      .map { |booking| booking.collides?(startDate, endDate) }
      .none? { |bookingBool| bookingBool }
    return ret;
  end

  def image_urls
    # returns an array of urls
    return self.images.reverse.map { |img| img.representation({}).processed.url }
  end
  
end
