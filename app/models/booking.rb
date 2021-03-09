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
class Booking < ApplicationRecord
  validates :start_date, :end_date, presence: true
  validate :ensure_available
  validate :end_not_before_start
  
  belongs_to :property
  belongs_to :guest, class_name: :User, foreign_key: "guest_id"

  def ensure_available
    if Property.find(self.property_id).is_available?(self.start_date, self.end_date)
      self.errors.add :property_id, " - This property is not available for some / all of the time you selected"
    end
  end

  def end_not_before_start
    if self.start_date >= self.end_date
      self.errors.add :end_date, "cannot be before start date"
    end
  end
  
  
  def collides?(startDate, endDate)
    # returns true if this booking's date range crosses over the given range at all
    return (
      (self.start_date === startDate) || 
      (self.end_date === endDate) || 
      (self.start_date.between?(startDate, endDate)) || 
      (self.end_date.between?(startDate, endDate))
    )
  end
  
end
