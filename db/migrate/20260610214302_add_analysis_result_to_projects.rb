class AddAnalysisResultToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :analysis_result, :text
  end
end
