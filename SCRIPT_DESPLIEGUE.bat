@echo off
echo ========================================
echo  SCRIPT DE DESPLIEGUE AUTOMATICO
echo  Sistema de Gestion de Transporte
echo ========================================
echo.

:: Verificar si se ejecuta como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Ejecutandose como administrador
) else (
    echo [ERROR] Este script debe ejecutarse como administrador
    echo Haga clic derecho en el archivo y seleccione "Ejecutar como administrador"
    pause
    exit /b 1
)

:: Configurar variables
set SITE_NAME=Gestion-Transporte
set SITE_PATH=C:\inetpub\wwwroot\gestion-transporte
set BACKUP_PATH=C:\Backup\gestion-transporte-%date:~-4,4%%date:~-10,2%%date:~-7,2%

echo.
echo Configuracion del despliegue:
echo - Nombre del sitio: %SITE_NAME%
echo - Ruta del sitio: %SITE_PATH%
echo - Ruta de backup: %BACKUP_PATH%
echo.

:: Preguntar confirmacion
set /p CONFIRM="¿Continuar con el despliegue? (S/N): "
if /i not "%CONFIRM%"=="S" (
    echo Despliegue cancelado por el usuario
    pause
    exit /b 0
)

echo.
echo ========================================
echo  INICIANDO DESPLIEGUE
echo ========================================

:: Paso 1: Verificar IIS
echo.
echo [1/8] Verificando IIS...
sc query W3SVC >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] IIS esta instalado y ejecutandose
) else (
    echo [ERROR] IIS no esta instalado o no esta ejecutandose
    echo Por favor instale IIS antes de continuar
    pause
    exit /b 1
)

:: Paso 2: Crear backup si existe instalacion previa
echo.
echo [2/8] Creando backup...
if exist "%SITE_PATH%" (
    if not exist "C:\Backup" mkdir "C:\Backup"
    xcopy "%SITE_PATH%" "%BACKUP_PATH%\" /E /I /Y >nul 2>&1
    if %errorLevel% == 0 (
        echo [OK] Backup creado en: %BACKUP_PATH%
    ) else (
        echo [WARNING] No se pudo crear backup completo
    )
) else (
    echo [INFO] No existe instalacion previa, omitiendo backup
)

:: Paso 3: Crear directorio del sitio
echo.
echo [3/8] Creando directorio del sitio...
if not exist "%SITE_PATH%" (
    mkdir "%SITE_PATH%"
    echo [OK] Directorio creado: %SITE_PATH%
) else (
    echo [INFO] Directorio ya existe: %SITE_PATH%
)

:: Paso 4: Copiar archivos
echo.
echo [4/8] Copiando archivos de la aplicacion...
copy "index.html" "%SITE_PATH%\" >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] index.html copiado
) else (
    echo [ERROR] No se pudo copiar index.html
    pause
    exit /b 1
)

copy "web.config" "%SITE_PATH%\" >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] web.config copiado
) else (
    echo [WARNING] No se pudo copiar web.config
)

:: Paso 5: Configurar permisos
echo.
echo [5/8] Configurando permisos...
icacls "%SITE_PATH%" /grant "IIS_IUSRS:(OI)(CI)RX" >nul 2>&1
icacls "%SITE_PATH%" /grant "IUSR:(OI)(CI)RX" >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Permisos configurados
) else (
    echo [WARNING] Problemas configurando permisos
)

:: Paso 6: Crear sitio en IIS
echo.
echo [6/8] Configurando sitio en IIS...

:: Verificar si el sitio ya existe
%windir%\system32\inetsrv\appcmd.exe list site "%SITE_NAME%" >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] El sitio ya existe, actualizando configuracion...
    %windir%\system32\inetsrv\appcmd.exe set site "%SITE_NAME%" -physicalPath:"%SITE_PATH%" >nul 2>&1
) else (
    echo [INFO] Creando nuevo sitio...
    %windir%\system32\inetsrv\appcmd.exe add site /name:"%SITE_NAME%" /physicalPath:"%SITE_PATH%" /bindings:"http/*:8080:" >nul 2>&1
    if %errorLevel% == 0 (
        echo [OK] Sitio creado en puerto 8080
    ) else (
        echo [ERROR] No se pudo crear el sitio
        pause
        exit /b 1
    )
)

:: Paso 7: Configurar pool de aplicaciones
echo.
echo [7/8] Configurando pool de aplicaciones...
%windir%\system32\inetsrv\appcmd.exe set apppool "DefaultAppPool" -processModel.identityType:ApplicationPoolIdentity >nul 2>&1
echo [OK] Pool de aplicaciones configurado

:: Paso 8: Verificar despliegue
echo.
echo [8/8] Verificando despliegue...
if exist "%SITE_PATH%\index.html" (
    echo [OK] Archivo principal encontrado
) else (
    echo [ERROR] Archivo principal no encontrado
    pause
    exit /b 1
)

:: Mostrar informacion de acceso
echo.
echo ========================================
echo  DESPLIEGUE COMPLETADO EXITOSAMENTE
echo ========================================
echo.
echo URLs de acceso:
echo - HTTP:  http://localhost:8080
echo - HTTP:  http://%COMPUTERNAME%:8080
echo.
echo IMPORTANTE - PASOS ADICIONALES REQUERIDOS:
echo.
echo 1. CONFIGURAR HTTPS:
echo    - Abrir IIS Manager
echo    - Ir a Server Certificates
echo    - Crear certificado auto-firmado
echo    - Agregar binding HTTPS (puerto 443)
echo.
echo 2. CAMBIAR CONTRASEÑAS POR DEFECTO:
echo    - Editar: %SITE_PATH%\index.html
echo    - Buscar seccion 'validUsers'
echo    - Cambiar contraseñas de admin, supervisor, operador
echo.
echo 3. CONFIGURAR FIREWALL:
echo    - Abrir puertos 80 y 443 en Windows Firewall
echo.
echo 4. USUARIOS INICIALES:
echo    - admin / admin123
echo    - supervisor / super123
echo    - operador / oper123
echo.
echo Backup creado en: %BACKUP_PATH%
echo Logs de IIS: C:\inetpub\logs\LogFiles\
echo.

:: Preguntar si abrir el sitio
set /p OPEN_SITE="¿Abrir el sitio en el navegador? (S/N): "
if /i "%OPEN_SITE%"=="S" (
    start http://localhost:8080
)

echo.
echo Presione cualquier tecla para salir...
pause >nul
