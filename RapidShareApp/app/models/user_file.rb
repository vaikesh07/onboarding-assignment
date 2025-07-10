class UserFile < ApplicationRecord
  belongs_to :user
  mount_uploader :file, FileUploader

  validates :name, length: { maximum: 255 }

  # This callback ensures file deletion is part of the main transaction
  before_destroy :delete_file_or_abort

  before_update :generate_share_token, if: -> { shareable? && share_token.blank? }
  before_update :clear_share_token, unless: :shareable?

  private

  def generate_share_token
    self.share_token = SecureRandom.hex(16)
  end

  def clear_share_token
    self.share_token = nil
  end

  def delete_file_or_abort
    begin
      # This CarrierWave method deletes the file from the disk
      self.file.remove!
    rescue => e
      # If there's any error, add an error to the object and, most importantly,
      # abort the entire destroy transaction.
      errors.add(:base, "Could not delete file: #{e.message}")
      throw :abort
    end
  end
end