import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { THEME } from "./config/theme";
import { TIMING } from "./config/timing";
import { NewHookSection } from "./sections/NewHookSection";
import { AppDemoSection } from "./sections/AppDemoSection";
import { EnergySection } from "./sections/EnergySection";
import { NewCTASection } from "./sections/NewCTASection";

/**
 * PrepRoyalePromo — 17-second high-energy promo.
 */
export const PrepRoyalePromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: THEME.colors.bg, fontFamily: THEME.font }}>
      {/* 1. Hook (0-90) */}
      <Sequence from={TIMING.PROMO.hook.start} durationInFrames={TIMING.PROMO.hook.end - TIMING.PROMO.hook.start}>
        <NewHookSection startFrame={0} />
      </Sequence>

      {/* 2. App Demo (90-540) */}
      <Sequence from={TIMING.PROMO.features.start} durationInFrames={TIMING.PROMO.features.end - TIMING.PROMO.features.start}>
        <AppDemoSection items={TIMING.PROMO.features.items} />
      </Sequence>

      {/* 3. Energy Cuts (540-630) */}
      <Sequence from={TIMING.PROMO.energy.start} durationInFrames={TIMING.PROMO.energy.end - TIMING.PROMO.energy.start}>
        <EnergySection words={TIMING.PROMO.energy.words} />
      </Sequence>

      {/* 4. CTA Outro (630-750) */}
      <Sequence from={TIMING.PROMO.cta.start} durationInFrames={TIMING.PROMO.cta.end - TIMING.PROMO.cta.start}>
        <NewCTASection startFrame={0} />
      </Sequence>
      
      {/* Persistent watermark */}
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
