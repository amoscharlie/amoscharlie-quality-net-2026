# Legacy users remain unbound and cannot authenticate until provisioned by an owner.
class BindUsersToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :tenant_id, :bigint
    add_index :users, :tenant_id
    add_foreign_key :users, :organizations, column: :tenant_id
  end
end
