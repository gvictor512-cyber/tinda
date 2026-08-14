# Checklist de Protección Legal - RoomMate Match

Este documento resume las acciones recomendadas para proteger la propiedad intelectual, el nombre, el código y los activos de la app antes de comercializarla.

---

## 1. Propiedad Intelectual del Código y Diseño (Derechos de Autor)

- [ ] **Declarar autoría en cada archivo fuente clave** con el siguiente encabezado:

```
// RoomMate Match - Proprietary and confidential.
// © [Año] [Nombre del titular]. All rights reserved.
// Unauthorized copying, distribution or use is strictly prohibited.
```

- [ ] **Mantener un repositorio privado** (GitHub/GitLab) con commits fechados como prueba de autoría.
- [ ] **Registrar el software** ante la propiedad intelectual:
  - España: Registro en el Registro Territorial de la Propiedad Intelectual o plataformas como Safe Creative.
  - UE: No hay registro obligatorio, pero se recomienda un depósito con fecha cierta.
- [ ] **Incluir una licencia** en el repositorio (`LICENSE`) que refleje que el código es propietario.
- [ ] **Evitar copiar código de terceros** sin licencia compatible o permiso.

---

## 2. Marca Registrada

- [ ] **Comprobar disponibilidad del nombre** en los siguientes registros:
  - Google Play (único a nivel mundial)
  - Apple App Store
  - WHOIS de dominios (.com, .es, .eu)
  - EUIPO para la UE
  - OEPM para España
  - WIPO para protección internacional
- [ ] **Solicitar el registro de marca** del nombre "RoomMate Match" y variantes.
- [ ] **Solicitar el registro del logotipo, icono y colores corporativos**.
- [ ] **Registrar en las clases adecuadas**:
  - Clase 9: Software y aplicaciones móviles.
  - Clase 35: Publicidad, gestión comercial.
  - Clase 38: Telecomunicaciones.
  - Clase 42: Servicios tecnológicos.

| Entidad | Ámbito | Enlace | Presupuesto aproximado |
|---------|--------|--------|------------------------|
| OEPM    | España | https://www.oepm.es | 100-200 €/clase |
| EUIPO   | Unión Europea | https://euipo.europa.eu | 850 € (1 clase online) |
| WIPO    | Internacional | https://www.wipo.int | Variable por países |

---

## 3. Patentes (si aplica)

- [ ] **Evaluar si hay algoritmo, sistema o proceso técnicamente novedoso** susceptible de patente.
- [ ] **Consultar con un abogado de patentes** si se considera una patente de invención.
- [ ] **Mantener confidencialidad** mientras se estudia la patente (no publicar detalles técnicos).
- [ ] **Recordar que el software puro no es patentable**, pero un método implementado en software sí puede serlo si cumple los requisitos.

---

## 4. Protección del Código y la App

- [ ] **Cambiar el package name** de `com.roommatematch.app` si aún no es definitivo.
- [ ] **Ofuscar el código en producción** (`minifyEnabled`, `shrinkResources` en Android; bitcode/payload obfuscation en iOS).
- [ ] **No exponer secretos** en el cliente: API keys, Stripe secret key, Firebase private keys solo en backend.
- [ ] **Usar `.env` y secretos en el backend**, nunca en el repositorio público.
- [ ] **Añadir `.gitignore` adecuado** para no subir `google-services.json`, `key.properties`, `.env`, etc.
- [ ] **Hacer backups cifrados** del código y los activos gráficos.

---

## 5. Contratos y Acuerdos

- [ ] **Acuerdo de confidencialidad (NDA)** con desarrolladores, diseñadores y colaboradores.
- [ ] **Contrato de cesión de derechos** con freelancers que creen código, diseños o contenido.
- [ ] **Términos y Condiciones de Uso** (`TERMS_OF_SERVICE.md`) actualizados y accesibles en la app.
- [ ] **Política de Privacidad** (`PRIVACY_POLICY.md`) cumpliendo GDPR/CCPA.
- [ ] **Acuerdo de licencia de usuario final (EULA)** si es necesario para tiendas.

---

## 6. Regulación y Publicación

- [ ] **Verificar cumplimiento GDPR**:
  - Consentimiento informado.
  - Derecho de acceso, rectificación, supresión y portabilidad.
  - Registro de actividades de tratamiento.
- [ ] **Cumplir CCPA** si se dirige a usuarios en California.
- [ ] **Declarar uso de datos sensibles** en Apple App Store y Google Play:
  - Ubicación aproximada/precisa.
  - Fotos/vídeos.
  - Contactos.
  - Identificadores de dispositivo.
- [ ] **Contar con consentimiento expreso** para pagos, verificación y marketing.
- [ ] **Designar un DPO (Delegado de Protección de Datos)** si se procesan datos a gran escala.

---

## 7. Dominios y Redes Sociales

- [ ] **Registrar dominios principales**:
  - `roommatematch.com`
  - `roommatematch.es`
  - `roommatematch.eu`
- [ ] **Reservar usuarios en redes sociales** con el nombre de marca.
- [ ] **Crear correos corporativos** (`hola@`, `legal@`, `privacy@`).

---

## 8. Preparación para Abogado/Asesor

Documentos a tener listos para una primera consulta:

- [ ] Código fuente y lista de dependencias de terceros con licencias.
- [ ] Manual de identidad corporativa: nombre, logo, colores, tipografías.
- [ ] Descripción técnica del algoritmo de matching (si se solicita patente).
- [ ] Listado de países objetivo de comercialización.
- [ ] Contratos actuales con colaboradores.

---

## 9. Próximos Pasos Inmediatos

1. **Esta semana:** registrar dominios y nombres de usuario en redes sociales.
2. **Esta semana:** cambiar `com.roommatematch.app` si es provisional.
3. **En 15 días:** solicitar registro de marca en OEPM y/o EUIPO.
4. **En 30 días:** depositar el código fuente en registro privado o Safe Creative.
5. **Antes del lanzamiento:** revisar con un abogado especializado en propiedad intelectual y GDPR.

---

**Nota:** Este checklist es orientativo y no sustituye el asesoramiento legal profesional. Se recomienda contactar con un abogado especializado en propiedad intelectual y protección de datos.
