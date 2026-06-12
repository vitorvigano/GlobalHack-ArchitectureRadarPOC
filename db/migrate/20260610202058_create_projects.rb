class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.string :domain
      t.string :subdomain
      t.string :concerns
      t.integer :expected_users
      t.integer :expected_rps
      t.string :growth_rate
      t.string :team_size
      t.string :team_experience
      t.string :budget

      t.timestamps
    end
  end
end
