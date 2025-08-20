# Guía de Despliegue - Sistema de Gestión de Transporte

## Requisitos del Servidor
- Windows Server con IIS instalado
- Certificado SSL válido
- Acceso administrativo al servidor

## Pasos para el Despliegue

### 1. Preparar el Servidor IIS

#### Instalar IIS (si no está instalado)
1. Abrir **Server Manager**
2. Ir a **Manage** > **Add Roles and Features**
3. Seleccionar **Web Server (IIS)**
4. Incluir las siguientes características:
   - Static Content
   - Default Document
   - Directory Browsing
   - HTTP Errors
   - HTTP Redirection
   - Request Filtering

#### Verificar IIS
1. Abrir **Internet Information Services (IIS) Manager**
2. Verificar que el **Default Web Site** esté funcionando
3. Probar accediendo a `http://localhost` desde el servidor

### 2. Crear el Sitio Web

#### Opción A: Usar Default Web Site
1. Navegar a `C:\inetpub\wwwroot\`
2. Crear carpeta `gestion-transporte`
3. Copiar el archivo `index.html` a esta carpeta

#### Opción B: Crear Nuevo Sitio (Recomendado)
1. En IIS Manager, clic derecho en **Sites**
2. Seleccionar **Add Website**
3. Configurar:
   - **Site name:** `Gestion-Transporte`
   - **Physical path:** `C:\inetpub\wwwroot\gestion-transporte`
   - **Port:** `80` (HTTP temporal)
4. Crear la carpeta física si no existe
5. Copiar `index.html` a la carpeta

### 3. Configurar HTTPS/SSL

#### Obtener Certificado SSL
**Opción 1: Certificado Interno (Para Intranet)**
1. Abrir **Server Manager**
2. Ir a **Tools** > **Internet Information Services (IIS) Manager**
3. Seleccionar el servidor en el panel izquierdo
4. Doble clic en **Server Certificates**
5. Clic en **Create Self-Signed Certificate**
6. Nombre: `gestion-transporte-ssl`
7. Clic **OK**

**Opción 2: Certificado de CA Interna**
- Solicitar certificado a tu CA corporativa
- Instalar el certificado en el servidor

#### Configurar HTTPS Binding
1. En IIS Manager, seleccionar tu sitio web
2. Clic derecho > **Edit Bindings**
3. Clic **Add**
4. Configurar:
   - **Type:** `https`
   - **Port:** `443`
   - **SSL certificate:** Seleccionar el certificado instalado
5. Clic **OK**

#### Configurar Redirección HTTP a HTTPS
1. Seleccionar tu sitio web en IIS
2. Doble clic en **URL Rewrite** (instalar si no está disponible)
3. Clic **Add Rule(s)** > **Blank rule**
4. Configurar:
   - **Name:** `Redirect to HTTPS`
   - **Pattern:** `(.*)`
   - **Conditions:** Add condition
     - **Condition input:** `{HTTPS}`
     - **Pattern:** `^OFF$`
   - **Action type:** `Redirect`
   - **Redirect URL:** `https://{HTTP_HOST}/{R:1}`
   - **Redirect type:** `Permanent (301)`

### 4. Configurar Seguridad

#### Configurar Autenticación
1. Seleccionar tu sitio web
2. Doble clic en **Authentication**
3. Configurar según necesidades:
   - **Anonymous Authentication:** Enabled (para la app)
   - **Windows Authentication:** Opcional (para integración AD)

#### Configurar Permisos de Carpeta
1. Navegar a `C:\inetpub\wwwroot\gestion-transporte`
2. Clic derecho > **Properties** > **Security**
3. Verificar permisos:
   - **IIS_IUSRS:** Read & Execute
   - **IUSR:** Read & Execute

### 5. Configurar Firewall

#### Abrir Puertos Necesarios
1. Abrir **Windows Firewall with Advanced Security**
2. Verificar reglas para:
   - **HTTP (Port 80):** Permitir entrada
   - **HTTPS (Port 443):** Permitir entrada

### 6. Configurar DNS (Opcional)

#### Para Acceso por Nombre
1. En tu servidor DNS interno, crear registro A:
   - **Name:** `gestion-transporte`
   - **IP:** Dirección IP del servidor
2. Los usuarios podrán acceder via: `https://gestion-transporte.tudominio.local`

### 7. Verificar el Despliegue

#### Pruebas Básicas
1. **Acceso HTTP:** `http://servidor-ip/gestion-transporte`
   - Debe redirigir automáticamente a HTTPS
2. **Acceso HTTPS:** `https://servidor-ip/gestion-transporte`
   - Debe cargar la aplicación correctamente
3. **Funcionalidad:** Probar login con usuarios predefinidos:
   - admin / admin123
   - supervisor / super123
   - operador / oper123

#### Verificar Certificado SSL
1. Acceder via HTTPS
2. Verificar que el navegador muestre el candado de seguridad
3. Si es certificado auto-firmado, agregar excepción de seguridad

### 8. Configuración Post-Despliegue

#### Cambiar Contraseñas por Defecto
**IMPORTANTE:** Antes de dar acceso a usuarios:
1. Abrir `index.html` en un editor de texto
2. Localizar la sección `validUsers` (línea ~709)
3. Cambiar las contraseñas:
```javascript
validUsers: [
    { username: 'admin', password: 'NUEVA_CONTRASEÑA_ADMIN', role: 'admin' },
    { username: 'supervisor', password: 'NUEVA_CONTRASEÑA_SUPERVISOR', role: 'supervisor' },
    { username: 'operador', password: 'NUEVA_CONTRASEÑA_OPERADOR', role: 'operator' }
],
```
4. Guardar el archivo

#### Configurar Backup Automático
1. Crear tarea programada para backup de la carpeta del sitio
2. Incluir backup del certificado SSL si es necesario

### 9. Acceso de Usuarios

#### URLs de Acceso
- **Interna:** `https://IP-SERVIDOR/gestion-transporte`
- **Con DNS:** `https://gestion-transporte.tudominio.local`

#### Usuarios Iniciales
- **Administrador:** admin / [nueva_contraseña]
- **Supervisor:** supervisor / [nueva_contraseña]  
- **Operador:** operador / [nueva_contraseña]

### 10. Monitoreo y Mantenimiento

#### Logs de IIS
- Ubicación: `C:\inetpub\logs\LogFiles\`
- Revisar regularmente para detectar errores

#### Actualización de la Aplicación
1. Hacer backup del archivo actual
2. Reemplazar `index.html` con la nueva versión
3. Verificar funcionamiento

## Solución de Problemas Comunes

### Error 500 - Internal Server Error
- Verificar permisos de carpeta
- Revisar logs de IIS

### Certificado SSL no confiable
- Instalar certificado en almacén de certificados de confianza
- O usar certificado de CA corporativa

### Acceso denegado
- Verificar autenticación en IIS
- Revisar permisos de carpeta

## Contacto de Soporte
Para problemas técnicos, contactar al administrador del sistema.
