import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { THEME } from "../config/theme";

interface Props {
  /** Slowly pulsing accent — set to feature accent color */
  glowColor?: string;
  /**
   * Total frames of the composition (used to scale the hue-rotate range).
   * Defaults to 780 (full promo).
   */
  totalFrames?: number;
}

/**
 * Background — full-canvas dark gradient with:
 *  - Animated radial glow (per-section color, pulsing)
 *  - Animated mesh gradient layer: three soft blobs that slowly drift
 *    across the canvas with a hue-rotate filter that shifts over the full video
 *  - Subtle grid overlay with slow parallax pan
 */
export const Background: React.FC<Props> = ({
  glowColor = THEME.colors.primary,
  totalFrames = 780,
}) => {
  const frame = useCurrentFrame();

  // Slow pulsing glow
  const pulse = 0.18 + 0.06 * Math.sin(frame / 28);

  // Very slow upward pan (parallax)
  const panY = interpolate(frame, [0, totalFrames], [0, -60], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Mesh gradient: three drifting color blobs ─────────────────────────────
  // Hue slowly rotates 0→72° over the full video for a "living" feel
  const hueRotate = interpolate(frame, [0, totalFrames], [0, 72], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Blob positions oscillate independently (different frequencies + offsets)
  const blob1X = 1080 * (0.18 + 0.10 * Math.sin(frame / 180));
  const blob1Y = 1920 * (0.22 + 0.08 * Math.cos(frame / 220));

  const blob2X = 1080 * (0.72 + 0.09 * Math.cos(frame / 160));
  const blob2Y = 1920 * (0.58 + 0.07 * Math.sin(frame / 200));

  const blob3X = 1080 * (0.48 + 0.06 * Math.sin(frame / 140 + 1));
  const blob3Y = 1920 * (0.80 + 0.05 * Math.cos(frame / 190 + 2));

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        background: `linear-gradient(170deg, ${THEME.colors.bg} 0%, ${THEME.colors.bgGrad} 100%)`,
        overflow: "hidden",
      }}
    >
      {/* ── Mesh gradient layer ── */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `
            radial-gradient(circle 440px at ${blob1X}px ${blob1Y}px, #6C63FF2A 0%, transparent 100%),
            radial-gradient(circle 380px at ${blob2X}px ${blob2Y}px, #00F5D42A 0%, transparent 100%),
            radial-gradient(circle 320px at ${blob3X}px ${blob3Y}px, #FF6B3520 0%, transparent 100%)
          `,
          filter: `hue-rotate(${hueRotate}deg)`,
          // Screen blend ensures the mesh adds light without washing out the dark bg
          mixBlendMode: "screen",
          pointerEvents: "none",
        }}
      />

      {/* ── Subtle grid lines (pan upward) ── */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: `
            linear-gradient(rgba(108,99,255,0.04) 1px, transparent 1px),
            linear-gradient(90deg, rgba(108,99,255,0.04) 1px, transparent 1px)
          `,
          backgroundSize: "80px 80px",
          transform: `translateY(${panY}px)`,
          pointerEvents: "none",
        }}
      />

      {/* ── Radial glow — top-center, changes color per section ── */}
      <div
        style={{
          position: "absolute",
          top: -400,
          left: "50%",
          transform: "translateX(-50%)",
          width: 1200,
          height: 1200,
          borderRadius: "50%",
          background: `radial-gradient(ellipse at center, ${glowColor} 0%, transparent 68%)`,
          opacity: pulse,
          transition: "background 0.8s ease",
          pointerEvents: "none",
        }}
      />

      {/* ── Bottom accent glow ── */}
      <div
        style={{
          position: "absolute",
          bottom: -300,
          left: "50%",
          transform: "translateX(-50%)",
          width: 900,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(ellipse at center, ${THEME.colors.accent}44 0%, transparent 70%)`,
          opacity: 0.5 + 0.08 * Math.sin(frame / 45 + 1),
          pointerEvents: "none",
        }}
      />
    </div>
  );
};
