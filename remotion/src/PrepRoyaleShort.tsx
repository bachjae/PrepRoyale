import React from "react";
import { AbsoluteFill, Sequence, interpolate } from "remotion";
import { THEME } from "./config/theme";
import { TIMING } from "./config/timing";
import { NewHookSection } from "./sections/NewHookSection";
import { AppDemoSection } from "./sections/AppDemoSection";
import { EnergySection } from "./sections/EnergySection";
import { NewCTASection } from "./sections/NewCTASection";

/**
 * PrepRoyaleShort — 13-second dynamic action cut.
 */
export const PrepRoyaleShort: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: THEME.colors.bg, fontFamily: THEME.font }}>
      {/* 1. Hook */}
      <Sequence from={TIMING.SHORT.hook.start} durationInFrames={TIMING.SHORT.hook.end - TIMING.SHORT.hook.start}>
        <NewHookSection startFrame={0} />
      </Sequence>

      {/* 2. App Demo (Shortened to 2 screens) */}
      <Sequence from={TIMING.SHORT.features.start} durationInFrames={TIMING.SHORT.features.end - TIMING.SHORT.features.start}>
        <AppDemoSection items={TIMING.SHORT.features.items} />
      </Sequence>

      {/* 3. Energy Cuts */}
      <Sequence from={TIMING.SHORT.energy.start} durationInFrames={TIMING.SHORT.energy.end - TIMING.SHORT.energy.start}>
        <EnergySection words={TIMING.SHORT.energy.words} />
      </Sequence>

      {/* 4. CTA Outro */}
      <Sequence from={TIMING.SHORT.cta.start} durationInFrames={TIMING.SHORT.cta.end - TIMING.SHORT.cta.start}>
        <NewCTASection startFrame={0} />
      </Sequence>
      
      <div
        style={{
          position: "absolute",
          bottom: 40,
          right: 36,
          fontSize: 18,
          color: "rgba(255,255,255,0.18)",
          fontFamily: THEME.font,
          fontWeight: 600,
          letterSpacing: 1,
          pointerEvents: "none",
        }}
      >
        preproyale.com
      </div>
    </AbsoluteFill>
  );
};
