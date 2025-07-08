class User < ApplicationRecord
  # Add this line
  has_many :user_files, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: true
  validate :password_complexity

  private

  def password_complexity
    # Return if password is blank
    return if password.blank?

    # Regexp for: 1 uppercase, 1 lowercase, 1 number
    return if password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/)

    # Add error if complexity is not met
    errors.add :password, "must include at least one uppercase, one lowercase, and one number"
  end
end
