# frozen_string_literal: true

class AllowNullEmailInDecidimUsers < ActiveRecord::Migration[5.2]
  def change
    change_column :decidim_users, :email, :string, null: true
  end
end
