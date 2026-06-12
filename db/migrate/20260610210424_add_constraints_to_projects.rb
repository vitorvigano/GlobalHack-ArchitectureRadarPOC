class AddConstraintsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :legacy_integration, :string
    add_column :projects, :architecture_style, :string
  end
end
