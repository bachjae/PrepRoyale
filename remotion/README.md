# Prep Royale — Promo Video

Remotion project for the Prep Royale (SAT/ACT Battle Royale) promotional video.

## Quick start

```bash
cd remotion
npm install
npm run preview       # Opens Remotion Studio in your browser
```

## Render commands

| Command | Output | Duration |
|---|---|---|
| `npm run render:promo` | `out/promo.mp4` | 25 s |
| `npm run render:short` | `out/promo-short.mp4` | 15 s |
| `npm run render:promo:hq` | `out/promo-hq.mp4` | 25 s (higher quality) |

Remotion uses **ffmpeg** internally — it ships its own binary so you don't need to install ffmpeg separately.

Render time: ~3–6 minutes on a modern laptop (CPU rendering, 750 frames).

---

## Adding your real screen recording

1. Place your vertical screen recording at:
   ```
   remotion/public/app-recording.mp4
   ```
2. In `src/sections/FeatureSection.tsx`, replace the `<MockScreen>` block with:
   ```tsx
   import { Video, staticFile } from "remotion";
   // ...
   <Video
     src={staticFile("app-recording.mp4")}
     startFrom={/* frame offset in the recording */}
   />
   ```
3. Re-run the preview to check alignment.

---

## Customisation guide

### Changing text copy
All copy lives in the section components. Files to edit:

| What | File |
|---|---|
| Hook lines ("SAT/ACT prep…") | `src/sections/HookSection.tsx` |
| Feature labels + subtitles | `src/config/timing.ts` → `TIMING.features.items` |
| Stats / motivation lines | `src/sections/SocialProofSection.tsx` |
| App name / tagline / CTA badge | `src/sections/CTASection.tsx` |

### Changing timing
Open `src/config/timing.ts`. Each section has `start`, `end`, and sub-frame `in`/`out` values. All numbers are **frame numbers** (multiply by 30 to get seconds).

Example — make the hook 1 second longer:
```ts
hook: {
  start: 0,
  end: 120,  // was 90
  ...
}
// then shift features.start to 120 as well
```

### Changing colors and fonts
Open `src/config/theme.ts`. The `THEME.colors` object controls every color in the project.

### Adding / removing features
Edit `TIMING.features.items` in `src/config/timing.ts`. Each item has:
```ts
{
  in: number,     // frame when this feature starts
  out: number,    // frame when this feature ends
  icon: string,   // emoji
  label: string,  // big bold text
  sub: string,    // subtitle
  screen: ScreenType,  // which mock screen to show
  accent: string, // hex color for this feature's accents
}
```

### Changing the mock app screens
Edit `src/components/MockAppScreens.tsx`. Each screen is an independent React component that fills 520×1040 px inside the phone frame. Add new screen types by:
1. Creating a new `MockXxxScreen` component in the file
2. Adding the type to the `ScreenType` union
3. Adding a case to the `<MockScreen>` switch

---

## Project structure

```
remotion/
├── public/               ← Put app-recording.mp4 here
├── src/
│   ├── index.ts          ← Remotion entry point
│   ├── Root.tsx          ← Registers compositions
│   ├── PrepRoyalePromo.tsx   ← Full 25s composition
│   ├── PrepRoyaleShort.tsx   ← 15s cut-down
│   ├── config/
│   │   ├── theme.ts      ← Colors, fonts, phone dimensions
│   │   └── timing.ts     ← All frame numbers / timing
│   ├── components/
│   │   ├── KineticText.tsx     ← Animated text (fade/slide/scale)
│   │   ├── FeatureCallout.tsx  ← Floating feature badge
│   │   ├── Background.tsx      ← Animated dark BG with glow
│   │   ├── PhoneFrame.tsx      ← Phone bezel wrapper
│   │   └── MockAppScreens.tsx  ← All mock app UI screens
│   └── sections/
│       ├── HookSection.tsx        ← 0–3 s opening hook
│       ├── FeatureSection.tsx     ← 3–19 s feature showcase
│       ├── SocialProofSection.tsx ← 19–22 s stats moment
│       └── CTASection.tsx         ← 22–25 s call to action
├── package.json
├── tsconfig.json
└── remotion.config.ts
```

---

## Common issues

**Preview is slow / laggy**
This is normal — the preview plays back at reduced quality. The final render will look sharp.

**`ffmpeg` error on render**
Remotion ships its own ffmpeg. If you get errors, try:
```bash
npx remotion install ffmpeg
```

**TypeScript errors**
Run `npm install` first. All types come from the Remotion packages.
