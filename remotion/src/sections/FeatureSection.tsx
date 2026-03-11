import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { THEME } from "../config/theme";
import { PhoneFrame } from "../components/PhoneFrame";
import { FeatureCallout } from "../components/FeatureCallout";
import { MockScreen, ScreenType } from "../components/MockAppScreens";

type FeatureItem = {
  in: number;
  out: number;
  icon: string;
  label: string;
  sub: string;
  screen: ScreenType;
  accent: string;
};

interface Props {
  items: readonly FeatureItem[];
}

// Cross-dissolve duration in frames (both screens visible simultaneously)
const DISSOLVE_FRAMES = 12;

/**
 * FeatureSection — cycles through app feature showcases.
 *
 * Screen transitions use a true cross-dissolve: the previous screen fades out
 * while the new screen fades in over DISSOLVE_FRAMES frames simultaneously.
 *
 * To add / remove features: edit TIMING.features.items in timing.ts.
 * To change dissolve speed: adjust DISSOLVE_FRAMES above.
 */
export const FeatureSection: React.FC<Props> = ({ items }) => {
  const frame = useCurrentFrame();

  // Find active and previous feature
  const activeIndex = items.findIndex((item) => frame >= item.in && frame < item.out);
  const active = activeIndex >= 0 ? items[activeIndex] : null;
  const prevFeature = activeIndex > 0 ? items[activeIndex - 1] : null;

  // Is the current feature in its opening cross-dissolve window?
  const isDissolving = active !== null && frame < active.in + DISSOLVE_FRAMES;

  // ── Current screen opacity ────────────────────────────────────────────────
  const currentOpacity = active
    ? interpolate(
        frame,
        [active.in, active.in + DISSOLVE_FRAMES],
        [0, 1],
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
      )
    : 0;

  // ── Previous screen opacity (fades OUT during dissolve window) ────────────
  const prevOpacity =
    prevFeature && isDissolving
      ? interpolate(
          frame,
          [active!.in, active!.in + DISSOLVE_FRAMES],
          [1, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        )
      : 0;

  // Slight phone Z-tilt alternates per feature for visual rhythm
  const tilt = active ? (activeIndex % 2 === 0 ? -1.5 : 1.5) : 0;

  // Progress dot fill
  const progress = active
    ? interpolate(frame, [active.in, active.out], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : 0;

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      {/* ── Progress indicator dots ── */}
      <div
        style={{
          position: "absolute",
          top: 60,
          left: "50%",
          transform: "translateX(-50%)",
          display: "flex",
          gap: 10,
          zIndex: 20,
        }}
      >
        {items.map((item, i) => {
          const isPast = frame >= item.out;
          const isCurrent = i === activeIndex;
          return (
            <div
              key={i}
              style={{
                height: 6,
                borderRadius: 3,
                background: isPast
                  ? "rgba(255,255,255,0.6)"
                  : isCurrent
                  ? item.accent
                  : "rgba(255,255,255,0.2)",
                width: isCurrent ? 24 + 20 * progress : 6,
                boxShadow: isCurrent ? `0 0 10px ${item.accent}` : "none",
              }}
            />
          );
        })}
      </div>

      {/* ── Phone frame with cross-dissolve screens ── */}
      {active && (
        <PhoneFrame
          enterFrame={items[0].in} // phone enters once at the first feature, stays
          tilt={tilt}
        >
          {/* Previous screen — fades out during dissolve */}
          {prevFeature && isDissolving && (
            <div
              style={{
                position: "absolute",
                inset: 0,
                opacity: prevOpacity,
                zIndex: 1,
              }}
            >
              <MockScreen type={prevFeature.screen} />
            </div>
          )}

          {/* Current screen — fades in during dissolve, then fully visible */}
          <div
            style={{
              position: "absolute",
              inset: 0,
              opacity: currentOpacity,
              zIndex: 2,
            }}
          >
            <MockScreen type={active.screen} />
          </div>
        </PhoneFrame>
      )}

      {/* ── Feature callout badges ── */}
      {items.map((item) => (
        <div
          key={item.label}
          style={{
            position: "absolute",
            bottom: 140,
            left: 40,
            zIndex: 30,
          }}
        >
          <FeatureCallout
            icon={item.icon}
            label={item.label}
            sub={item.sub}
            startFrame={item.in}
            endFrame={item.out}
            accent={item.accent}
            side="left"
          />
        </div>
      ))}

      {/* ── Accent line below phone ── */}
      {active && (
        <div
          style={{
            position: "absolute",
            bottom: 370,
            left: "50%",
            transform: "translateX(-50%)",
            width: interpolate(frame, [active.in, active.in + 20], [0, 200], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            height: 2,
            background: `linear-gradient(90deg, transparent, ${active.accent}, transparent)`,
            opacity: 0.7,
          }}
        />
      )}
    </div>
  );
};
