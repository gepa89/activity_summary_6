Redmine::Plugin.register :resumen_actividades do
  name 'Resumen de Actividades'
  author 'Enrique Paredes'
  description 'Plugin para generar resúmenes de actividades con filtrado dinámico'
  version '0.0.1'

  menu :top_menu, :activity_summary, { controller: 'activity_summary', action: 'index' }, 
       caption: 'Resumen de Actividades', if: Proc.new { User.current.admin? }
end
