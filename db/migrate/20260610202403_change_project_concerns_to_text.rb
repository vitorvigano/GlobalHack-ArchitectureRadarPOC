class ChangeProjectConcernsToText < ActiveRecord::Migration[8.1]
  def change
    change_column :projects, :concerns, :text
  end
end
