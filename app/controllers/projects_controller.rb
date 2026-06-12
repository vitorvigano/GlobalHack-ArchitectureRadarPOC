class ProjectsController < ApplicationController
  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @project = Project.find(params[:id])
    if @project.analysis_result.present?
      @analysis = @project.analysis_result
    else
      @analysis = ::ArchitectureAnalysisService.new(@project).analyze
      @project.update!(analysis_result: @analysis) if @analysis
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :domain, :subdomain, :expected_users,
                                    :expected_rps, :growth_rate, :traffic_pattern,
                                    :criticality, :team_size, :team_experience,
                                    :budget, :legacy_integration, :architecture_style,
                                    concerns: [])
  end
end
