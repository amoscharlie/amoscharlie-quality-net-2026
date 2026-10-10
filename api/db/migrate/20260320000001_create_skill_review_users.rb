# frozen_string_literal: true

class CreateSkillReviewUsers < ActiveRecord::Migration[7.0]
  def up
    execute "SET search_path TO skill_review, public"

    create_table :users do |t|
      t.string  :email,           null: false, limit: 255
      t.string  :password_digest, null: false
      t.string  :role,            null: false, default: 'user', limit: 20
      t.timestamps null: false
    end

    add_index :users, :email, unique: true, name: 'idx_skill_review_users_email'
  end

  def down
    drop_table :users
  end
end
