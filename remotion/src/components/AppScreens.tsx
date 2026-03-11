import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";

/**
 * Each AppScreen renders the real screenshot via staticFile + Img.
 * The TapIndicator overlay is handled in AppDemoSection.
 * Phone frame renders at 414w × 896h (logical px).
 */

/** Screen 1: Home / Lobby — 1000005782.jpg */
export const LobbyScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-lobby.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);

/** Screen 2: Choose Battle Mode Modal — 1000005786.jpg */
export const BattleModalScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-battle-modal.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);

/** Screen 3: 1v1 Quiz Battle Setup — 1000005788.jpg */
export const BattleSetupScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-battle-setup.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);

/** Screen 4: Finding Opponent Matchmaking — 1000005790.jpg */
export const MatchmakingScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-matchmaking.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);

/** Screen 5: Study Mode / Zen — 1000005784.jpg */
export const StudyModeScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-study.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);

/** Screen 6: Your Stats — 1000005792.jpg */
export const StatsScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-stats.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);

/** Screen 7: Leaderboard — 1000005794.jpg */
export const LeaderboardScreen: React.FC = () => (
  <AbsoluteFill>
    <Img
      src={staticFile("screen-leaderboard.jpg")}
      style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
    />
  </AbsoluteFill>
);
