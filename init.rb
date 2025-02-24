require_dependency 'redmine'

# Intentar cargar las gemas necesarias para exportar a Excel
begin
  require 'axlsx_rails'
  require 'caxlsx'
rescue LoadError => e
  Rails.logger.error "Error al cargar gemas para exportación a Excel: #{e.message}"
end

Redmine::Plugin.register :activity_summary do
  name 'Resumen de Actividades'
  author 'IDESA'
  description 'Plugin para generar resúmenes de actividades con filtrado dinámico'
  version '0.0.1'
  url ''
  author_url ''

  # Compatibilidad con Redmine 6.0.3 o superior
  requires_redmine version_or_higher: '6.0.3'

  # Definir permisos para el módulo del proyecto
  project_module :activity_summary do
    permission :view_activity_summary,   { activity_summary: [:index] },  public: false
    permission :filter_activity_summary, { activity_summary: [:filter] }, public: false
    permission :export_activity_summary, { activity_summary: [:export_csv, :export_to_excel] }, public: false
  end

  # Agregar al menú superior solo para usuarios con permisos
  menu :top_menu, :activity_summary,
       { controller: 'activity_summary', action: 'index', only_path: true },
       caption: 'Resumen de Actividades',
       if: Proc.new { User.current.allowed_to?(:view_activity_summary, nil, global: true) }

  Rails.logger.info "🔹 Plugin 'Resumen de Actividades' cargado correctamente en Redmine."
end
