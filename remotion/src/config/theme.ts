/**
 * THEME CONFIG — tweaked to match Prep Royale app exactly
 */
export const THEME = {
  colors: {
    // Page backgrounds
    bg: "#0F172A", // Slate 900 for dark contrasting background to the real app UI
    bgGrad: "#0F172A", // Removed gradient

    // Brand / accent matches Flutter app
    primary: "#38BDF8",     // Sky 400
    primaryGlow: "#38BDF800",
    secondary: "#0EA5E9",   // Sky 500
    accent: "#06B6D4",      // Teal/Cyan
    accentOrange: "#F97316", // Streak Orange
    accentYellow: "#EAB308", // Accuracy Yellow
    success: "#22C55E",
    error: "#EF4444",

    // Text
    white: "#FFFFFF",
    textSub: "rgba(255,255,255,0.72)",
    textMuted: "rgba(255,255,255,0.40)",
    textPrimary: "#1E293B",

    // Cards / overlays matching flutter app's white cards
    card: "#FFFFFF",
    cardBorder: "#E2E8F0",
    overlay: "rgba(15, 23, 42, 0.78)",
    overlayHeavy: "rgba(15, 23, 42, 0.92)",
  },

  // Font stack
  font: '"Poppins", "Segoe UI", system-ui, -apple-system, sans-serif',

  fontSizes: {
    hero: 110,
    title: 76,
    subtitle: 52,
    body: 36,
    caption: 26,
  },

  phone: {
    w: 520,
    h: 1040,
    radius: 48,
    x: (1080 - 520) / 2,
    y: (1920 - 1040) / 2,
  },
} as const;
