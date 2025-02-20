class ActivitySummaryController < ApplicationController
  before_action :require_admin
  before_action :retrieve_query, only: [:index, :filter, :export_csv, :export_to_excel]

  helper :queries # 🔹 Incluir el helper de Queries
  include QueriesHelper # 🔹 Incluir métodos de QueriesHelper

  def index
    # 🔹 Se obtienen los datos filtrados por Redmine
    @summary = fetch_summary(@query.results_scope)
    @user_summaries = generate_user_summaries(@summary)
  end

  def filter
    @summary = fetch_summary(@query.results_scope)
    @user_summaries = generate_user_summaries(@summary)

    render partial: 'planilla', locals: { summary: @summary, user_summaries: @user_summaries }
  end

  def export_csv
    @summary = fetch_summary(@query.results_scope)
    @user_summaries = generate_user_summaries(@summary)

    csv_data = generate_csv(@summary, @user_summaries)
    send_data csv_data, filename: "reporte_redmine_#{Date.today}.csv", type: 'text/csv'
  end

  def export_to_excel
    @summary = fetch_summary(@query.results_scope)
    @user_summaries = generate_user_summaries(@summary)

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=activity_summary_#{Date.today}.xlsx"
      end
    end
  end

  private

  # 🔹 Cargar la Query de Redmine para aplicar los filtros
  def retrieve_query
    if params[:query_id].present?
      @query = TimeEntryQuery.find(params[:query_id])
    else
      @query = TimeEntryQuery.new(name: 'Resumen de Actividades')
      @query.build_from_params(params) if params[:set_filter]
    end
  end

  # 🔹 Consultar registros con los filtros aplicados
  def fetch_summary(scope)
    scope
      .joins(:project, :user, :activity)
      .left_joins(:issue)
      .left_joins("LEFT JOIN issue_statuses ON issue_statuses.id = issues.status_id")
      .select(
        'projects.name AS project_name',
        'issues.subject AS petition',
        'CONCAT(users.firstname, " ", users.lastname) AS user_name',
        'time_entries.comments AS comment',
        'enumerations.name AS activity_name',
        'issue_statuses.name AS status',
        'time_entries.spent_on AS fecha',
        'time_entries.hours AS hours'
      )
      .order('projects.name ASC, time_entries.spent_on DESC')
      .limit(500) # Evita sobrecarga de datos
  end

  # 🔹 Generar resúmenes por usuario y actividad
  def generate_user_summaries(entries)
    return {} unless entries.is_a?(Array) && entries.any?

    entries.group_by { |entry| entry.user_name.to_s }.transform_values do |user_entries|
      total_hours = user_entries.sum(&:hours)

      activities = user_entries.group_by(&:activity_name).map do |activity_type, activity_entries|
        hours = activity_entries.sum(&:hours)
        percentage = total_hours.positive? ? ((hours / total_hours.to_f) * 100).round(2) : 0
        { activity_type: activity_type, hours: hours, percentage: "#{percentage}%" }
      end

      { total_hours: total_hours, activities: activities }
    end
  end

  # 🔹 Generar datos CSV para la exportación
  def generate_csv(summary, user_summaries)
    CSV.generate(headers: false) do |csv|
      user_summaries.each_with_index do |(user, summary), index|
        csv << [] if index.positive?
        csv << ["Resumen de #{user}", "", "", "", "", "", "", "", ""]
        csv << ["Tipo de Actividad", "Horas", "% Relación", "", "", "", "", "", ""]

        total_hours = summary[:total_hours].to_f
        total_percentage = 0.0

        summary[:activities].each do |activity|
          activity_hours = activity[:hours].to_f
          percentage = total_hours.positive? ? ((activity_hours / total_hours) * 100).round(2) : 0
          total_percentage += percentage

          csv << [activity[:activity_type], activity[:hours], "#{percentage}%", "", "", "", "", "", ""]
        end

        csv << ["Total", summary[:total_hours], "#{total_percentage.round(2)}%", "", "", "", "", "", ""]
      end

      csv << ["Planilla de tiempo dedicado", "", "", "", "", "", "", "", ""]
      csv << ["Proyecto", "Petición", "Usuario", "Comentario", "Actividad", "Estado", "Fecha", "Horas"]

      summary.each do |entry|
        csv << [
          entry.project_name,
          entry.petition,
          entry.user_name,
          entry.comment,
          entry.activity_name,
          entry.status,
          entry.fecha,
          entry.hours
        ]
      end
    end
  end
end
