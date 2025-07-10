class User < ApplicationRecord
  has_secure_password

  has_many :user_files, dependent: :destroy

  validates :username, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  validate :password_complexity, if: -> { new_record? || !password.nil? }

  private

  def password_complexity
    return if password.blank? || password =~ /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/

    errors.add :password, 'must include at least one uppercase letter, one lowercase letter, and one number'
  end
end