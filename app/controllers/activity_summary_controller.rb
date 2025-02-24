# Controlador principal para el Resumen de Actividades
# Se encarga de mostrar, filtrar y exportar la información de las entradas de tiempo (TimeEntries)
# relacionadas con proyectos, usuarios, peticiones (issues) y actividades (enumerations).
class ActivitySummaryController < ApplicationController
  before_action :require_admin
  before_action :retrieve_query, only: [:index, :filter, :export_csv, :export_to_excel]

  helper :queries
  include QueriesHelper

  # Método filter para realizar el filtrado de datos
  def filter
    @summary = @query.respond_to?(:results_scope) ? fetch_summary(@query.results_scope) : []
    
    # Genera los resúmenes por usuario solo si los datos están disponibles
    @user_summaries = generate_user_summaries(@summary)

    respond_to do |format|
      format.html do
        # Renderiza el partial sin el layout global
        render partial: 'planilla',
               locals: { summary: @summary, user_summaries: @user_summaries },
               layout: false
      end
    end
  rescue StandardError => e
    render json: { error: "Error al filtrar datos: #{e.message}" }, status: :unprocessable_entity
  end

  # Exporta la información filtrada a un archivo CSV
  def export_csv
    @summary = fetch_summary(@query.results_scope)
    
    # Verificar que el summary tiene datos
    if @summary.empty?
      flash[:error] = "No hay datos para exportar."
      redirect_to activity_summary_index_path
      return
    end
    
    # Pasar también los resúmenes de usuario
    csv_data = generate_csv(@summary, @user_summaries)
    
    send_data csv_data, filename: "reporte_redmine_#{Date.today}.csv", type: 'text/csv'
  rescue StandardError => e
    flash[:error] = "Error al exportar CSV: #{e.message}"
    redirect_to activity_summary_index_path
  end
  
  # Exporta la información filtrada a un archivo Excel (.xlsx)
  def export_to_excel
    @summary = fetch_summary(@query.results_scope)
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=activity_summary_#{Date.today}.xlsx"
      end
    end
  rescue StandardError => e
    flash[:error] = "Error al exportar a Excel: #{e.message}"
    redirect_to activity_summary_index_path
  end

  private

  # Inicializa o recupera la consulta (TimeEntryQuery) que define
  # el conjunto de resultados a mostrar o exportar.
  def retrieve_query
    @query = if params[:query_id].present?
               TimeEntryQuery.find_by(id: params[:query_id]) || TimeEntryQuery.new
             else
               TimeEntryQuery.new(name: 'Resumen de Actividades').tap do |q|
                 q.build_from_params(params) if params[:set_filter]
               end
             end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Consulta de tiempo no encontrada."
    redirect_to home_path
  end

  # Construye y ejecuta la consulta de datos de time_entries,
  # incluyendo proyectos, usuarios, issues, estados de issues y enumerations (actividades).
  def fetch_summary(scope)
    return [] unless scope.is_a?(ActiveRecord::Relation)

    begin
      results = scope
        .joins(:project, :user)
        .joins("JOIN enumerations ON enumerations.id = time_entries.activity_id AND enumerations.type = 'TimeEntryActivity'")
        .left_joins(:issue)
        .joins("LEFT JOIN issue_statuses ON issue_statuses.id = issues.status_id")
        .select(
          'projects.name AS project_name',
          'CONCAT(users.firstname, " ", users.lastname) AS user_name',
          'issues.subject AS petition',
          'time_entries.comments AS comment',
          'enumerations.name AS activity_name',
          'issue_statuses.name AS status',
          'time_entries.spent_on AS fecha',
          'time_entries.hours AS hours',
          'time_entries.activity_id AS activity_id'
        )
        .order('projects.name ASC, user_name ASC, petition ASC')
        .limit(500)
      results.to_a
    rescue StandardError
      []
    end
  end


  def generate_user_summaries(entries)
    return {} unless entries.is_a?(Array) && entries.any?
  
    entries.group_by(&:user_name).transform_values do |user_entries|
      total_hours = user_entries.sum(&:hours)
      activities = user_entries.group_by(&:activity_name).map do |activity_type, activity_entries|
        hours = activity_entries.sum(&:hours)
        percentage = total_hours.positive? ? ((hours / total_hours.to_f) * 100).round(2) : 0
        { activity_type: activity_type, hours: hours, percentage: "#{percentage}%" }
      end
      { total_hours: total_hours, activities: activities }
    end
  rescue StandardError
    {}
  end
  

  def generate_csv(summary, user_summaries)
    CSV.generate(headers: true) do |csv|
      # Encabezados para la planilla general
      csv << ["Proyecto", "Usuario", "Petición", "Comentario", "Actividad", "Estado", "Fecha", "Horas (Tiempo dedicado)"]
  
      # Agregar las entradas de la planilla general
      summary.each do |entry|
        csv << [
          entry.project_name,
          entry.user_name,
          entry.petition.presence || '-',
          entry.comment.presence || '-',
          entry.activity_name,
          entry.status,
          entry.fecha,
          entry.hours
        ]
      end
  
      # Espacio vacío para separar las secciones (si se requiere un cambio de sección)
      csv << []
      csv << ["Resumen de Usuario", "Actividad", "Horas", "% Relación"]
  
      # Incluir los resúmenes de usuario
      user_summaries.each do |user_name, user_summary|
        user_summary[:activities].each do |activity|
          csv << [
            user_name,
            activity[:activity_type],
            activity[:hours],
            activity[:percentage]
          ]
        end
      end
    end
  rescue StandardError => e
    # Si ocurre un error, simplemente retorna un string vacío
    ""
  end
  
end
