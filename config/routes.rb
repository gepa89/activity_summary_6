RedmineApp::Application.routes.draw do
  # Definir rutas optimizadas para `activity_summary`
  resources :activity_summary, only: [:index], as: 'activity_summary' do
    collection do
      get :export_csv
      get :export_to_excel  # Se añadió exportación a Excel
      post :filter
    end
  end
end
