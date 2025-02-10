RedmineApp::Application.routes.draw do
  # Agrupar rutas relacionadas con activity_summary
  scope 'activity_summary', controller: 'activity_summary' do
    get '/', action: 'index', as: 'activity_summary'
    get '/export_csv', action: 'export_csv', as: 'activity_summary_export_csv'
    post '/filter', action: 'filter', as: 'filter_activity_summary'
  end
end
