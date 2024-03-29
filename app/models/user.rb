# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string
#  password_digest :string
#  session_token   :string
#  username        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  include Rails.application.routes.url_helpers

  has_secure_password

  validates :username, :email, presence: true, uniqueness: true
  validates :password_digest, :session_token, presence: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  after_initialize :ensure_session_token

  has_many :managed_properties, class_name: :Property, foreign_key: "manager_id", dependent: :destroy

  # has_many :managed_bookings, through: :Property, source: :bookings  ? necessary?

  has_many :bookings, class_name: :Booking, foreign_key: "guest_id", dependent: :destroy
  has_many :booked_properties, through: :bookings, source: :property

  has_many :received_manager_ratings, 
    class_name: :ManagerRating, 
    foreign_key: :manager_id, 
    dependent: :destroy
  has_many :made_manager_ratings, 
    class_name: :ManagerRating, 
    foreign_key: :guest_id, 
    dependent: :destroy

  has_many :received_guest_ratings, 
    class_name: :GuestRating, 
    foreign_key: :guest_id,
    dependent: :destroy
  has_many :made_guest_ratings, 
    class_name: :GuestRating, 
    foreign_key: :manager_id, 
    dependent: :destroy

  has_one_attached :avatar

  before_destroy :purge_avatar

  def guest_rating
    return self.received_guest_ratings.average(:rating) || 0
  end
  
  def manager_rating
    return self.received_manager_ratings.average(:rating) || 0
  end
  
  def self.find_by_credentials(username, password)
    user = User.find_by(username: username)
    return nil unless user
    user.is_password?(password) ? user : nil
  end

  def password=(password)
    # Set temporary instance variable so that we can validate length
    @password = password
    # Create a password_digest so that we do not have to store the plain-text password in our DB
    self.password_digest = BCrypt::Password.create(password)
  end

  def is_password?(password)
    # Use BCrypt's built-in method for checking if the password provided is the user's password
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def ensure_session_token
    # Generate the initial session_token so that we pass the validation
    # This method runs right after the model is initialized, before any validations are run
    self.session_token ||= SecureRandom.urlsafe_base64
  end

  def reset_session_token!
    # When a user logs out, we want to scramble their session_token so that bad people cannot use the old one
    self.session_token = SecureRandom.urlsafe_base64
    self.save
    self.session_token
  end

  def avatar_url
    self.avatar.attached? ? {url: url_for(self.avatar), id: self.avatar.signed_id} : nil
  end

  def purge_avatar
    puts "deleting avatar for #{self.username}"
    self.avatar.purge_later
  end
end
