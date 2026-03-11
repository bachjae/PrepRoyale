/**
 * MockAppScreens — pixel-art-style recreations of the Prep Royale app UI.
 *
 * Each export is a standalone React component sized to fill the PhoneFrame
 * (520 × 1040 px).  The designs mimic the actual Flutter app's dark theme,
 * purple/cyan palette, and layout so the promo feels authentic without
 * needing a real screen recording.
 *
 * To swap in a real recording later, replace <MockXxxScreen /> usages in
 * FeatureSection.tsx with a <Video src={staticFile('app-recording.mp4')} />
 * wrapped in an appropriate clip/seek.
 */

import React from "react";
import { useCurrentFrame } from "remotion";
import { THEME } from "../config/theme";

// ─── Shared helpers ────────────────────────────────────────────────────────────

const T = THEME.colors;

const Bar: React.FC<{
  value: number; // 0–1
  color: string;
  height?: number;
  radius?: number;
  bg?: string;
}> = ({ value, color, height = 10, radius = 6, bg = "rgba(255,255,255,0.10)" }) => (
  <div
    style={{
      width: "100%",
      height,
      borderRadius: radius,
      background: bg,
      overflow: "hidden",
    }}
  >
    <div
      style={{
        width: `${value * 100}%`,
        height: "100%",
        background: color,
        borderRadius: radius,
        boxShadow: `0 0 8px ${color}88`,
      }}
    />
  </div>
);

const Avatar: React.FC<{
  size?: number;
  color?: string;
  emoji?: string;
  label?: string;
}> = ({ size = 60, color = T.primary, emoji = "🧑‍🎓", label }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        background: `${color}33`,
        border: `2px solid ${color}`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: size * 0.5,
      }}
    >
      {emoji}
    </div>
    {label && (
      <div style={{ fontSize: 14, color: T.textSub, fontFamily: THEME.font }}>
        {label}
      </div>
    )}
  </div>
);

const ScreenWrapper: React.FC<{ children: React.ReactNode; bg?: string }> = ({
  children,
  bg = T.bg,
}) => (
  <div
    style={{
      width: "100%",
      height: "100%",
      background: bg,
      fontFamily: THEME.font,
      color: T.white,
      overflow: "hidden",
      position: "relative",
      paddingTop: 50, // space for notch
    }}
  >
    {children}
  </div>
);

// ─── HOME SCREEN ───────────────────────────────────────────────────────────────

export const MockHomeScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const xpPulse = 0.72 + 0.05 * Math.sin(frame / 20);

  return (
    <ScreenWrapper>
      {/* Header */}
      <div
        style={{
          padding: "16px 24px 10px",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div>
          <div style={{ fontSize: 13, color: T.textMuted }}>Good morning,</div>
          <div style={{ fontSize: 22, fontWeight: 800 }}>AlexStudent 🔥</div>
        </div>
        <div
          style={{
            background: `${T.accentYellow}22`,
            border: `1.5px solid ${T.accentYellow}`,
            borderRadius: 12,
            padding: "6px 14px",
            fontSize: 14,
            color: T.accentYellow,
            fontWeight: 700,
          }}
        >
          🔥 7 day streak
        </div>
      </div>

      {/* Level card */}
      <div
        style={{
          margin: "6px 18px 14px",
          background: `linear-gradient(135deg, ${T.primary}33, ${T.accent}18)`,
          border: `1.5px solid ${T.primary}55`,
          borderRadius: 20,
          padding: "16px 20px",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: 10,
          }}
        >
          <div>
            <div style={{ fontSize: 11, color: T.textMuted, textTransform: "uppercase", letterSpacing: 1 }}>
              Level
            </div>
            <div style={{ fontSize: 36, fontWeight: 900, color: T.accent }}>
              12
            </div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: 11, color: T.textMuted }}>XP</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: T.accentYellow }}>
              2,840 / 4,000
            </div>
          </div>
        </div>
        <Bar value={xpPulse * 0.71} color={T.accent} height={8} />
      </div>

      {/* Quick stats row */}
      {[
        { label: "SAT Score Est.", value: "1,380", color: T.primary },
        { label: "Accuracy", value: "81%", color: T.success },
        { label: "Battles Won", value: "34", color: T.accentOrange },
      ].map((s) => (
        <div
          key={s.label}
          style={{
            margin: "0 18px 10px",
            background: T.card,
            border: `1px solid ${T.cardBorder}`,
            borderRadius: 14,
            padding: "12px 18px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <span style={{ fontSize: 14, color: T.textSub }}>{s.label}</span>
          <span style={{ fontSize: 20, fontWeight: 800, color: s.color }}>{s.value}</span>
        </div>
      ))}

      {/* Action buttons */}
      <div style={{ display: "flex", gap: 12, padding: "8px 18px" }}>
        <div
          style={{
            flex: 1,
            background: `linear-gradient(135deg, ${T.accentOrange}, #FF4500)`,
            borderRadius: 18,
            padding: "20px 10px",
            textAlign: "center",
            fontWeight: 800,
            fontSize: 17,
            boxShadow: `0 6px 24px ${T.accentOrange}55`,
          }}
        >
          ⚔️{"\n"}BATTLE NOW
        </div>
        <div
          style={{
            flex: 1,
            background: `linear-gradient(135deg, ${T.accent}44, ${T.primary}44)`,
            border: `1.5px solid ${T.accent}`,
            borderRadius: 18,
            padding: "20px 10px",
            textAlign: "center",
            fontWeight: 800,
            fontSize: 17,
            color: T.accent,
          }}
        >
          🧘{"\n"}ZEN MODE
        </div>
      </div>
    </ScreenWrapper>
  );
};

// ─── BATTLE SCREEN ─────────────────────────────────────────────────────────────

export const MockBattleScreen: React.FC = () => {
  const frame = useCurrentFrame();

  // Animate health bars decreasing slightly over time for drama
  const playerHP = Math.max(0.45, 0.85 - 0.001 * frame);
  const opponentHP = Math.max(0.3, 0.72 - 0.002 * frame);

  const timerVal = Math.max(0, 28 - Math.floor(frame / 12));
  const timerColor = timerVal < 10 ? T.accentOrange : T.accent;

  return (
    <ScreenWrapper bg={`linear-gradient(180deg, #0A0020 0%, ${T.bg} 100%)`}>
      {/* VS Header */}
      <div
        style={{
          textAlign: "center",
          padding: "6px 0 14px",
          fontSize: 13,
          color: T.textMuted,
          textTransform: "uppercase",
          letterSpacing: 2,
        }}
      >
        BATTLE • Question 8 / 20
      </div>

      {/* Players row */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-around",
          alignItems: "flex-start",
          padding: "0 16px 14px",
        }}
      >
        {/* Player */}
        <div style={{ width: "40%", display: "flex", flexDirection: "column", gap: 6 }}>
          <Avatar size={52} color={T.primary} emoji="🧑‍🎓" label="You" />
          <div style={{ fontSize: 12, color: T.textSub, textAlign: "center" }}>
            HP: {Math.round(playerHP * 100)}
          </div>
          <Bar value={playerHP} color={T.success} height={10} />
        </div>

        {/* VS badge */}
        <div
          style={{
            width: 48,
            height: 48,
            borderRadius: "50%",
            background: `linear-gradient(135deg, ${T.accentOrange}, ${T.primary})`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontWeight: 900,
            fontSize: 14,
            marginTop: 4,
            boxShadow: `0 0 20px ${T.primary}66`,
          }}
        >
          VS
        </div>

        {/* Opponent */}
        <div style={{ width: "40%", display: "flex", flexDirection: "column", gap: 6 }}>
          <Avatar size={52} color={T.accentOrange} emoji="🎮" label="Rival99" />
          <div style={{ fontSize: 12, color: T.textSub, textAlign: "center" }}>
            HP: {Math.round(opponentHP * 100)}
          </div>
          <Bar value={opponentHP} color={T.accentOrange} height={10} />
        </div>
      </div>

      {/* Timer */}
      <div style={{ textAlign: "center", marginBottom: 10 }}>
        <span
          style={{
            fontFamily: "monospace",
            fontSize: 32,
            fontWeight: 900,
            color: timerColor,
            textShadow: `0 0 16px ${timerColor}`,
          }}
        >
          {String(timerVal).padStart(2, "0")}s
        </span>
      </div>

      {/* Question card */}
      <div
        style={{
          margin: "0 14px 14px",
          background: T.card,
          border: `1.5px solid ${T.cardBorder}`,
          borderRadius: 18,
          padding: "16px 18px",
        }}
      >
        <div style={{ fontSize: 11, color: T.primary, marginBottom: 8, textTransform: "uppercase", letterSpacing: 1 }}>
          Math · Algebra
        </div>
        <div style={{ fontSize: 14, lineHeight: 1.5, color: T.white }}>
          If 3x + 7 = 22, what is the value of{" "}
          <span style={{ color: T.accent, fontWeight: 700 }}>6x − 4</span>?
        </div>
      </div>

      {/* Answer choices */}
      {["A) 26", "B) 30 ✓", "C) 14", "D) 18"].map((choice, i) => {
        const isCorrect = i === 1;
        const isSelected = i === 0 && frame > 40;
        return (
          <div
            key={choice}
            style={{
              margin: "0 14px 8px",
              background: isCorrect && frame > 55
                ? `${T.success}22`
                : isSelected
                ? `${T.accentOrange}22`
                : T.card,
              border: `1.5px solid ${
                isCorrect && frame > 55 ? T.success : isSelected ? T.accentOrange : T.cardBorder
              }`,
              borderRadius: 12,
              padding: "11px 16px",
              fontSize: 13,
              color: T.white,
            }}
          >
            {choice}
          </div>
        );
      })}
    </ScreenWrapper>
  );
};

// ─── ZEN MODE SCREEN ───────────────────────────────────────────────────────────

export const MockZenScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = Math.min(1, frame / 90);

  return (
    <ScreenWrapper bg={`linear-gradient(180deg, #050518 0%, #0A0A2A 100%)`}>
      {/* Zen header */}
      <div
        style={{
          textAlign: "center",
          padding: "10px 0 20px",
        }}
      >
        <div style={{ fontSize: 11, color: T.accent, letterSpacing: 2, textTransform: "uppercase" }}>
          ZEN MODE
        </div>
        <div style={{ fontSize: 22, fontWeight: 800, marginTop: 4 }}>SAT • Reading</div>
        <div
          style={{
            display: "inline-block",
            marginTop: 8,
            background: `${T.accent}22`,
            border: `1px solid ${T.accent}44`,
            borderRadius: 20,
            padding: "4px 16px",
            fontSize: 12,
            color: T.accent,
          }}
        >
          Question 3 of 15
        </div>
      </div>

      {/* Progress bar */}
      <div style={{ padding: "0 20px 18px" }}>
        <Bar value={progress * 0.2} color={T.accent} height={6} />
      </div>

      {/* Question card */}
      <div
        style={{
          margin: "0 16px 14px",
          background: `${T.accent}0D`,
          border: `1.5px solid ${T.accent}33`,
          borderRadius: 18,
          padding: "18px 18px",
        }}
      >
        <div style={{ fontSize: 11, color: T.accent, marginBottom: 10, textTransform: "uppercase", letterSpacing: 1 }}>
          Evidence-Based Reading
        </div>
        <div style={{ fontSize: 13, lineHeight: 1.6, color: T.textSub }}>
          The author primarily uses the word "ephemeral" in paragraph 3 to
          suggest that the effects of the policy are...
        </div>
      </div>

      {/* Choices */}
      {[
        { label: "A", text: "Long-lasting and widespread", sel: false },
        { label: "B", text: "Short-lived and temporary", sel: true },
        { label: "C", text: "Deeply controversial", sel: false },
        { label: "D", text: "Surprisingly effective", sel: false },
      ].map((c) => (
        <div
          key={c.label}
          style={{
            margin: "0 16px 8px",
            background: c.sel ? `${T.accent}22` : T.card,
            border: `1.5px solid ${c.sel ? T.accent : T.cardBorder}`,
            borderRadius: 12,
            padding: "11px 16px",
            display: "flex",
            gap: 12,
            alignItems: "center",
          }}
        >
          <span
            style={{
              width: 26,
              height: 26,
              borderRadius: "50%",
              background: c.sel ? T.accent : "rgba(255,255,255,0.1)",
              color: c.sel ? T.bg : T.white,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 12,
              fontWeight: 700,
              flexShrink: 0,
            }}
          >
            {c.label}
          </span>
          <span style={{ fontSize: 13, color: T.white }}>{c.text}</span>
        </div>
      ))}

      {/* Timer */}
      <div style={{ textAlign: "center", marginTop: 8, fontSize: 13, color: T.textMuted }}>
        ⏱ No time pressure — take your time
      </div>
    </ScreenWrapper>
  );
};

// ─── QUESTION SCREEN (daily) ───────────────────────────────────────────────────

export const MockQuestionScreen: React.FC = () => {
  return (
    <ScreenWrapper>
      {/* Header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          padding: "10px 20px 16px",
        }}
      >
        <div>
          <div style={{ fontSize: 11, color: T.textMuted, textTransform: "uppercase", letterSpacing: 1 }}>
            Daily Challenge
          </div>
          <div style={{ fontSize: 18, fontWeight: 800 }}>📅 Today's SAT</div>
        </div>
        <div
          style={{
            background: `${T.accentYellow}22`,
            border: `1px solid ${T.accentYellow}`,
            borderRadius: 10,
            padding: "6px 12px",
            fontSize: 13,
            color: T.accentYellow,
            fontWeight: 700,
          }}
        >
          +50 XP
        </div>
      </div>

      {/* Streak badge */}
      <div style={{ margin: "0 20px 14px" }}>
        <Bar value={3 / 5} color={T.accentOrange} height={8} />
        <div style={{ fontSize: 11, color: T.textMuted, marginTop: 5, textAlign: "right" }}>
          3 of 5 complete
        </div>
      </div>

      {/* Question */}
      <div
        style={{
          margin: "0 16px 16px",
          background: T.card,
          border: `1px solid ${T.cardBorder}`,
          borderRadius: 18,
          padding: "18px",
        }}
      >
        <div style={{ fontSize: 11, color: T.accentOrange, marginBottom: 8, textTransform: "uppercase", letterSpacing: 1 }}>
          ACT · Science · Medium
        </div>
        <div style={{ fontSize: 14, lineHeight: 1.6 }}>
          A scientist measures the rate of photosynthesis at different light intensities.
          Which graph best represents the relationship between light intensity and O₂ production?
        </div>
      </div>

      {/* Choices */}
      {["A) Linear increase", "B) Logarithmic curve ✓", "C) Exponential decay", "D) No relationship"].map(
        (c, i) => (
          <div
            key={c}
            style={{
              margin: "0 16px 8px",
              background: i === 1 ? `${T.success}22` : T.card,
              border: `1.5px solid ${i === 1 ? T.success : T.cardBorder}`,
              borderRadius: 12,
              padding: "12px 16px",
              fontSize: 13,
            }}
          >
            {c}
          </div>
        )
      )}
    </ScreenWrapper>
  );
};

// ─── PROFILE / STATS SCREEN ────────────────────────────────────────────────────

export const MockProfileScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const xp = 0.6 + 0.05 * Math.sin(frame / 25);

  return (
    <ScreenWrapper>
      {/* Avatar & name */}
      <div style={{ textAlign: "center", padding: "12px 0 16px" }}>
        <div
          style={{
            width: 80,
            height: 80,
            borderRadius: "50%",
            background: `linear-gradient(135deg, ${T.primary}, ${T.accent})`,
            margin: "0 auto 10px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 36,
            border: `3px solid ${T.accent}`,
            boxShadow: `0 0 24px ${T.accent}55`,
          }}
        >
          🧑‍🎓
        </div>
        <div style={{ fontSize: 22, fontWeight: 800 }}>AlexStudent</div>
        <div style={{ fontSize: 13, color: T.textSub, marginTop: 2 }}>SAT Warrior • Lv. 12</div>
        <div
          style={{
            display: "inline-flex",
            gap: 8,
            marginTop: 8,
            background: `${T.accentOrange}22`,
            border: `1px solid ${T.accentOrange}`,
            borderRadius: 20,
            padding: "5px 14px",
            fontSize: 13,
            color: T.accentOrange,
          }}
        >
          🔥 7-day streak
        </div>
      </div>

      {/* XP bar */}
      <div style={{ padding: "0 22px 16px" }}>
        <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: T.textMuted, marginBottom: 6 }}>
          <span>XP to Level 13</span>
          <span style={{ color: T.accent }}>2,840 / 4,000</span>
        </div>
        <Bar value={xp} color={T.accent} height={10} />
      </div>

      {/* Stats grid */}
      {[
        ["📚", "Questions Answered", "482"],
        ["✅", "Accuracy Rate", "81%"],
        ["⚔️", "Battle W/L", "34 / 18"],
        ["📈", "SAT Score Est.", "1,380"],
      ].map(([icon, label, val]) => (
        <div
          key={label}
          style={{
            margin: "0 16px 9px",
            background: T.card,
            border: `1px solid ${T.cardBorder}`,
            borderRadius: 14,
            padding: "12px 16px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <span style={{ fontSize: 13, color: T.textSub }}>
            {icon} {label}
          </span>
          <span style={{ fontSize: 17, fontWeight: 700, color: T.white }}>{val}</span>
        </div>
      ))}
    </ScreenWrapper>
  );
};

// ─── LEADERBOARD SCREEN ────────────────────────────────────────────────────────

export const MockLeaderboardScreen: React.FC = () => {
  const players = [
    { rank: 1, name: "TopScorer", score: "9,200 XP", emoji: "🥇", color: T.accentYellow },
    { rank: 2, name: "StudyKing", score: "8,750 XP", emoji: "🥈", color: "#C0C0C0" },
    { rank: 3, name: "ACEster",   score: "8,100 XP", emoji: "🥉", color: "#CD7F32" },
    { rank: 4, name: "AlexStudent ← You", score: "2,840 XP", emoji: "⚔️", color: T.accent },
    { rank: 5, name: "QuizWizard", score: "2,700 XP", emoji: "🎯", color: T.textSub },
  ];

  return (
    <ScreenWrapper>
      <div style={{ textAlign: "center", padding: "10px 0 16px" }}>
        <div style={{ fontSize: 11, color: T.textMuted, letterSpacing: 2, textTransform: "uppercase" }}>
          Global Rankings
        </div>
        <div style={{ fontSize: 24, fontWeight: 900, marginTop: 4 }}>🏆 Leaderboard</div>
      </div>

      {/* Tab row */}
      <div style={{ display: "flex", gap: 8, padding: "0 16px 14px" }}>
        {["Global", "Friends", "SAT", "ACT"].map((t, i) => (
          <div
            key={t}
            style={{
              flex: 1,
              background: i === 0 ? T.primary : T.card,
              border: `1px solid ${i === 0 ? T.primary : T.cardBorder}`,
              borderRadius: 10,
              padding: "7px 0",
              textAlign: "center",
              fontSize: 12,
              fontWeight: i === 0 ? 700 : 400,
              color: i === 0 ? T.white : T.textMuted,
            }}
          >
            {t}
          </div>
        ))}
      </div>

      {/* Player rows */}
      {players.map((p) => (
        <div
          key={p.name}
          style={{
            margin: "0 16px 8px",
            background: p.rank === 4 ? `${T.accent}18` : T.card,
            border: `1.5px solid ${p.rank === 4 ? T.accent : T.cardBorder}`,
            borderRadius: 14,
            padding: "12px 16px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <span style={{ fontSize: 20 }}>{p.emoji}</span>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, color: T.white }}>{p.name}</div>
              <div style={{ fontSize: 11, color: T.textMuted }}>Rank #{p.rank}</div>
            </div>
          </div>
          <div style={{ fontSize: 14, fontWeight: 700, color: p.color }}>{p.score}</div>
        </div>
      ))}
    </ScreenWrapper>
  );
};

// ─── Screen switcher ───────────────────────────────────────────────────────────

export type ScreenType = "home" | "battle" | "zen" | "question" | "profile" | "leaderboard";

export const MockScreen: React.FC<{ type: ScreenType }> = ({ type }) => {
  switch (type) {
    case "home":        return <MockHomeScreen />;
    case "battle":      return <MockBattleScreen />;
    case "zen":         return <MockZenScreen />;
    case "question":    return <MockQuestionScreen />;
    case "profile":     return <MockProfileScreen />;
    case "leaderboard": return <MockLeaderboardScreen />;
  }
};
