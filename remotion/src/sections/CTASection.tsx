import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { THEME } from "../config/theme";
import { KineticText } from "../components/KineticText";

interface Props {
  startFrame: number;
  logo: { in: number; out: number };
  tag: { in: number; out: number };
  badge: { in: number; out: number };
}

// ── Confetti config ─────────────────────────────────────────────────────────
const PARTICLE_COUNT = 55;
const CONFETTI_DURATION = 22; // frames — burst fades out by this point
const CONFETTI_COLORS = [
  THEME.colors.accentOrange,
  THEME.colors.primary,
  THEME.colors.accent,
  THEME.colors.accentYellow,
  "#FF4081",
  "#B2FF59",
];

// Deterministic "random" using sin seeding — Remotion requires reproducible frames
function seededVal(seed: number): number {
  return Math.abs(Math.sin(seed * 9301 + 49297)) % 1;
}

/**
 * CTASection — the last 3 seconds; strong brand close with a CTA.
 *
 * Confetti burst: 55 particles fire when the badge slams in (badge.in frame),
 * spread outward with deterministic physics, and fade out over ~22 frames.
 * Uses seededVal() — no Math.random() — so every render is identical.
 *
 * To change the app name or tagline: edit the text below.
 * To add an app store badge: replace the "Coming Soon" div with an <Img>.
 * To adjust confetti: change PARTICLE_COUNT or CONFETTI_DURATION above.
 */
export const CTASection: React.FC<Props> = ({
  startFrame,
  logo,
  tag,
  badge,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Overall section entrance
  const entrance = spring({
    frame: frame - startFrame,
    fps,
    config: { damping: 22, stiffness: 130, mass: 0.9 },
    durationInFrames: 25,
  });

  // Logo scale pop
  const logoSpring = spring({
    frame: frame - logo.in,
    fps,
    config: { damping: 10, stiffness: 200, mass: 0.6 },
    durationInFrames: 20,
  });
  const logoScale = interpolate(logoSpring, [0, 1], [0.5, 1]);

  // Pulsing glow
  const glowPulse = 0.6 + 0.4 * Math.sin((frame - startFrame) / 12);

  // Badge bounce
  const badgeSpring = spring({
    frame: frame - badge.in,
    fps,
    config: { damping: 12, stiffness: 220, mass: 0.5 },
    durationInFrames: 18,
  });
  const badgeScale = interpolate(badgeSpring, [0, 1], [0.3, 1]);
  const badgeOpacity = Math.min(badgeSpring, 1);

  // ── Confetti burst (fires exactly when badge appears) ────────────────────
  const localConfettiFrame = frame - badge.in;
  const showConfetti =
    localConfettiFrame >= 0 && localConfettiFrame <= CONFETTI_DURATION;

  const particles = showConfetti
    ? Array.from({ length: PARTICLE_COUNT }, (_, i) => {
        // Deterministic angle spread across 360°
        const baseAngle = (i / PARTICLE_COUNT) * Math.PI * 2;
        const angleJitter = (seededVal(i * 7 + 1) - 0.5) * 0.8;
        const angle = baseAngle + angleJitter;

        // Speed: 14–28 px/frame
        const speed = 14 + seededVal(i * 3 + 2) * 14;

        // Particle color from brand palette
        const color = CONFETTI_COLORS[i % CONFETTI_COLORS.length];

        // Shape: square vs rounded pill (alternating)
        const isRect = i % 3 !== 0;
        const size = 8 + (i % 4) * 4;

        // Spin amount (total rotation in degrees over CONFETTI_DURATION)
        const spin = (seededVal(i * 11 + 3) * 2 - 1) * 720;

        // Physics: x and y with gravity (0.6 px/frame² downward)
        const t = localConfettiFrame;
        const x = Math.cos(angle) * speed * t;
        const y = Math.sin(angle) * speed * t + 0.6 * t * t;
        const rot = spin * (t / CONFETTI_DURATION);

        // Opacity: quick fade-in then fade-out
        const opacity = interpolate(
          t,
          [0, 4, CONFETTI_DURATION - 4, CONFETTI_DURATION],
          [0, 1, 1, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        return { x, y, rot, color, size, opacity, isRect };
      })
    : [];

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 0,
        opacity: interpolate(entrance, [0, 0.2, 1], [0, 0.6, 1]),
      }}
    >
      {/* Large radial glow behind logo */}
      <div
        style={{
          position: "absolute",
          width: 900,
          height: 900,
          borderRadius: "50%",
          background: `radial-gradient(ellipse, ${THEME.colors.primary}55 0%, transparent 65%)`,
          opacity: glowPulse * 0.7,
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          pointerEvents: "none",
        }}
      />

      {/* Sword icon */}
      <div
        style={{
          fontSize: 80,
          marginBottom: 16,
          transform: `scale(${logoScale})`,
          filter: `drop-shadow(0 0 24px ${THEME.colors.accentOrange})`,
          opacity: frame >= logo.in ? 1 : 0,
        }}
      >
        ⚔️
      </div>

      {/* App name */}
      <div
        style={{
          fontFamily: THEME.font,
          fontWeight: 900,
          fontSize: 88,
          lineHeight: 1,
          textAlign: "center",
          transform: `scale(${logoScale})`,
          opacity: frame >= logo.in ? 1 : 0,
          marginBottom: 6,
        }}
      >
        <span
          style={{
            background: `linear-gradient(135deg, ${THEME.colors.accentOrange} 0%, ${THEME.colors.primary} 50%, ${THEME.colors.accent} 100%)`,
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            filter: `drop-shadow(0 0 ${20 * glowPulse}px ${THEME.colors.primary}88)`,
          }}
        >
          Prep Royale
        </span>
      </div>

      {/* Sub-title */}
      <div
        style={{
          fontFamily: THEME.font,
          fontWeight: 300,
          fontSize: 28,
          color: THEME.colors.textSub,
          textAlign: "center",
          marginBottom: 44,
          letterSpacing: 1,
          opacity: frame >= logo.in ? 1 : 0,
          transform: `scale(${logoScale})`,
        }}
      >
        SAT/ACT Battle Royale
      </div>

      {/* Tagline */}
      <KineticText
        text="Turn test prep into your next W."
        startFrame={tag.in}
        anim="scale"
        damping={16}
        style={{
          fontFamily: THEME.font,
          fontWeight: 800,
          fontSize: 50,
          color: THEME.colors.white,
          textAlign: "center",
          lineHeight: 1.2,
          padding: "0 60px",
          marginBottom: 40,
          textShadow: "0 4px 20px rgba(0,0,0,0.8)",
        }}
      />

      {/* Coming Soon badge + confetti anchor */}
      <div style={{ position: "relative" }}>
        {/* ── Confetti particles (positioned relative to badge center) ── */}
        {particles.map((p, i) => (
          <div
            key={i}
            style={{
              position: "absolute",
              top: "50%",
              left: "50%",
              width: p.size,
              height: p.isRect ? p.size * 0.5 : p.size,
              borderRadius: p.isRect ? 2 : "50%",
              background: p.color,
              opacity: p.opacity,
              transform: `translate(calc(-50% + ${p.x}px), calc(-50% + ${p.y}px)) rotate(${p.rot}deg)`,
              willChange: "transform, opacity",
              zIndex: 40,
              boxShadow: `0 0 4px ${p.color}88`,
            }}
          />
        ))}

        {/* Badge */}
        <div
          style={{
            transform: `scale(${badgeScale})`,
            opacity: badgeOpacity,
          }}
        >
          <div
            style={{
              background: `linear-gradient(135deg, ${THEME.colors.accentOrange}, ${THEME.colors.primary})`,
              borderRadius: 60,
              padding: "18px 52px",
              fontFamily: THEME.font,
              fontWeight: 800,
              fontSize: 32,
              color: THEME.colors.white,
              textAlign: "center",
              boxShadow: `0 8px 40px ${THEME.colors.primary}88, 0 0 0 3px rgba(255,255,255,0.15)`,
              letterSpacing: 1,
              position: "relative",
              zIndex: 2,
            }}
          >
            Coming Soon 🚀
          </div>
        </div>
      </div>

      {/* "Available on" note */}
      <div
        style={{
          marginTop: 20,
          fontSize: 22,
          color: THEME.colors.textMuted,
          fontFamily: THEME.font,
          opacity: badgeOpacity * 0.7,
        }}
      >
        Android · iOS
      </div>
    </div>
  );
};
