class AddSignatureToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :signature, :string, default: ""
  end
end
