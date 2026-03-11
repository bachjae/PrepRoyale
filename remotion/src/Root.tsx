import React from "react";
import { Composition } from "remotion";
import { PrepRoyalePromo } from "./PrepRoyalePromo";
import { PrepRoyaleShort } from "./PrepRoyaleShort";
import { TIMING, FPS } from "./config/timing";

/**
 * =========================================================================
 * PREP ROYALE REMOTION VIDEOS - SCENE-BY-SCENE PLAN (STEP 2)
 * =========================================================================
 *
 * PROMO TIMING (Total: ~17s / 510 frames at 30 FPS)
 * -------------------------------------------------------------------------
 * Scene 1 — Hook (0–75 frames | ~2.5s)
 * - Background: #0F172A (dark slate, flat, no gradients).
 * - "SAT/ACT prep..." text fades/slides in first, small and muted (#94A3B8).
 * - "boring?" slams in large (White) with spring scale bounce + brief rapid shake.
 *
 * Scene 2 — App Demo (75–345 frames | ~9s, 3s per screen)
 * - Phone mockup flies in from bottom with 3D tilt entry (rotateX/Y), settles.
 * - Screen 1: Lobby (75-165)
 * - Screen 2: Quiz (165-255) — Crossfades from Lobby.
 * - Screen 3: Results (255-345) — Crossfades from Quiz.
 * - Animated callout labels: "Real-time 1v1", "Answer fast to survive" float 
 *   in via spring pop-ins. Text on screen > 45 frames.
 *
 * Scene 3 — Energy/Battle Moment (345–420 frames | 2.5s, 25 frames per word)
 * - Fast-cut text, one word at a time hitting with spring scale (1.4 -> 1.0).
 * - "STUDY." (345-370) on Primary bg (#38BDF8)
 * - "COMPETE." (370-395) on Accent bg (#06B6D4)
 * - "WIN." (395-420) on Orange bg (#F97316)
 *
 * Scene 4 — CTA Outro (420–510 frames | 3s)
 * - Background returns to flat dark (#0F172A).
 * - App Logo + "Prep Royale" animates in with spring bounce.
 * - Subtitle CTA slides up: "Free to play. Start today.".
 *
 *
 * SHORT TIMING (Total: ~13s / 390 frames at 30 FPS)
 * -------------------------------------------------------------------------
 * Follows same scenes as Promo but condensed:
 * - Scene 1: Hook (0–60 frames)
 * - Scene 2: App Demo (60–240 frames | 2 screens = Lobby -> Quiz)
 * - Scene 3: Energy (240–300 frames | "STUDY", "COMPETE", "WIN" 20 frames each)
 * - Scene 4: CTA (300–390 frames)
 *
 * APP UI RECREATION RULES
 * -------------------------------------------------------------------------
 * All screens must exactly match the Flutter app theme (No gradients):
 * - Primary: Sky 400 (#38BDF8)
 * - Secondary: Sky 500 (#0EA5E9)
 * - Accent: Teal (#06B6D4)
 * - Backgrounds: Flat dark (#0F172A) / App backgrounds.
 * - Font: Poppins, 800/900 for headlines.
 * - No `any` types. JSDoc on components.
 * =========================================================================
 *
 * Root — registers all Remotion compositions.
 */
export const Root: React.FC = () => {
  return (
    <>
      {/* Full 26-second promo (9:16 vertical) — 780 frames */}
      <Composition
        id="PrepRoyalePromo"
        component={PrepRoyalePromo}
        durationInFrames={TIMING.PROMO.duration}
        fps={FPS}
        width={1080}
        height={1920}
      />

      {/* 16-second cut-down (same resolution) — 480 frames */}
      <Composition
        id="PrepRoyaleShort"
        component={PrepRoyaleShort}
        durationInFrames={TIMING.SHORT.duration}
        fps={FPS}
        width={1080}
        height={1920}
      />
    </>
  );
};
