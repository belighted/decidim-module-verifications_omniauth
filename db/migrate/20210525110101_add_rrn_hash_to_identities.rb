# frozen_string_literal: true

class AddRrnHashToIdentities < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_identities, :rrn_hash, :string
  end
end
