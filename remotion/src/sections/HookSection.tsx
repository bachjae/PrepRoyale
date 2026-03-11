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
}

/**
 * HookSection — first 3 seconds of the promo.
 *
 * Narrative:
 *   Line 1 → typewriter: "SAT/ACT prep..."
 *   "boring?" → spring slam + full RGB glitch (chromatic aberration + red flash + scanlines)
 *   Line 2 → "Turn it into a Battle Royale."
 *
 * To change copy: update TYPEWRITER_TEXT and the KineticText `text` props below.
 * To adjust glitch timing: change the frame ranges on glitchIntensity.
 */
export const HookSection: React.FC<Props> = ({ startFrame }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Section entrance punch ──────────────────────────────────────────────────
  const punch = spring({
    frame: frame - startFrame,
    fps,
    config: { damping: 24, stiffness: 180, mass: 0.7 },
    durationInFrames: 18,
  });
  const punchScale = interpolate(punch, [0, 1], [0.88, 1]);

  // Initial white flash
  const flashOpacity = interpolate(frame, [startFrame, startFrame + 6], [0.6, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Orange glow swells behind line 2
  const glowOpacity = interpolate(frame, [startFrame + 30, startFrame + 60], [0, 0.7], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Typewriter for "SAT/ACT prep..." ───────────────────────────────────────
  const TYPEWRITER_TEXT = "SAT/ACT prep...";
  // Reveal one char per ~1.7 frames → full text visible by frame ~25
  const charsVisible = Math.floor(
    interpolate(frame - startFrame, [0, 25], [0, TYPEWRITER_TEXT.length], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    })
  );
  const typewriterDisplay = TYPEWRITER_TEXT.slice(0, charsVisible);
  // Cursor blinks every 6 frames while typing, hides after text is complete
  const showCursor =
    charsVisible < TYPEWRITER_TEXT.length &&
    frame < startFrame + 30 &&
    (frame % 6) < 3;

  // Fade out the typewriter line (same timing as original line1.out)
  const typewriterOpacity = interpolate(
    frame,
    [startFrame + 44, startFrame + 50],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  // Line doesn't appear at all before startFrame
  const typewriterVisible = frame >= startFrame ? 1 : 0;

  // ── "boring?" spring entrance (used for scale + transform context) ──────────
  const boringEntrance = spring({
    frame: frame - (startFrame + 6),
    fps,
    config: { damping: 12, stiffness: 140, mass: 0.8 },
    durationInFrames: 22,
  });
  const boringScale = interpolate(boringEntrance, [0, 1], [0.65, 1]);
  const boringBaseOpacity = interpolate(boringEntrance, [0, 0.1, 1], [0, 1, 1]);
  const boringExitOpacity = interpolate(
    frame,
    [startFrame + 44, startFrame + 50],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const boringOpacity = Math.min(boringBaseOpacity, boringExitOpacity);

  // ── Glitch effect window ────────────────────────────────────────────────────
  // Fires right as "boring?" lands: frames startFrame+6 → startFrame+15
  const G_START = startFrame + 6;
  const G_PEAK  = startFrame + 9;
  const G_MID   = startFrame + 12;
  const G_END   = startFrame + 15;

  const glitchIntensity = interpolate(
    frame,
    [G_START, G_PEAK, G_MID, G_END],
    [0, 0.75, 0.4, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Chromatic offset — shifts as a sine wave during the glitch window for jitter
  const chromaShift = 4 + 3 * Math.sin(frame * 5.7);

  // Main word slightly desaturates during glitch
  const mainWordOpacity = boringOpacity * (1 - glitchIntensity * 0.15);

  // Red flash overlay (covers whole section)
  const redFlashOpacity = interpolate(
    frame,
    [G_START, G_PEAK, G_END],
    [0, 0.28, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Scanline jitter — two horizontal clip bands
  const jitterX1 = glitchIntensity > 0.05 ? (8 + 4 * Math.sin(frame * 17.3)) * glitchIntensity : 0;
  const jitterX2 = glitchIntensity > 0.05 ? -(8 + 4 * Math.cos(frame * 13.7)) * glitchIntensity : 0;

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        transform: `scale(${punchScale})`,
        transformOrigin: "center",
      }}
    >
      {/* White flash at section start */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: THEME.colors.white,
          opacity: flashOpacity,
          pointerEvents: "none",
        }}
      />

      {/* Red glitch flash overlay */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "#FF0000",
          opacity: redFlashOpacity,
          pointerEvents: "none",
          zIndex: 5,
          mixBlendMode: "overlay",
        }}
      />

      {/* Accent glow behind text */}
      <div
        style={{
          position: "absolute",
          width: 800,
          height: 400,
          borderRadius: "50%",
          background: `radial-gradient(ellipse, ${THEME.colors.accentOrange}66 0%, transparent 70%)`,
          opacity: glowOpacity,
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          pointerEvents: "none",
        }}
      />

      {/* ── Typewriter line: "SAT/ACT prep..." ── */}
      <div
        style={{
          fontFamily: THEME.font,
          fontWeight: 400,
          fontSize: 58,
          color: THEME.colors.textSub,
          textAlign: "center",
          lineHeight: 1.15,
          marginBottom: 16,
          textShadow: "0 2px 16px rgba(0,0,0,0.8)",
          opacity: typewriterVisible * typewriterOpacity,
          minHeight: 70, // prevent layout shift as chars appear
        }}
      >
        {typewriterDisplay}
        {showCursor && (
          <span style={{ color: THEME.colors.accent, opacity: 0.9 }}>|</span>
        )}
      </div>

      {/* ── "boring?" — glitch slam ── */}
      <div
        style={{
          position: "relative",
          marginBottom: 32,
          opacity: boringOpacity > 0 ? 1 : 0,
          transform: `scale(${boringScale})`,
        }}
      >
        {/* Scanline jitter bar 1 — clips top portion and shifts it */}
        <div
          style={{
            position: "absolute",
            top: 14,
            left: 0,
            right: 0,
            height: 16,
            overflow: "hidden",
            transform: `translateX(${jitterX1}px)`,
            opacity: glitchIntensity * 0.65,
            zIndex: 4,
          }}
        >
          <div
            style={{
              fontFamily: THEME.font,
              fontWeight: 900,
              fontSize: 100,
              color: THEME.colors.white,
              lineHeight: 1,
              position: "absolute",
              top: -14,
              left: 0,
              right: 0,
              textAlign: "center",
            }}
          >
            boring?
          </div>
        </div>

        {/* Scanline jitter bar 2 — clips middle portion */}
        <div
          style={{
            position: "absolute",
            top: 50,
            left: 0,
            right: 0,
            height: 14,
            overflow: "hidden",
            transform: `translateX(${jitterX2}px)`,
            opacity: glitchIntensity * 0.5,
            zIndex: 4,
          }}
        >
          <div
            style={{
              fontFamily: THEME.font,
              fontWeight: 900,
              fontSize: 100,
              color: THEME.colors.white,
              lineHeight: 1,
              position: "absolute",
              top: -50,
              left: 0,
              right: 0,
              textAlign: "center",
            }}
          >
            boring?
          </div>
        </div>

        {/* Chromatic aberration: blue ghost (left) */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            fontFamily: THEME.font,
            fontWeight: 900,
            fontSize: 100,
            color: "#4466FF",
            textAlign: "center",
            lineHeight: 1,
            transform: `translateX(${-chromaShift * glitchIntensity}px)`,
            opacity: glitchIntensity * 0.65,
            userSelect: "none",
            zIndex: 2,
          }}
        >
          boring?
        </div>

        {/* Chromatic aberration: red ghost (right) */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            fontFamily: THEME.font,
            fontWeight: 900,
            fontSize: 100,
            color: "#FF2244",
            textAlign: "center",
            lineHeight: 1,
            transform: `translateX(${chromaShift * glitchIntensity}px)`,
            opacity: glitchIntensity * 0.65,
            userSelect: "none",
            zIndex: 2,
          }}
        >
          boring?
        </div>

        {/* Main "boring?" text (on top) */}
        <div
          style={{
            position: "relative",
            fontFamily: THEME.font,
            fontWeight: 900,
            fontSize: 100,
            color: THEME.colors.white,
            textAlign: "center",
            lineHeight: 1,
            textShadow: `0 0 40px ${THEME.colors.accentOrange}88, 0 4px 16px rgba(0,0,0,0.9)`,
            opacity: mainWordOpacity,
            zIndex: 3,
          }}
        >
          boring?
        </div>
      </div>

      {/* Divider line */}
      <div
        style={{
          width: interpolate(frame, [startFrame + 28, startFrame + 52], [0, 260], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          height: 3,
          background: `linear-gradient(90deg, transparent, ${THEME.colors.accent}, transparent)`,
          borderRadius: 2,
          marginBottom: 32,
          opacity: Math.min(1, Math.max(0, (frame - startFrame - 28) / 10)),
        }}
      />

      {/* Line 2 */}
      <KineticText
        text="Turn it into a"
        startFrame={startFrame + 35}
        anim="fadeSlide"
        dir="up"
        style={{
          fontFamily: THEME.font,
          fontWeight: 300,
          fontSize: 52,
          color: THEME.colors.textSub,
          textAlign: "center",
          marginBottom: 8,
        }}
      />
      <KineticText
        text="Battle Royale."
        startFrame={startFrame + 44}
        anim="scale"
        damping={14}
        style={{
          fontFamily: THEME.font,
          fontWeight: 900,
          fontSize: 86,
          background: `linear-gradient(135deg, ${THEME.colors.accentOrange}, ${THEME.colors.primary})`,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          textAlign: "center",
          lineHeight: 1.1,
          textShadow: "none",
          filter: `drop-shadow(0 0 20px ${THEME.colors.accentOrange}88)`,
        }}
      />
    </div>
  );
};
