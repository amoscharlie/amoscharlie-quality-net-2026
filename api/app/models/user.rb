# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :organization, foreign_key: :tenant_id, optional: true

  has_secure_password

  ROLES = %w[admin user].freeze

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
