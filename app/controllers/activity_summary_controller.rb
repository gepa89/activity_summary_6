# Controlador principal para el Resumen de Actividades
# Se encarga de mostrar, filtrar y exportar la información de las entradas de tiempo (TimeEntries)
# relacionadas con proyectos, usuarios, peticiones (issues) y actividades (enumerations).
class ActivitySummaryController < ApplicationController
  before_action :require_admin
  before_action :retrieve_query, only: [:index, :filter, :export_csv, :export_to_excel]

  helper :queries
  include QueriesHelper

  def filter
    @summary = @query.respond_to?(:results_scope) ? fetch_summary(@query.results_scope) : []
    @user_summaries = generate_user_summaries(@summary)

    respond_to do |format|
      format.html do
        render partial: 'planilla',
               locals: { summary: @summary, user_summaries: @user_summaries },
               layout: false
      end
    end
  rescue StandardError => e
    render json: { error: "Error al filtrar datos: #{e.message}" }, status: :unprocessable_entity
  end

  def export_csv
    @summary = fetch_summary(@query.results_scope)
    
    if @summary.empty?
      flash[:error] = "No hay datos para exportar."
      redirect_to activity_summary_index_path
      return
    end
    
    csv_data = generate_csv(@summary, @user_summaries)
    
    send_data csv_data, filename: "reporte_redmine_#{Date.today}.csv", type: 'text/csv'
  rescue StandardError => e
    flash[:error] = "Error al exportar CSV: #{e.message}"
    redirect_to activity_summary_index_path
  end
  
  # Exporta la información filtrada a un archivo Excel (.xlsx)
  def export_to_excel
    @summary = fetch_summary(@query.results_scope)
    @user_summaries = generate_user_summaries(@summary)

    if @summary.empty?
      flash[:error] = "No hay datos para exportar."
      redirect_to activity_summary_index_path
      return
    end

    package = Axlsx::Package.new
    wb = package.workbook

    # Hoja principal con los datos detallados
    wb.add_worksheet(name: "Resumen de Actividad") do |sheet|
      sheet.add_row ["Proyecto", "Usuario", "Petición", "Comentario", "Actividad", "Estado", "Fecha", "Horas"]
      @summary.each do |entry|
        sheet.add_row [
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
    end

    wb.add_worksheet(name: "Resumen por Usuario") do |sheet|
      row_offset = 0 # Controla la posición vertical
    
      @user_summaries.each do |user_name, user_summary|
        # Espacio entre tablas (2 filas vacías)
        sheet.add_row []
        sheet.add_row []
    
        # Encabezado con el nombre del usuario
        sheet.add_row [user_name], style: wb.styles.add_style(sz: 14, b: true), height: 20
        row_offset += 1
    
        # Encabezados de la tabla
        sheet.add_row ["Actividad", "Horas", "% Relación"], style: wb.styles.add_style(b: true)
        row_offset += 1
    
        total_percentage = 0.0 # Inicializa el total del porcentaje
    
        # Agregar cada actividad del usuario
        user_summary[:activities].each do |activity|
          percentage = activity[:percentage].to_f # Convierte el porcentaje a número
          total_percentage += percentage # Acumula el porcentaje
    
          sheet.add_row [
            activity[:activity_type],
            activity[:hours],
            "#{percentage}%"
          ]
          row_offset += 1
        end
    
        # Fila total del usuario con total de porcentaje
        sheet.add_row [
          "Total:",
          user_summary[:total_hours],
          "#{total_percentage.round(2)}%"
        ], style: wb.styles.add_style(b: true)
    
        # Mueve la siguiente tabla 2 filas abajo para separación
        row_offset += 2
      end
    end
        

    # Enviar el archivo Excel al usuario
    send_data package.to_stream.read, 
              filename: "activity_summary_#{Date.today}.xlsx", 
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  rescue StandardError => e
    flash[:error] = "Error al exportar a Excel: #{e.message}"
    redirect_to activity_summary_index_path
  end

  private

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
          "DATE_FORMAT(time_entries.spent_on, '%d/%m/%Y') AS fecha",  # Formato DD/MM/YYYY
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
      total_hours = user_entries.sum(&:hours).to_i
      total_entries = user_entries.count
  
      activities = user_entries.group_by(&:activity_name).map do |activity_type, activity_entries|
        hours = activity_entries.sum(&:hours).to_i
        entry_count = activity_entries.count
        percentage = total_hours.positive? ? ((hours / total_hours.to_f) * 100).round(2) : 0
        { activity_type: activity_type, hours: "#{hours}/#{entry_count}", percentage: "#{percentage}%" }
      end
  
      { total_hours: "#{total_hours}/#{total_entries}", activities: activities }
    end
  rescue StandardError => e
    puts "Error en generate_user_summaries: #{e.message}"
    {}
  end
  
  def generate_csv(summary, user_summaries)
    CSV.generate(headers: true) do |csv|
      # ============================
      # 1️⃣ RESUMEN DE ACTIVIDAD GENERAL
      # ============================
      csv << ["Proyecto", "Usuario", "Petición", "Comentario", "Actividad", "Estado", "Fecha", "Horas"]
    
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
  
      # ============================
      # 2️⃣ SEPARACIÓN ENTRE TABLAS
      # ============================
      csv << [] # Primera fila vacía
      csv << [] # Segunda fila vacía
  
      # ============================
      # 3️⃣ RESUMEN POR USUARIO
      # ============================
      user_summaries.each do |user_name, user_summary|
        csv << [user_name] # Encabezado con el nombre del usuario
        csv << ["Actividad", "Horas", "% Relación"] # Encabezados de la tabla
  
        total_percentage = 0.0 # Inicializa el total de porcentaje para cada usuario
  
        # Agregar cada actividad del usuario
        user_summary[:activities].each do |activity|
          percentage = activity[:percentage].to_f # Convierte el porcentaje a número
          total_percentage += percentage # Acumula el porcentaje
  
          csv << [
            activity[:activity_type],
            activity[:hours],
            "#{percentage}%"
          ]
        end
  
        # Fila total del usuario con total de porcentaje
        csv << [
          "Total:",
          user_summary[:total_hours],
          "#{total_percentage.round(2)}%"
        ]
  
        # ============================
        # 4️⃣ ESPACIADO ENTRE USUARIOS
        # ============================
        csv << [] # Primera fila vacía de separación
        csv << [] # Segunda fila vacía de separación
      end
    end
  rescue StandardError => e
    ""
  end
  
end
