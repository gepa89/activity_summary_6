
# 📄 README.md - Plugin de Resumen de Actividades para Redmine 4.0.4

---

## 📊 **Descripción**

Este plugin para **Redmine 4.0.4** permite generar resúmenes de actividades de los usuarios, incluyendo el detalle del tiempo dedicado por proyecto, tareas y actividades. Además, permite exportar los datos en formato **CSV**.

---

## ⚙️ **Requisitos del Sistema**

- **Redmine:** 4.0.4
- **Ruby:** 2.5.x o superior
- **Rails:** 5.2.3
- **Base de datos compatible:** MySQL, PostgreSQL o SQLite

---

## 🚀 **Instalación**

1. **Clonar el repositorio en el directorio de plugins de Redmine:**

   ```bash
   cd /path/to/redmine/plugins
   git clone <URL_DEL_REPOSITORIO> activity_summary
   ```

2. **Instalar las gemas necesarias:**

   Abre una terminal en el contenedor o servidor donde se encuentra Redmine:

   ```bash
   bundle install
   ```

   **Dependencias adicionales:**  
   Asegúrate de que las siguientes gemas estén incluidas en el `Gemfile` de Redmine:

   ```ruby
   gem 'csv'           # Para la exportación de archivos CSV
   ```

3. **Reiniciar Redmine:**

   Si estás usando Passenger o Docker:

   ```bash
   touch /path/to/redmine/tmp/restart.txt
   ```

   O si usas otro servidor web:

   ```bash
   sudo systemctl restart apache2
   # o
   sudo systemctl restart nginx
   ```

   En Docker:

   ```bash
   docker-compose restart redmine
   ```

4. **Verificar la instalación:**

   Inicia sesión en Redmine y dirígete a la pestaña **"Resumen de Actividades"** en el menú principal.

---

## 📋 **Uso del Plugin**

1. **Filtrado de Actividades:**
   - Filtra por proyecto, tarea, usuario y rango de fechas.
   - Usa los botones **"Mes Anterior"** y **"Mes Siguiente"** para navegar fácilmente por períodos de tiempo.

2. **Exportación de Datos:**
   - Haz clic en el botón **"Exportar CSV"** para descargar un informe con el resumen de actividades y la planilla de tiempo dedicado.

---

## 🗃️ **Rutas Disponibles**

| Método | Ruta                                | Acción                      |
|:------:|:------------------------------------|:----------------------------|
| GET    | `/activity_summary`                 | Vista principal del plugin |
| POST   | `/activity_summary/filter`          | Filtro de actividades      |
| GET    | `/activity_summary/export_csv`      | Exportación CSV            |

---

## 🛠️ **Estructura del Plugin**

```
activity_summary/
├── app/
│   ├── controllers/
│   │   └── activity_summary_controller.rb
│   ├── views/
│   │   └── activity_summary/
│   │       ├── index.html.erb
│   │       └── _planilla.html.erb
├── assets/
│   ├── stylesheets/
│   │   └── activity_summary.css
│   └── javascripts/
│       └── activity_summary.js
├── config/
│   └── routes.rb
├── init.rb
└── README.md
```

---

## 📝 **Consideraciones Importantes**

- **Roles y Permisos:** Solo los administradores pueden acceder a este plugin por defecto. Para cambiar esto, ajusta el `before_action :require_admin` en el controlador.
- **Zona Horaria:** Verifica que la zona horaria de Redmine esté configurada correctamente para evitar desajustes en las fechas de los reportes.
- **Compatibilidad:** Este plugin ha sido probado únicamente en Redmine 4.0.4.

---

## ❓ **Soporte**

Para reportar problemas o sugerencias, por favor abre un **issue** en el repositorio del plugin o contacta al equipo de desarrollo.

---

## 📜 **Licencia**

Este plugin está licenciado bajo la **MIT License**. Puedes utilizarlo, modificarlo y distribuirlo libremente.

---
