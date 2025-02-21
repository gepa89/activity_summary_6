# 📄 README.md - Plugin de Resumen de Actividades para Redmine 6.0.3

---

## 📊 **Descripción**

Este plugin para **Redmine 6.0.3** permite generar resúmenes de actividades de los usuarios, incluyendo el detalle del tiempo dedicado por **proyecto, tarea y actividad**. También permite exportar los datos en **CSV** y navegar por períodos de tiempo.

### **Características principales**
✅ Filtrado dinámico por **proyecto, tarea, usuario y fecha**.  
✅ **Exportación en CSV** del resumen de actividades.  
✅ Interfaz optimizada con botones de navegación para cambiar de mes.  
✅ Compatible con **Redmine 6.0.3** y **Rails 6**.  
✅ Integración con el sistema de **permisos de Redmine**.

---

## ⚙️ **Requisitos del Sistema**

- **Redmine:** 6.0.3 o superior
- **Ruby:** 3.0.x o superior
- **Rails:** 6.x
- **Base de datos compatible:** MySQL, PostgreSQL o SQLite

---

## 🚀 **Instalación**

### **1️⃣ Clonar el repositorio en el directorio de plugins de Redmine**
```bash
cd /path/to/redmine/plugins
git clone <URL_DEL_REPOSITORIO> resumen_actividades
```

### **2️⃣ Instalar dependencias**
Ejecuta el siguiente comando para instalar las gemas necesarias:
```bash
bundle install
```

### **3️⃣ Aplicar migraciones (si fueran necesarias)**
Si el plugin requiere cambios en la base de datos, ejecuta:
```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### **4️⃣ Reiniciar Redmine**
Si usas Passenger:
```bash
touch /path/to/redmine/tmp/restart.txt
```
Si usas **Nginx o Apache**, reinicia el servicio:
```bash
sudo systemctl restart apache2
# o
sudo systemctl restart nginx
```
Si usas **Docker**:
```bash
docker-compose restart redmine
```

### **5️⃣ Verificar la instalación**
- Inicia sesión en Redmine.
- Dirígete a la pestaña **"Resumen de Actividades"** en el menú superior.

---

## 📋 **Uso del Plugin**

### **1️⃣ Filtrado de Actividades**
- Filtra por **proyecto, tarea, usuario y rango de fechas**.
- Usa los botones **"Mes Anterior"** y **"Mes Siguiente"** para cambiar rápidamente de período.

### **2️⃣ Exportación de Datos**
- Haz clic en el botón **"Exportar CSV"** para descargar un informe con el resumen de actividades.

---

## 🗃️ **Rutas Disponibles**
El plugin agrega las siguientes rutas a Redmine:

| Método | Ruta                                | Acción                      |
|:------:|:------------------------------------|:----------------------------|
| GET    | `/activity_summary`                 | Vista principal del plugin |
| POST   | `/activity_summary/filter`          | Filtrar actividades        |
| GET    | `/activity_summary/export_csv`      | Exportar a CSV             |

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
│   │       ├── index.js.erb
│   │       └── _planilla.html.erb
├── assets/
│   ├── stylesheets/
│   │   └── activity_summary.css
│   ├── javascripts/
│   │   └── activity_summary.js
├── config/
│   └── routes.rb
├── init.rb
├── lib/
│   └── user_patch.rb
├── README.md
```

# ✅ Dependencias necesarias que ya están en Redmine 6.0.3

Redmine 6.0.3 ya incluye todas las dependencias clave que el plugin necesita:

| 📦 **Gema**               | ✅ **Incluida en Redmine 6.0.3** | 📌 **Usada en el Plugin** |
|---------------------------|--------------------------------|---------------------------|
| **Rails 6.x**             | ✅ Sí                          | El plugin usa Rails 6 para formularios y rutas |
| **ActiveRecord**          | ✅ Sí                          | Para consultas a la base de datos |
| **CSV**                   | ✅ Sí                          | Para exportar datos en CSV |
| **ActionView**            | ✅ Sí                          | Para renderizar vistas y _partials_ |
| **Redmine::AccessControl**| ✅ Sí                          | Para gestionar permisos de usuarios |
| **Redmine::Plugin**       | ✅ Sí                          | Para la inicialización del plugin |

🔹 **No es necesario instalar manualmente ninguna de estas gemas.**

## 🔐 **Permisos y Configuración de Acceso**

El acceso al plugin está controlado por el **sistema de permisos de Redmine**.  

### **📌 Permisos Disponibles**
Por defecto, solo los **administradores** pueden acceder al plugin.  
Para otorgar acceso a otros roles, sigue estos pasos:

1. **Ir a**: Administración → Roles y permisos.
2. **Seleccionar un rol** (Ejemplo: "Desarrollador").
3. **Buscar la sección** "Resumen de Actividades".
4. **Habilitar la opción** `Ver Resumen de Actividades`.

---

## 📌 **Consideraciones Importantes**
- **⚠️ Zona Horaria:**  
  Verifica que la configuración de zona horaria en **Redmine** y en la **base de datos** sea correcta para evitar desajustes en las fechas.  
  Puedes verificarlo con:
  ```bash
  date
  ```
- **🔄 Migraciones:**  
  Si en el futuro el plugin requiere cambios en la base de datos, ejecuta:
  ```bash
  bundle exec rake redmine:plugins:migrate RAILS_ENV=production
  ```

---

## ❓ **Soporte y Contribuciones**
Si encuentras **errores** o tienes **sugerencias**, abre un **issue** en el repositorio del plugin o contacta al equipo de desarrollo.  

🔗 **Repositorio:** [[activity_summary_6]  ](https://github.com/gepa89/activity_summary_6)

📩 **Contacto:** [[gepa89]  ](https://github.com/gepa89)

---

## 📜 **Licencia**
Este plugin está licenciado bajo la **MIT License**. Puedes utilizarlo, modificarlo y distribuirlo libremente.  

---

## 🚀 **Mejoras en esta versión**
✅ **Soporte completo para Redmine 6.0.3 y Rails 6**.  
✅ **Optimización del rendimiento en filtrado y exportación de datos**.  
✅ **Mejor gestión de permisos** mediante `Redmine::AccessControl`.  
✅ **Interfaz mejorada con botones de navegación de meses**.  
✅ **Código más limpio y optimizado** para futuras actualizaciones.  
