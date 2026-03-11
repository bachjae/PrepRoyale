import React from "react";
import { useCurrentFrame, useVideoConfig, interpolate, spring } from "remotion";
import { THEME } from "../config/theme";
import { KineticText } from "../components/KineticText";

interface Props {
  startFrame: number;
  endFrame: number;
  line1Frame: { in: number; out: number };
  line2Frame: { in: number; out: number };
}

/**
 * SocialProofSection — motivational stats moment (3 seconds).
 *
 * Shows a zoomed-in mock stats card plus two animated text lines.
 * To change copy: update the KineticText `text` props below.
 */
export const SocialProofSection: React.FC<Props> = ({
  startFrame,
  endFrame,
  line1Frame,
  line2Frame,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sectionProgress = interpolate(frame, [startFrame, endFrame], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const cardEntrance = spring({
    frame: frame - startFrame,
    fps,
    config: { damping: 20, stiffness: 100, mass: 1 },
    durationInFrames: 30,
  });

  const cardY = interpolate(cardEntrance, [0, 1], [80, 0]);
  const cardOpacity = interpolate(cardEntrance, [0, 0.3, 1], [0, 0.5, 1]);

  const stats = [
    { icon: "🔥", label: "7-Day Streak", value: "Keep going!", color: THEME.colors.accentOrange },
    { icon: "⚔️", label: "Battle W/L",   value: "34 / 18",     color: THEME.colors.primary },
    { icon: "📈", label: "Score Est.",    value: "1,380 SAT",   color: THEME.colors.accent },
    { icon: "✅", label: "Accuracy",      value: "81%",          color: THEME.colors.success },
  ];

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "0 60px",
      }}
    >
      {/* Section label */}
      <div
        style={{
          fontSize: 14,
          color: THEME.colors.textMuted,
          textTransform: "uppercase",
          letterSpacing: 3,
          marginBottom: 24,
          opacity: sectionProgress > 0.05 ? 1 : 0,
          fontFamily: THEME.font,
        }}
      >
        Your Progress
      </div>

      {/* Stats card */}
      <div
        style={{
          width: "100%",
          background: THEME.colors.card,
          border: `1.5px solid ${THEME.colors.cardBorder}`,
          borderRadius: 28,
          padding: "32px 36px",
          opacity: cardOpacity,
          transform: `translateY(${cardY}px)`,
          boxShadow: `0 20px 60px rgba(0,0,0,0.5), 0 0 40px ${THEME.colors.primary}22`,
          marginBottom: 40,
        }}
      >
        {stats.map((s, i) => {
          const itemEntrance = spring({
            frame: frame - startFrame - i * 5,
            fps,
            config: { damping: 18, stiffness: 110 },
            durationInFrames: 25,
          });
          const itemOpacity = Math.max(0, itemEntrance);
          const itemX = interpolate(itemEntrance, [0, 1], [-30, 0]);

          return (
            <div
              key={s.label}
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                paddingBottom: i < stats.length - 1 ? 20 : 0,
                marginBottom: i < stats.length - 1 ? 20 : 0,
                borderBottom: i < stats.length - 1 ? `1px solid ${THEME.colors.cardBorder}` : "none",
                opacity: itemOpacity,
                transform: `translateX(${itemX}px)`,
                fontFamily: THEME.font,
              }}
            >
              <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
                <span style={{ fontSize: 28 }}>{s.icon}</span>
                <span style={{ fontSize: 18, color: THEME.colors.textSub }}>{s.label}</span>
              </div>
              <span style={{ fontSize: 22, fontWeight: 800, color: s.color }}>
                {s.value}
              </span>
            </div>
          );
        })}
      </div>

      {/* Text callouts */}
      <KineticText
        text="Track your streaks and stats"
        startFrame={line1Frame.in}
        endFrame={line1Frame.out}
        anim="fadeSlide"
        dir="up"
        style={{
          fontFamily: THEME.font,
          fontWeight: 700,
          fontSize: 44,
          color: THEME.colors.white,
          textAlign: "center",
          lineHeight: 1.2,
          marginBottom: 12,
        }}
      />

      <KineticText
        text="Level up your score — one battle at a time."
        startFrame={line2Frame.in}
        endFrame={line2Frame.out}
        anim="fadeSlide"
        dir="up"
        style={{
          fontFamily: THEME.font,
          fontWeight: 400,
          fontSize: 30,
          color: THEME.colors.textSub,
          textAlign: "center",
          lineHeight: 1.4,
          maxWidth: 640,
        }}
      />
    </div>
  );
};
