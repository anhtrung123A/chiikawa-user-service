class AddIsDefaultAddressToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :is_default_address, :boolean, null: false, default: false
    add_column :addresses, :country, :string, null: false
  end
end
