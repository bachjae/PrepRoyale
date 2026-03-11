import React from "react";
import { useCurrentFrame, useVideoConfig, interpolate, spring } from "remotion";
import { THEME } from "../config/theme";

interface Props {
  icon: string;
  label: string;
  sub: string;
  startFrame: number;
  endFrame: number;
  accent?: string;
  /** Which side of the phone frame to float on */
  side?: "left" | "right" | "bottom";
}

/**
 * FeatureCallout — animated badge that flies in beside the phone mockup.
 *
 * To change copy: update `label` and `sub` from the timing config.
 * To change accent color: update the `accent` prop or TIMING items.
 */
export const FeatureCallout: React.FC<Props> = ({
  icon,
  label,
  sub,
  startFrame,
  endFrame,
  accent = THEME.colors.accent,
  side = "left",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Entrance spring
  const enter = spring({
    frame: frame - startFrame,
    fps,
    config: { damping: 16, stiffness: 100, mass: 0.9 },
    durationInFrames: 28,
  });

  // Exit fade
  const exitFade = interpolate(frame, [endFrame - 14, endFrame], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const opacity = Math.min(enter, exitFade);

  // Slide in from the chosen side
  const slideStart = side === "left" ? -120 : side === "right" ? 120 : 0;
  const yStart = side === "bottom" ? 80 : 0;

  const translateX = interpolate(enter, [0, 1], [slideStart, 0]);
  const translateY = interpolate(enter, [0, 1], [yStart, 0]);

  const scalePop = interpolate(enter, [0, 0.6, 1], [0.7, 1.06, 1]);

  return (
    <div
      style={{
        position: "absolute",
        opacity,
        transform: `translate(${translateX}px, ${translateY}px) scale(${scalePop})`,
        willChange: "opacity, transform",

        // Badge card
        background: THEME.colors.overlayHeavy,
        border: `2px solid ${accent}`,
        borderRadius: 24,
        padding: "22px 32px",
        minWidth: 340,
        maxWidth: 420,
        boxShadow: `0 0 32px ${accent}55, 0 8px 32px rgba(0,0,0,0.6)`,

        display: "flex",
        alignItems: "center",
        gap: 20,
      }}
    >
      {/* Icon circle */}
      <div
        style={{
          width: 72,
          height: 72,
          borderRadius: "50%",
          background: `${accent}22`,
          border: `2px solid ${accent}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 34,
          flexShrink: 0,
        }}
      >
        {icon}
      </div>

      {/* Text */}
      <div>
        <div
          style={{
            fontFamily: THEME.font,
            fontWeight: 800,
            fontSize: 30,
            color: THEME.colors.white,
            lineHeight: 1.1,
          }}
        >
          {label}
        </div>
        <div
          style={{
            fontFamily: THEME.font,
            fontWeight: 400,
            fontSize: 22,
            color: THEME.colors.textSub,
            marginTop: 6,
          }}
        >
          {sub}
        </div>
      </div>
    </div>
  );
};
