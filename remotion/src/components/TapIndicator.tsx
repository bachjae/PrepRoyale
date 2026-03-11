import React from "react";
import { useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";

interface Props {
  /** X position relative to the phone content div (414px wide) */
  x: number;
  /** Y position relative to the phone content div (896px tall) */
  y: number;
  /** Frame (local, relative to the scene start) when the click happens */
  tapFrame: number;
  /** Ripple color */
  color?: string;
}

/**
 * TapIndicator — A real SVG mouse cursor that glides in from the bottom-right
 * and clicks a specific UI element. Includes a ripple effect on click.
 */
export const TapIndicator: React.FC<Props> = ({
  x,
  y,
  tapFrame,
  color = "rgba(56,189,248,0.4)",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Show cursor for 30 frames before click and 20 frames after
  const local = frame - tapFrame;
  if (local < -30 || local > 25) return null;

  // Glide in from bottom-right offset
  const glideProgress = interpolate(local, [-30, 0], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const offsetX = interpolate(glideProgress, [0, 1], [80, 0]);
  const offsetY = interpolate(glideProgress, [0, 1], [80, 0]);

  // Cursor fade
  const cursorOpacity = interpolate(
    local,
    [-30, -18, 18, 25],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Click press: cursor compresses slightly at frame 0
  const clickCompress = spring({ frame: Math.max(0, local), fps, config: { damping: 10, stiffness: 300 } });
  const cursorScale = local < 0 ? 1 : interpolate(clickCompress, [0, 0.5, 1], [1, 0.75, 1]);

  // Ripple ring expands from tap point
  const rippleProgress = interpolate(local, [0, 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const rippleScale = interpolate(rippleProgress, [0, 1], [0.2, 2.5]);
  const rippleOpacity = interpolate(rippleProgress, [0, 0.2, 1], [0, 0.7, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const RIPPLE_SIZE = 48;

  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 9999 }}>
      {/* Ripple ring at tap point */}
      {local >= 0 && (
        <div style={{
          position: "absolute",
          left: x - RIPPLE_SIZE / 2,
          top: y - RIPPLE_SIZE / 2,
          width: RIPPLE_SIZE,
          height: RIPPLE_SIZE,
          borderRadius: "50%",
          background: color,
          opacity: rippleOpacity,
          transform: `scale(${rippleScale})`,
        }} />
      )}

      {/* SVG Mouse Cursor */}
      <div style={{
        position: "absolute",
        left: x + offsetX - 6, // offset so the tip of cursor lands on target
        top: y + offsetY - 4,
        opacity: cursorOpacity,
        transform: `scale(${cursorScale})`,
        transformOrigin: "4px 2px", // tip of arrow
        filter: "drop-shadow(1px 2px 4px rgba(0,0,0,0.5))",
      }}>
        {/* Standard mouse pointer arrow */}
        <svg width="28" height="34" viewBox="0 0 28 34" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path
            d="M4 2L4 28L10 22L14 30L17 28L13 20L22 20L4 2Z"
            fill="white"
            stroke="#1E293B"
            strokeWidth="2"
            strokeLinejoin="round"
          />
        </svg>
      </div>
    </div>
  );
};
