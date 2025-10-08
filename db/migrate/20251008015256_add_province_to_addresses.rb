class AddProvinceToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :province, :string, null: false
  end
end
