/**
 * TIMING CONFIG — 30s App Store-style promo
 * Phone renders at 414×896 logical pixels
 */

export const FPS = 30;

export const FEATURE_ACCENTS = {
  primary: "#38BDF8",
  accent:  "#06B6D4",
  orange:  "#F97316",
  green:   "#22C55E",
  gold:    "#EAB308",
} as const;

// Screen type union
export type ScreenId =
  | "lobby"
  | "battle-modal"
  | "battle-setup"
  | "matchmaking"
  | "study"
  | "stats"
  | "leaderboard";

// Each feature scene
export interface FeatureItem {
  in: number;
  out: number;
  screen: ScreenId;
  label: string;         // Caption shown on screen
  sublabel: string;      // Sub-caption (parent/student hook)
  /** Tap target position within the phone frame (414×896) */
  tap?: { x: number; y: number; frame: number };
  /** Camera pan target (0–1 from top) at end of scene */
  panY?: number;
  /** Camera scale at end of scene */
  zoomTo?: number;
}

export const TIMING = {
  PROMO: {
    duration: 900, // 30s at 30fps

    // HOOK (0–90, 3s)
    hook: {
      start: 0,
      end: 90,
    },

    // FEATURE DEMO (90–720, 21s) — 7 screens × ~90-120 frames each
    features: {
      start: 90,
      end: 720,
      items: [
        // Screen 1: Lobby (4s = 120f)
        {
          in: 0, out: 120,
          screen: "lobby" as const,
          label: "Build Your Streak",
          sublabel: "Stay consistent daily",
          tap: { x: 110, y: 650, frame: 80 }, // Tap the blue Battle card
          panY: 0.5,
          zoomTo: 1.15,
        },
        // Screen 2: Battle Mode Modal (3s = 90f)
        {
          in: 120, out: 210,
          screen: "battle-modal" as const,
          label: "Challenge Real Students",
          sublabel: "Live 1v1 battles",
          tap: { x: 207, y: 750, frame: 60 }, // Tap "Live Battle" row
          panY: 0.75,
          zoomTo: 1.2,
        },
        // Screen 3: Battle Setup (4s = 120f)
        {
          in: 210, out: 330,
          screen: "battle-setup" as const,
          label: "Pick SAT or ACT",
          sublabel: "20 questions. 30 seconds each.",
          tap: { x: 300, y: 565, frame: 60 }, // Tap "ACT" button
          panY: 0.9,
          zoomTo: 1.3,
        },
        // Screen 4: Finding Opponent (3s = 90f)
        {
          in: 330, out: 420,
          screen: "matchmaking" as const,
          label: "Matched Instantly",
          sublabel: "To a student near your level",
          panY: 0.45,
          zoomTo: 1.1,
        },
        // Screen 5: Study Mode (4s = 120f)
        {
          in: 420, out: 540,
          screen: "study" as const,
          label: "Study at Your Own Pace",
          sublabel: "Math, Reading, English & Science",
          tap: { x: 110, y: 420, frame: 60 }, // Tap "SAT" card
          panY: 0.6,
          zoomTo: 1.15,
        },
        // Screen 6: Stats (4s = 120f)
        {
          in: 540, out: 660,
          screen: "stats" as const,
          label: "Track Real Progress",
          sublabel: "See your accuracy grow every day",
          panY: 0.7,
          zoomTo: 1.2,
        },
        // Screen 7: Leaderboard (3s = 90f)
        {
          in: 660, out: 750,
          screen: "leaderboard" as const,
          label: "Rise to #1",
          sublabel: "Compete with students nationally",
          panY: 0.5,
          zoomTo: 1.1,
        },
      ] as FeatureItem[],
    },

    // ENERGY CUTS (720–780, 2s)
    energy: {
      start: 720,
      end: 780,
      words: [
        { text: "STUDY.", in: 0, out: 20, bgColor: FEATURE_ACCENTS.primary },
        { text: "COMPETE.", in: 20, out: 40, bgColor: FEATURE_ACCENTS.accent },
        { text: "WIN.", in: 40, out: 60, bgColor: FEATURE_ACCENTS.orange },
      ],
    },

    // CTA OUTRO (780–900, 4s)
    cta: {
      start: 780,
      end: 900,
    },
  },

  SHORT: {
    duration: 450, // 15s
    hook: { start: 0, end: 90 },
    features: {
      start: 90,
      end: 330,
      items: [
        {
          in: 0, out: 120,
          screen: "lobby" as const,
          label: "Build Your Streak",
          sublabel: "Stay consistent daily",
          tap: { x: 110, y: 650, frame: 80 },
        },
        {
          in: 120, out: 240,
          screen: "battle-setup" as const,
          label: "1v1 Quiz Battles",
          sublabel: "SAT & ACT prep that's actually fun",
          tap: { x: 207, y: 820, frame: 80 },
        },
      ] as FeatureItem[],
    },
    energy: {
      start: 330,
      end: 390,
      words: [
        { text: "STUDY.", in: 0, out: 20, bgColor: FEATURE_ACCENTS.primary },
        { text: "COMPETE.", in: 20, out: 40, bgColor: FEATURE_ACCENTS.accent },
        { text: "WIN.", in: 40, out: 60, bgColor: FEATURE_ACCENTS.orange },
      ],
    },
    cta: { start: 390, end: 450 },
  },
} as const;
