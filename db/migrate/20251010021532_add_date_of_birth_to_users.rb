class AddDateOfBirthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :dob, :date
  end
end
