class AddMagnitudeToProjects < ActiveRecord::Migration[8.1]
  def change
    change_column :projects, :expected_users, :string
    add_column :projects, :traffic_pattern, :string
    add_column :projects, :criticality, :string
  end
end
