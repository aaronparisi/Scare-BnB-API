# == Schema Information
#
# Table name: addresses
#
#  id          :bigint           not null, primary key
#  city        :string           not null
#  line_1      :string           not null
#  line_2      :string
#  state       :string           not null
#  zip         :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  property_id :bigint
#
# Indexes
#
#  index_addresses_on_property_id  (property_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
class Address < ApplicationRecord
  # @STATES = [
  #   "Alabama", "Alaska", "American Samoa", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", "Guam", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Minor Outlying Islands", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Northern Mariana Islands", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Puerto Rico", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "U.S. Virgin Islands", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
  # ]

  @STATES = ['North Takoma']

  validates :line_1, :city, :state, :zip, presence: true
  validates :state, inclusion: { in: @STATES }
  validates :zip, format: { with: /\A\d{6}-\d{4}|\A\d{6}\z/ }
  # validate :cityInState

  belongs_to :property, class_name: :Property, foreign_key: "property_id"

  def cityInState
    # todo this could be expanded to a more general 'address actually exists'
    return true
  end
end
