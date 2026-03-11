import React from "react";
import { useCurrentFrame, useVideoConfig, spring, Sequence, interpolate, AbsoluteFill } from "remotion";
import { THEME } from "../config/theme";
import { PhoneFrame } from "../components/PhoneFrame";
import type { FeatureItem } from "../config/timing";
import {
  LobbyScreen,
  BattleModalScreen,
  BattleSetupScreen,
  MatchmakingScreen,
  StudyModeScreen,
  StatsScreen,
  LeaderboardScreen,
} from "../components/AppScreens";
import { TapIndicator } from "../components/TapIndicator";

interface Props {
  items: readonly FeatureItem[];
}

/** Returns the correct screen component for a given screenId */
function renderScreen(screen: FeatureItem["screen"]): React.ReactElement {
  switch (screen) {
    case "lobby":        return <LobbyScreen />;
    case "battle-modal": return <BattleModalScreen />;
    case "battle-setup": return <BattleSetupScreen />;
    case "matchmaking":  return <MatchmakingScreen />;
    case "study":        return <StudyModeScreen />;
    case "stats":        return <StatsScreen />;
    case "leaderboard":  return <LeaderboardScreen />;
  }
}

/**
 * AppDemoSection — Cinematic phone showcase with:
 * - Actual app screenshots via staticFile
 * - Precise SVG cursor on real buttons
 * - Dynamic camera: zoom in + slow pan per scene
 * - Student/parent focused captions with subtitle
 */
export const AppDemoSection: React.FC<Props> = ({ items }) => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  return (
    <AbsoluteFill style={{ background: "linear-gradient(160deg, #0F172A 0%, #1E293B 50%, #0F172A 100%)" }}>

      {/* Subtle background shimmer */}
      <div style={{
        position: "absolute", inset: 0,
        background: "radial-gradient(ellipse 60% 50% at 50% 50%, rgba(56,189,248,0.08) 0%, transparent 70%)",
        pointerEvents: "none"
      }} />

      {items.map((item, i) => {
        const localFrame = frame - item.in;
        const duration = item.out - item.in;

        if (localFrame < -15 || localFrame > duration + 15) return null;

        // Fade in / fade out
        const opacity = interpolate(
          localFrame,
          [0, 18, duration - 18, duration],
          [0, 1, 1, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        // Camera zoom: starts at 1.0, slowly creeps to zoomTo
        const targetZoom = item.zoomTo ?? 1.15;
        const zoom = interpolate(localFrame, [0, duration], [1.0, targetZoom], {
          extrapolateLeft: "clamp", extrapolateRight: "clamp"
        });

        // Camera Y pan: slides image up slowly to focus on detail
        const targetPanY = (item.panY ?? 0) * -80; // px offset
        const panY = interpolate(localFrame, [0, duration], [0, targetPanY], {
          extrapolateLeft: "clamp", extrapolateRight: "clamp"
        });

        // 3D tilt for cinematism — gentle rock side to side
        const rotY = interpolate(localFrame, [0, duration / 2, duration], [6, -4, 6]);
        const rotX = interpolate(localFrame, [0, duration], [3, -2]);

        // Pop-in spring for phone entry
        const entrySpring = spring({ frame: localFrame, fps, config: { damping: 14, stiffness: 120 } });
        const entryScale = interpolate(entrySpring, [0, 1], [0.85, 1]);

        // Caption pop-in
        const captionSpring = spring({ frame: Math.max(0, localFrame - 20), fps, config: { damping: 14 } });
        const captionY = interpolate(captionSpring, [0, 1], [40, 0]);
        const captionOpacity = interpolate(localFrame, [20, 40, duration - 20, duration], [0, 1, 1, 0], {
          extrapolateLeft: "clamp", extrapolateRight: "clamp"
        });

        const PHONE_CENTER_X = (1080) / 2; // 540
        const PHONE_CENTER_Y = (1920) / 2; // 960

        return (
          <Sequence from={item.in} durationInFrames={duration + 15} key={item.screen}>

            {/* 
              Phone positioned absolutely over the full canvas.
              We apply our cinematic transform around the phone's center point.
            */}
            <div style={{
              position: "absolute",
              top: 0, left: 0,
              width: "100%", height: "100%",
              opacity,
              transformOrigin: `${PHONE_CENTER_X}px ${PHONE_CENTER_Y}px`,
              transform: `
                scale(${entryScale * zoom})
                translateY(${panY}px)
                perspective(1200px)
                rotateX(${rotX}deg)
                rotateY(${rotY}deg)
              `,
            }}>
              <PhoneFrame enterFrame={0}>
                {renderScreen(item.screen)}
              </PhoneFrame>

              {/* Tap cursor — coordinates relative to phone content (414×896 logical px) */}
              {item.tap && (
                <div style={{
                  position: "absolute",
                  left: THEME.phone.x,
                  top: THEME.phone.y,
                  width: THEME.phone.w,
                  height: THEME.phone.h,
                  pointerEvents: "none",
                }}>
                  <TapIndicator
                    x={item.tap.x}
                    y={item.tap.y}
                    tapFrame={item.tap.frame}
                    color="rgba(56,189,248,0.3)"
                  />
                </div>
              )}
            </div>

            {/* Floating Caption Box */}
            <div style={{
              position: "absolute",
              bottom: 80,
              left: 0, right: 0,
              textAlign: "center",
              pointerEvents: "none",
              opacity: captionOpacity,
              transform: `translateY(${captionY}px)`,
              zIndex: 20,
              padding: "0 40px",
            }}>
              {/* Main label */}
              <div style={{
                display: "inline-block",
                background: "rgba(255,255,255,0.95)",
                color: "#0F172A",
                padding: "18px 48px 12px",
                borderRadius: "28px 28px 8px 8px",
                fontSize: 44,
                fontWeight: 900,
                letterSpacing: -0.5,
                boxShadow: "0 20px 60px rgba(0,0,0,0.4)",
                lineHeight: 1.1,
                fontFamily: THEME.font,
              }}>
                {item.label}
              </div>
              {/* Sub-label */}
              <div style={{
                display: "inline-block",
                background: "rgba(255,255,255,0.85)",
                color: "#475569",
                padding: "8px 48px 16px",
                borderRadius: "8px 8px 28px 28px",
                fontSize: 28,
                fontWeight: 600,
                boxShadow: "0 20px 60px rgba(0,0,0,0.3)",
                lineHeight: 1.3,
                fontFamily: THEME.font,
                marginTop: 2,
              }}>
                {item.sublabel}
              </div>
            </div>

          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
