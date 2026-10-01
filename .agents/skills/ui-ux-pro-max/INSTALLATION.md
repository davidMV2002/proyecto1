# UI UX Pro Max instalado en el proyecto

Fuente: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
Instalacion: `npx --yes ui-ux-pro-max-cli init --ai codex`
Fecha: 2026-10-01
Ubicacion: `.agents/skills/ui-ux-pro-max/`
Agente: `.codex/agents/ui_ux_pro_max.toml`

Los archivos de la skill se han generado con el instalador oficial. La skill proporciona el metodo y los datos de diseno; el agente solo conecta ese metodo con Flutter y la coordinacion del proyecto.

Ejemplo en PowerShell, desde la raiz del proyecto:

```powershell
python .agents/skills/ui-ux-pro-max/scripts/search.py "form validation" --stack flutter
```

La busqueda de Flutter se ha ejecutado correctamente. No se han modificado pantallas de la app. Para que el cliente descubra la nueva skill, reinicia Codex. Las instrucciones de AGENTS.md permiten leerla explicitamente desde su ruta local.
