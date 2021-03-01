# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string
#  guest_rating    :decimal(10, 2)
#  host_rating     :decimal(10, 2)
#  image_url       :string
#  password_digest :string
#  session_token   :string
#  username        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
