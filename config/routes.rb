RedmineApp::Application.routes.draw do
  resources :activity_summary, only: [:index] do
    collection do
      get :export_csv
      get :export_to_excel
      get :filter  # Acción para filtrar por AJAX
    end
  end
end
