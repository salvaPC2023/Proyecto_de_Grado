# Proyecto de Grado — Maintenance App

Sistema de gestión de mantenimiento con backend FastAPI y app móvil Flutter.

---

## Requisitos previos

- Python 3.11+ con `venv` o equivalente
- Flutter SDK
- Dispositivo Android con depuración USB habilitada
- Archivo `backend/.env` configurado (copiar desde `backend/.env.example`)

---

## 1. Backend (FastAPI)

Desde la raíz del proyecto:

```powershell
cd backend
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

El servidor queda disponible en `http://localhost:8000`. La documentación interactiva está en `http://localhost:8000/docs`.

### Primera vez (instalar dependencias)

```powershell
cd backend
pip install -e ".[dev]"
```

---

## 2. App móvil (Flutter)

### Obtener la IP de tu PC (Wi-Fi)

En PowerShell:

```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" } | Select-Object -ExpandProperty IPAddress
```

Usa esa IP en el comando de Flutter (campo `API_BASE_URL`).

### Obtener el ID de tu dispositivo Android

```powershell
flutter devices
```

Copia el ID del dispositivo conectado.

### Correr la app

```powershell
cd mobile
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<IP_DE_TU_PC>:8000/api/v1
```

**Ejemplo con los valores actuales:**

```powershell
cd mobile
flutter run -d 138082553T002618 --dart-define=API_BASE_URL=http://192.168.1.26:8000/api/v1
```

> La IP puede cambiar si te reconectas a la red. Repite el paso de obtener la IP si la app no conecta.

### Firewall (solo primera vez, ejecutar como Administrador)

Si el celular no puede conectar al backend, agregar regla de firewall:

```powershell
New-NetFirewallRule -DisplayName "FastAPI Dev 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
```

---

## Orden de arranque recomendado

1. Iniciar el backend (`uvicorn ...`)
2. Conectar el celular por USB y confirmar que aparece en `flutter devices`
3. Correr la app Flutter con la IP correcta
