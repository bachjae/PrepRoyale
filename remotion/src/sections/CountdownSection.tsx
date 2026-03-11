import React from "react";
import { useCurrentFrame, useVideoConfig, interpolate, spring, AbsoluteFill } from "remotion";
import { loadFont } from "@remotion/google-fonts/Orbitron";
import { THEME } from "../config/theme";

// Load Orbitron font — called at module level (Remotion requirement)
const { fontFamily: orbitron } = loadFont();

interface Props {
  /** Absolute frame where this section starts in the composition */
  startFrame: number;
}

// ── Helper: one number slam ────────────────────────────────────────────────────

interface NumberSlamProps {
  digit: string;
  /** Relative frame this digit becomes active */
  activeAt: number;
  /** Relative frame this digit disappears */
  exitAt: number;
  color?: string;
  fontSize?: number;
}

const NumberSlam: React.FC<NumberSlamProps> = ({
  digit,
  activeAt,
  exitAt,
  color = THEME.colors.white,
  fontSize = 280,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const localFrame = frame; // already offset by Sequence

  // Entrance — explosive spring (low damping = big bounce)
  const entrance = spring({
    frame: localFrame - activeAt,
    fps,
    config: { damping: 8, stiffness: 260, mass: 0.5 },
    durationInFrames: 14,
  });

  // Exit — quick 2-frame opacity fade when the next number appears
  const exitOpacity = interpolate(
    localFrame,
    [exitAt - 2, exitAt],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const scale = interpolate(entrance, [0, 1], [2.4, 1]);
  const opacity = Math.min(
    interpolate(entrance, [0, 0.05, 1], [0, 1, 1]),
    exitOpacity
  );

  // Subtle radial glow burst tied to entrance
  const glowOpacity = interpolate(entrance, [0, 0.3, 1], [0.9, 0.4, 0]);

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        opacity,
      }}
    >
      {/* Glow burst */}
      <div
        style={{
          position: "absolute",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(ellipse, ${color}44 0%, transparent 65%)`,
          opacity: glowOpacity,
        }}
      />

      {/* Number */}
      <div
        style={{
          fontFamily: orbitron,
          fontWeight: 900,
          fontSize,
          color,
          transform: `scale(${scale})`,
          textShadow: `0 0 60px ${color}99, 0 0 120px ${color}44`,
          lineHeight: 1,
          userSelect: "none",
        }}
      >
        {digit}
      </div>
    </div>
  );
};

// ── Main countdown component ───────────────────────────────────────────────────

/**
 * CountdownSection — "3... 2... 1... FIGHT!" transition (30 frames = 1 second).
 *
 * Lives between the hook and the features section.
 * Font: Orbitron (Google Fonts, loaded at module level).
 *
 * Frame layout (relative to startFrame, inside its Sequence):
 *   0–6   → "3" slams in and holds
 *   6–12  → "2" slams in (3 fades out)
 *   12–18 → "1" slams in (2 fades out)
 *   18–30 → "FIGHT!" slams in with gradient + screen shake + white flash
 */
export const CountdownSection: React.FC<Props> = ({ startFrame }) => {
  const frame = useCurrentFrame(); // offset by Sequence — relative frame
  const { fps } = useVideoConfig();

  // ── FIGHT! entrance ──────────────────────────────────────────────────────────
  const fightEntrance = spring({
    frame: frame - 18,
    fps,
    config: { damping: 6, stiffness: 300, mass: 0.4 },
    durationInFrames: 14,
  });

  const fightScale = interpolate(fightEntrance, [0, 1], [3.2, 1]);
  const fightOpacity = interpolate(fightEntrance, [0, 0.08, 1], [0, 1, 1]);

  // ── Screen shake (tied to FIGHT!) ────────────────────────────────────────────
  const shakeActive = frame >= 18 && frame <= 26;
  const shakeDecay = interpolate(frame, [18, 26], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const shakeX = shakeActive ? Math.sin(frame * 1.8) * 6 * shakeDecay : 0;
  const shakeY = shakeActive ? Math.cos(frame * 2.3) * 3 * shakeDecay : 0;

  // ── White flash when FIGHT! appears ──────────────────────────────────────────
  const flashOpacity = interpolate(frame, [18, 21, 25], [0.55, 0.55, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Background (dark overlay) ────────────────────────────────────────────────
  const bgOpacity = interpolate(frame, [0, 4, 26, 30], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        transform: `translate(${shakeX}px, ${shakeY}px)`,
      }}
    >
      {/* Dark overlay — fades in at start, fades out at end */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: THEME.colors.overlayHeavy,
          opacity: bgOpacity,
        }}
      />

      {/* White flash */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "#FFFFFF",
          opacity: flashOpacity,
          pointerEvents: "none",
          zIndex: 20,
        }}
      />

      {/* "3" */}
      <NumberSlam digit="3" activeAt={0} exitAt={6} color={THEME.colors.accentOrange} />

      {/* "2" */}
      {frame >= 6 && (
        <NumberSlam digit="2" activeAt={6} exitAt={12} color={THEME.colors.primary} />
      )}

      {/* "1" */}
      {frame >= 12 && (
        <NumberSlam digit="1" activeAt={12} exitAt={18} color={THEME.colors.accent} />
      )}

      {/* "FIGHT!" */}
      {frame >= 18 && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: fightOpacity,
          }}
        >
          {/* Outer glow ring */}
          <div
            style={{
              position: "absolute",
              width: 900,
              height: 400,
              borderRadius: "50%",
              background: `radial-gradient(ellipse, ${THEME.colors.accentOrange}55 0%, transparent 70%)`,
              opacity: interpolate(fightEntrance, [0, 0.5, 1], [0, 0.8, 0.4]),
            }}
          />

          <div
            style={{
              fontFamily: orbitron,
              fontWeight: 900,
              fontSize: 156,
              transform: `scale(${fightScale})`,
              background: `linear-gradient(135deg, ${THEME.colors.accentOrange} 0%, ${THEME.colors.primary} 50%, ${THEME.colors.accent} 100%)`,
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              filter: `drop-shadow(0 0 30px ${THEME.colors.accentOrange}99) drop-shadow(0 0 60px ${THEME.colors.primary}66)`,
              lineHeight: 1,
              letterSpacing: 8,
              userSelect: "none",
            }}
          >
            FIGHT!
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
