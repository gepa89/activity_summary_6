class ActivitySummaryController < ApplicationController
  unloadable
  before_action :require_admin

  def index
    @projects = Project.all
    @tasks = Issue.all
    @users = User.all
  end

  def filter
    filters = params.permit(:project_id, :issue_id, :user_id, :start_date, :end_date)
    @summary = fetch_summary(filters)
    @user_summaries = generate_user_summaries(@summary)

    render partial: 'planilla', locals: { summary: @summary, user_summaries: @user_summaries }
  end

  def export_csv
    filters = params.permit(:project_id, :issue_id, :user_id, :start_date, :end_date)
    @summary = fetch_summary(filters)
    @user_summaries = generate_user_summaries(@summary)

    csv_data = generate_csv(@summary, @user_summaries)
    send_data csv_data, filename: "reporte_redmine_#{Date.today}.csv"
  end

  def export_to_excel
    filters = params.permit(:project_id, :issue_id, :user_id, :start_date, :end_date)
    @summary = fetch_summary(filters)
    @user_summaries = generate_user_summaries(@summary)

    respond_to do |format|
      format.xlsx { response.headers['Content-Disposition'] = "attachment; filename=activity_summary.xlsx" }
    end
  end

  private

  def build_conditions(filters)
    conditions = []
    values = {}

    filters.each do |key, value|
      next if value.blank? || value == 'all'
      case key
      when 'project_id', 'user_id', 'issue_id'
        conditions << "time_entries.#{key} = :#{key}"
        values[key.to_sym] = value
      when 'start_date'
        conditions << "time_entries.spent_on >= :start_date"
        values[:start_date] = value
      when 'end_date'
        conditions << "time_entries.spent_on <= :end_date"
        values[:end_date] = value
      end
    end

    [conditions.join(' AND '), values]
  end

  def fetch_summary(filters)
    conditions, values = build_conditions(filters)

    TimeEntry
      .joins("INNER JOIN projects ON projects.id = time_entries.project_id")
      .joins("INNER JOIN users ON users.id = time_entries.user_id")
      .joins("INNER JOIN enumerations ON enumerations.id = time_entries.activity_id")
      .left_joins(:issue)
      .joins("LEFT JOIN issue_statuses ON issue_statuses.id = time_entries.issue_id")
      .select('projects.name AS project_name,
               issues.subject AS petition,
               CONCAT(users.firstname, " ", users.lastname) AS user_name,
               time_entries.comments AS comment,
               enumerations.name AS activity_name,
               issue_statuses.name AS status,
               time_entries.spent_on AS fecha,
               time_entries.hours AS hours')
      .where(conditions, values)
      .order('projects.name ASC, time_entries.spent_on DESC')
  end

  def generate_user_summaries(entries)
    entries.group_by(&:user_name).each_with_object({}) do |(user, user_entries), summaries|
      total_hours = user_entries.sum(&:hours)

      activities = user_entries.group_by(&:activity_name).map do |activity_type, activity_entries|
        hours = activity_entries.sum(&:hours)
        percentage = total_hours.positive? ? ((hours / total_hours.to_f) * 100).round(2) : 0

        { activity_type: activity_type, hours: hours, percentage: "#{percentage}%" }
      end

      summaries[user] = { total_hours: total_hours, activities: activities }
    end
  end

  def generate_csv(summary, user_summaries)
    CSV.generate(headers: false) do |csv|
      user_summaries.each_with_index do |(user, summary), index|
        csv << [] if index > 0
        csv << []
        csv << ["", "", "", "", "", "", "", "", ""]
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

      5.times { csv << [] }

      csv << ["Planilla de tiempo dedicado", "", "", "", "", "", "", "", ""]
      csv << ["Proyecto", "Petición", "Usuario", "", "Comentario", "Actividad", "Estado", "", "Fecha", "Horas"]

      summary.each do |entry|
        csv << [
          entry.project_name,
          entry.petition,
          entry.user_name,
          "",
          entry.comment,
          entry.activity_name,
          entry.status,
          "",
          entry.fecha,
          entry.hours
        ]
      end
    end
  end
end
