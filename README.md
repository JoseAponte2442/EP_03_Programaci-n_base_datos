# EP_03_Programacion_base_datos

📋 Contenido de las Actividades

Actividad 1: Identificación del proceso a automatizar

Contexto y Problema: Migración de la lógica de negocio repetitiva desde las aplicaciones cliente hacia el servidor SQL Server para evitar sobrecarga de red y vulnerabilidades.

Entradas y Salidas:

Entradas: @IdEquipo (INT), @NuevoEstado (VARCHAR), @Observaciones (TEXT).

Salidas: @CodigoRetorno (INT), @Mensaje (VARCHAR).

Reglas de Negocio: Validación de existencia de equipos y restricción para no dar de baja equipos con mantenimientos pendientes.

Diagrama de Flujo (Pseudocódigo):

### Proceso de Actualización de Estado de Equipos

**Lógica del Pseudocódigo:**
```sql
INICIO
  Recibir parámetros (@IdEquipo, @NuevoEstado, @Observaciones)
  Validar existencia del equipo en la tabla Equipos
  SI el equipo no existe ENTONCES Retornar error (-1)
  Verificar restricciones de órdenes abiertas
  SI existen órdenes abiertas Y @NuevoEstado = 'Dado de Baja' ENTONCES Retornar error (-2)
  Ejecutar UPDATE y retornar éxito (0)
FIN
```

**Códigos de Retorno:**
* `0`: Éxito. El estado del equipo se actualizó correctamente.
* `-1`: Error. El equipo especificado en `@IdEquipo` no existe.
* `-2`: Error. No se puede dar de baja un equipo con órdenes de trabajo abiertas.

