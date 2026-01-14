# DreamRoomEngine

DreamRoomEngine is the protected, reusable DreamRoom image-generation pipeline. Treat this as the core product hook.

## What it does
- Generates a DreamRoom image from an input photo and character prompt.
- Returns both:
  - a canonical hero image at **exactly 1200×1600 (3:4 portrait)**, and
  - the **raw model output** (unaltered) for debugging or future tooling.

## Canonical output rule
- The engine **always** returns `heroImageData` at **1200×1600**.
- If the model output is already **1200×1600**, no crop/resize occurs.
- Otherwise, the engine center-crops to 3:4, then resizes to 1200×1600.

## Usage
```swift
import DreamRoomEngine

let engine = DreamRoomEngine()
let result = try await engine.generate(
    beforePhotoData: inputData,
    context: DreamRoomContext(characterPrompt: character.dreamVisionPrompt),
    config: DreamRoomConfig(apiKey: apiKey)
)

let heroData = result.heroImageData      // 1200×1600
let rawData = result.rawImageData        // original model output
let wasNormalized = result.metadata.wasNormalized
```

## Inputs / outputs
- Input: raw image `Data` (JPEG/PNG).
- Output:
  - `heroImageData`: canonical 1200×1600 portrait hero image (Data).
  - `rawImageData`: model output Data (unaltered).
  - `metadata`: includes detected `rawPixelSize` and `wasNormalized`.

## Configuration
- `DreamRoomConfig` requires an `apiKey` and allows overriding the model endpoint and timeout.
