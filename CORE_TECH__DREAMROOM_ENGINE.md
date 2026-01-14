# DO NOT TOUCH WITHOUT EXPLICIT TASK
This engine is the core product hook. Treat DreamRoomEngine as a protected black box unless you are explicitly tasked to change it.

## DreamRoomEngine is the product hook
DreamRoomEngine generates the DreamRoom hero image that motivates users to tidy. It is the core output that the rest of the product depends on.

## Why Shop / Filters / Gallery / Points depend on it
- **Shop / Filters** exist to stylize DreamRoom outputs.
- **Gallery** exists to view/share DreamRoom outputs.
- **Points** are meaningful because they unlock filters applied to DreamRoom outputs.

## Guardrails
- Do not refactor engine behavior casually.
- Keep UI (SwiftUI/views) out of DreamRoomEngine.
- Preserve the canonical output rule: hero image must be 1200×1600; raw output also retained.
