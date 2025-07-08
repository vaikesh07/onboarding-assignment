class UserFile < ApplicationRecord
  belongs_to :user
  mount_uploader :file, FileUploader # This is the key line for CarrierWave

  # Add this validation
  validates :name, length: { maximum: 255 }, allow_blank: true

  # Add the same sharing logic as before
  before_update :generate_share_token, if: -> { shareable? && share_token.blank? }
  before_update :clear_share_token, unless: :shareable?

  private

  def generate_share_token
    self.share_token = SecureRandom.hex(16)
  end

  def clear_share_token
    self.share_token = nil
  end
end
