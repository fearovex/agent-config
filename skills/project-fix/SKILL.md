# project-fix

> Implementa las correcciones encontradas por /project:audit. Lee audit-report.md como spec y ejecuta cada acción requerida.

**Triggers**: `/project:fix`, aplicar correcciones audit, fix proyecto claude, implementar audit

---

## Rol en el flujo SDD meta-configuración

Este skill es el **equivalente a la fase APPLY** del ciclo SDD, aplicado a la configuración del proyecto:

```
/project:audit  →  audit-report.md  →  /project:fix  →  /project:audit (verify)
     (spec)           (artefacto)          (apply)           (verify)
```

El `audit-report.md` generado por `/project:audit` es el INPUT de este skill. Sin ese artefacto, este skill no puede operar.

**Regla absoluta**: Este skill NUNCA inventa correcciones. Solo implementa lo que está en `FIX_MANIFEST` del audit-report.md.

---

## Prerequisito: audit-report.md

Antes de cualquier otra cosa, verifico que existe `.claude/audit-report.md`.

Si NO existe:
```
❌ No se encontró .claude/audit-report.md

Este skill requiere que /project:audit haya sido ejecutado primero.
El reporte de auditoría es la especificación que implemento.

Por favor ejecuta: /project:audit
```

Si existe pero tiene más de 7 días:
```
⚠️ El audit-report.md tiene [N] días de antigüedad (generado: [fecha])

Opciones:
  1. Usar el reporte existente igual (puede estar desactualizado)
  2. Ejecutar /project:audit primero para un diagnóstico fresco

¿Cómo deseas proceder?
```

---

## Proceso de Fix

### Paso 1 — Leer y parsear el FIX_MANIFEST

Leo el bloque `FIX_MANIFEST` del `audit-report.md`. Extraigo:
- `required_actions.critical[]`
- `required_actions.high[]`
- `required_actions.medium[]`
- `required_actions.low[]`
- `missing_global_skills[]`
- `orphaned_changes[]`
- `violations[]`

Presento al usuario el resumen de lo que voy a hacer:

```
📋 Fix Plan — [Nombre Proyecto]
Basado en audit del [fecha]
Score actual: [XX]/100

Acciones a ejecutar:
  ❌ Críticas  : [N] acciones
  ⚠️ Altas     : [N] acciones
  ℹ️ Medias    : [N] acciones
  💡 Bajas     : [N] acciones (opcionales)

¿Ejecutar todas las correcciones? (críticas + altas + medias)
  S → Ejecutar todo recomendado
  C → Solo críticas (mínimo para SDD funcional)
  R → Revisar una por una
  N → Cancelar
```

Espero respuesta del usuario antes de continuar.

---

### Paso 2 — Ejecutar por fases

Proceso las acciones en orden de severidad. Cada fase tiene un checkpoint.

#### Fase 1 — Correcciones Críticas (bloquean SDD)

Ejecuto en este orden:

**1.1 Inicializar openspec/ si no existe**
```yaml
type: create_dir
target: openspec/
```
Acción: Crear el directorio `openspec/` con estructura base:
```
openspec/
├── config.yaml
└── changes/
    └── archive/
        └── .gitkeep
```

**1.2 Crear openspec/config.yaml si no existe**
```yaml
type: create_file
target: openspec/config.yaml
template: openspec_config
```
Leo el stack del proyecto desde `ai-context/stack.md` (o `package.json` si stack.md no existe) y genero:
```yaml
project:
  name: "[nombre del package.json/pyproject.toml]"
  description: "[del README o inferida]"
  root: "[ruta absoluta al proyecto]"
  stack:
    language: "[detectado]"
    framework: "[detectado]"
    database: "[detectado o none]"
    testing: "[detectado]"
  conventions:
    naming: "[detectado: camelCase|snake_case|PascalCase]"
    structure: "[detectado: feature|layer|monorepo]"

artifact_store:
  mode: openspec
  changes_dir: openspec/changes
  archive_dir: openspec/changes/archive

rules:
  proposal:
    - "Debe incluir criterios de éxito medibles"
    - "Debe evaluar impacto en funcionalidad existente"
    - "Debe proponer plan de rollback si el cambio es de alto riesgo"
  specs:
    - "Usar Given/When/Then para escenarios de comportamiento"
    - "Incluir casos límite y estados de error"
    - "Especificar contratos de API cuando aplique"
  design:
    - "Cada decisión de diseño debe tener justificación"
    - "Preferir patrones existentes del proyecto sobre nuevos"
    - "Documentar alternativas descartadas"
  tasks:
    - "Tareas atómicas: una tarea = un archivo o una función"
    - "Incluir ruta de archivo en cada tarea"
    - "Definir criterio de verificación por tarea"
  apply:
    - "Seguir convenciones documentadas en ai-context/conventions.md"
    - "Correr tests antes de marcar tarea completa"
    - "No modificar archivos no listados en las tareas"
  verify:
    - "Verificar compliance con specs primero"
    - "Luego verificar adherencia al diseño técnico"
    - "Revisar que no hay regresiones en funcionalidad existente"
```

**1.3 Crear global SDD skills faltantes**
```yaml
type: install_skill
target: "[skill-name]"
```
Si algún global SDD skill falta en `~/.claude/skills/`, notifico al usuario — no puedo crearlos automáticamente, pero indico exactamente qué está faltando y dónde deben estar.

**1.4 Actualizar CLAUDE.md — añadir sección SDD**
```yaml
type: update_file
target: .claude/CLAUDE.md
section: sdd_section
```
Si CLAUDE.md no menciona `/sdd:*`, añado al final del CLAUDE.md esta sección:
```markdown
## SDD — Spec-Driven Development

Este proyecto usa SDD. Los artefactos viven en `openspec/`.

| Comando | Acción |
|---------|--------|
| `/sdd:new <cambio>` | Inicia ciclo SDD completo |
| `/sdd:ff <cambio>` | Fast-forward: propose → spec+design → tasks |
| `/sdd:explore <tema>` | Explorar sin commitarse a cambios |
| `/sdd:status` | Ver estado de cambios activos |

**Flujo completo**: explore → propose → spec + design → tasks → apply → verify → archive
```

**Checkpoint**: Presento las acciones críticas ejecutadas y pido confirmación para continuar con las altas.

---

#### Fase 2 — Correcciones Altas (degradan calidad)

**2.1 Crear archivos de memoria faltantes**
```yaml
type: create_file
target: ai-context/[archivo].md
template: [stack|architecture|conventions|known-issues|changelog-ai]
```

Para cada archivo faltante, genero contenido real basado en lo que puedo detectar del proyecto:

- **stack.md**: Leo `package.json`/`pyproject.toml`, genero tabla de dependencias con versiones reales
- **architecture.md**: Leo estructura de carpetas y archivos de config, documento el patrón detectado
- **conventions.md**: Leo 3-5 archivos de código existente, infiero y documento las convenciones reales
- **known-issues.md**: Inicio con sección de "Production Safety Rules" y dejo estructura para que se llene
- **changelog-ai.md**: Creo con entrada inicial documentando este fix

**2.2 Actualizar stack en CLAUDE.md**
```yaml
type: update_file
target: .claude/CLAUDE.md
section: tech_stack
```
Si las versiones declaradas no coinciden con package.json, actualizo la tabla de Tech Stack con los valores reales.

**2.3 Corregir registry de Skills**
```yaml
type: add_registry_entry / remove_registry_entry
target: .claude/CLAUDE.md
section: skills_registry
```
- Añado al registry las skills que están en disco pero no listadas
- Marco como `[MISSING FILE]` las skills listadas pero sin archivo (no las elimino, informo)

**2.4 Corregir registry de Commands**
Mismo proceso que skills.

**Checkpoint**: Presento acciones altas ejecutadas. Pido confirmación para continuar con medias.

---

#### Fase 3 — Correcciones Medias

**3.1 Añadir secciones faltantes en CLAUDE.md**
Si faltan secciones como Unbreakable Rules, Plan Mode Rules, Quick Reference — añado las correspondientes con contenido inferido del proyecto.

**3.2 Actualizar Folder Structure en CLAUDE.md**
Si existen directorios en `.claude/` no documentados en CLAUDE.md, los añado a la tabla de Folder Structure.

**3.3 Corregir cross-references rotas**
Para referencias rotas donde el archivo de destino NO existe y debería existir: lo creo con contenido mínimo. Para referencias donde el archivo sí existe pero la ruta está mal escrita: corrijo la ruta.

**Checkpoint**: Presento acciones medias. Ofrece ejecutar las bajas.

---

#### Fase 4 — Correcciones Bajas (opcional, pregunto antes)

**4.1 Instalar global tech skills recomendadas**
Para cada global skill recomendada pero no instalada localmente:
```
Skill recomendada: react-19
Disponible en: ~/.claude/skills/react-19/SKILL.md
Para instalarla en este proyecto: /skill:add react-19
```
No instalo automáticamente — solo informo con el comando exacto.

**4.2 Notificar violaciones de arquitectura**
Las violaciones encontradas en la Dimensión 7 NO las corrijo automáticamente — son cambios de código que requieren revisión humana. Las presento con contexto:
```
⚠️ Violaciones de arquitectura (requieren revisión manual):
  - src/pages/api/payment.js:45 — Lógica de negocio en API route
  - src/components/Cart.jsx:23 — Import directo de servicio (debería usar hook)
```

---

### Paso 3 — Registrar en changelog

Al terminar, añado una entrada a `ai-context/changelog-ai.md`:

```markdown
## [YYYY-MM-DD] — project:fix ejecutado

**Score antes**: [XX]/100
**Acciones ejecutadas**: [N] críticas, [N] altas, [N] medias
**Archivos creados**: [lista]
**Archivos modificados**: [lista]
**SDD Readiness**: [FULL|PARTIAL|NOT CONFIGURED] → [estado final]
**Notas**: [cualquier decisión importante tomada]
```

---

### Paso 4 — Reporte final

```
✅ Fix completado — [Nombre Proyecto]

Acciones ejecutadas:
  ✅ [N] críticas
  ✅ [N] altas
  ✅ [N] medias
  ⏭️ [N] bajas (informadas, no auto-ejecutadas)

Archivos creados:    [lista]
Archivos modificados: [lista]

SDD Status: [FULL / PARTIAL / NOT CONFIGURED]
  - openspec/config.yaml: [✅ creado | ✅ ya existía | ❌ pendiente]
  - Global SDD skills: [✅ completos | ⚠️ faltan: lista]
  - CLAUDE.md menciona /sdd:*: [✅ sí | ✅ añadido]

Para verificar el resultado:
  → /project:audit  (debe mostrar score más alto)
  → Para iniciar desarrollo con SDD: /sdd:new <nombre-cambio>

Cambios registrados en: ai-context/changelog-ai.md
```

---

## Templates internos

### Template: openspec_config
Ver Paso 2 — 1.2 arriba para el template completo de `openspec/config.yaml`.

### Template: changelog entry
```markdown
## [YYYY-MM-DD] — [descripción del cambio]

**Tipo**: [Feature|Bug Fix|Refactor|Config|Documentation]
**Agente**: Claude [modelo]
**Archivos modificados**:
- `ruta/archivo.ext` — [qué se hizo]

**Decisiones tomadas**:
- [decisión y su razón]

**Notas**: [cualquier cosa importante para sesiones futuras]
```

---

## Reglas de ejecución

1. **Sin audit-report.md no opero** — solicito al usuario ejecutar `/project:audit` primero
2. **Solo implemento lo que está en FIX_MANIFEST** — nunca invento correcciones adicionales
3. **Checkpoint entre fases** — nunca ejecuto la siguiente fase sin confirmación del usuario
4. **No corrijo código de producción** — reporto violaciones de arquitectura pero no las toco
5. **Siempre registro en changelog** — cada fix queda documentado en `ai-context/changelog-ai.md`
6. **Si un archivo ya tiene contenido más completo que el template**, no lo sobreescribo — hago merge inteligente o añado solo las secciones faltantes
7. **Idempotente**: ejecutar `/project:fix` dos veces en el mismo proyecto no debe causar duplicaciones
8. **Al finalizar**, sugiero siempre: "Ejecuta `/project:audit` para verificar el score nuevo"
