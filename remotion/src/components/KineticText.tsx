import React from "react";
import { useCurrentFrame, useVideoConfig, interpolate, spring } from "remotion";

type AnimType = "fadeSlide" | "scale" | "fade";
type SlideDir = "up" | "down" | "left" | "right";

interface Props {
  text: string;
  startFrame: number;
  /** If supplied, the text fades out at this frame */
  endFrame?: number;
  style?: React.CSSProperties;
  anim?: AnimType;
  dir?: SlideDir;
  /** Spring damping — lower = more bounce */
  damping?: number;
}

/**
 * KineticText — animated headline component.
 *
 * To change copy: just update the `text` prop in the parent section.
 * To change animation feel: adjust `damping` prop or the spring config below.
 */
export const KineticText: React.FC<Props> = ({
  text,
  startFrame,
  endFrame,
  style = {},
  anim = "fadeSlide",
  dir = "up",
  damping = 18,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Entrance ──────────────────────────────────────────────────────
  const entranceProgress = spring({
    frame: frame - startFrame,
    fps,
    config: { damping, stiffness: 120, mass: 0.8 },
    durationInFrames: 22,
  });

  // ── Exit (optional) ───────────────────────────────────────────────
  const exitOpacity = endFrame
    ? interpolate(frame, [endFrame - 12, endFrame], [1, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : 1;

  const opacity = Math.min(entranceProgress, exitOpacity);

  // ── Transform ─────────────────────────────────────────────────────
  let transform = "none";
  const OFFSET = 34;

  if (anim === "fadeSlide") {
    const slideValue = interpolate(entranceProgress, [0, 1], [
      dir === "up" ? OFFSET : dir === "down" ? -OFFSET : 0,
      0,
    ]);
    const xValue = interpolate(entranceProgress, [0, 1], [
      dir === "left" ? OFFSET : dir === "right" ? -OFFSET : 0,
      0,
    ]);
    transform =
      dir === "left" || dir === "right"
        ? `translateX(${xValue}px)`
        : `translateY(${slideValue}px)`;
  } else if (anim === "scale") {
    const s = interpolate(entranceProgress, [0, 1], [0.65, 1]);
    transform = `scale(${s})`;
  }

  return (
    <div
      style={{
        opacity,
        transform,
        willChange: "opacity, transform",
        ...style,
      }}
    >
      {text}
    </div>
  );
};
