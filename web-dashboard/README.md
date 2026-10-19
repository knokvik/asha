# Asha Setu web dashboard

The doctor desk is this existing React + Vite app. New child-triage views were added onto the pages that were already here.

| Path | Existing page | What was added |
| --- | --- | --- |
| `/phc` and `/queue` | PHC Shahpur emergency queue | PCMC child tickets, oldest RED first, 30-minute SLA, ACKNOWLEDGE, START CONSULT, reasons, SMS line |
| `/ticket/:id` | Same referral record | Diagnosis, treated / referred up / sent home, note for the ASHA |
| `/heatmap` | Leaflet field map | PCMC W1–W8 choropleth, outbreak ring, 12-week sparkline, week slider |
| `/supervisor` and `/af` | ASHA facilitator page | Sortable IMCI completion table |
| `/resources` | Outbreak alerts | Ward W3 dengue NS1 card next to the Shahpur alerts |

Demo mode is on unless `VITE_USE_MOCKS=false`. With mocks, acknowledging a red ticket and recording an outcome updates the ward confirmation on the heatmap in the same session, well inside two minutes.

Shahpur patients, including Sunita Devi, stay on the queue.

# React + TypeScript + Vite

This template provides a minimal setup to get React working in Vite with HMR and some Oxlint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the Oxlint configuration

If you are developing a production application, we recommend enabling type-aware lint rules by installing `oxlint-tsgolint` and editing `.oxlintrc.json`:

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["react", "typescript", "oxc"],
  "options": {
    "typeAware": true
  },
  "rules": {
    "react/rules-of-hooks": "error",
    "react/only-export-components": ["warn", { "allowConstantExport": true }]
  }
}
```

See the [Oxlint rules documentation](https://oxc.rs/docs/guide/usage/linter/rules) for the full list of rules and categories.
