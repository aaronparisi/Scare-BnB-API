# == Schema Information
#
# Table name: ratings
#
#  id         :bigint           not null, primary key
#  rating     :integer          not null
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  guest_id   :bigint           not null
#  manager_id :bigint           not null
#
# Indexes
#
#  index_ratings_on_guest_id    (guest_id)
#  index_ratings_on_manager_id  (manager_id)
#
# Foreign Keys
#
#  fk_rails_...  (guest_id => users.id)
#  fk_rails_...  (manager_id => users.id)
#
class ManagerRating < Rating
end
