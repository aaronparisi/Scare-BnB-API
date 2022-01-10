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
  include Rails.application.routes.url_helpers

  validates :baths, :beds, :description, :nightly_rate, :square_feet, :title, presence: true
  validates :pets, :smoking, inclusion: { in: [true, false] }

  belongs_to :manager, class_name: :User, foreign_key: "manager_id"

  has_many :bookings, class_name: :Booking, foreign_key: "property_id", dependent: :destroy
  has_many :guests, through: :bookings, source: :guest

  has_one :address, class_name: :Address, foreign_key: "property_id", dependent: :destroy  # ? is this appropriate here?

  has_many_attached :images

  before_destroy :purge_images

  def is_available?(startDate, endDate)
    # returns true if property has no conflicting bookings,
    # else, false
    ret = self.bookings
      .map { |booking| booking.collides?(startDate, endDate) }
      .none? { |bookingBool| bookingBool }
    return ret;
  end

  def image_url(img)
    return {
      # url: Rails.application.routes.url_helpers.rails_blob_path(img, only_path: true),
      url: url_for(img),
      id: img.signed_id
    }
  end

  def image_urls
    # returns an array of objects consisting of the images url and the signed id
    ret = self.images.map { |img| self.image_url(img) }
  end

  def purge_images
    # puts "deleting #{self.images.count} #{ActionController::Base.helpers.pluralize(self.images.count, "image")} for #{self.title}"
    puts "deleting images for #{self.title}"
    self.images.purge_later
  end
  
end
