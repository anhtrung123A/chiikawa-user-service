class AddLineUserIdAndRemoveSomeDeviseColumns < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :line_user_id, :string
    remove_column :users, :reset_password_token
    remove_column :users, :remember_created_at
    remove_column :users, :reset_password_sent_at
    add_index :users, :line_user_id,                unique: true
  end
end
