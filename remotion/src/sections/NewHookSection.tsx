import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { THEME } from "../config/theme";

interface Props {
  startFrame: number;
}

/**
 * NewHookSection — Hook scene without any gradients or glow
 */
export const NewHookSection: React.FC<Props> = ({ startFrame }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const relativeFrame = frame - startFrame;
  
  // First phrase "SAT/ACT prep..." (0-25)
  const line1Opacity = interpolate(relativeFrame, [0, 10], [0, 1], { extrapolateRight: "clamp" });
  const line1Y = interpolate(relativeFrame, [0, 15], [20, 0], { extrapolateRight: "clamp" });
  
  // Second phrase "boring?" (20-75)
  const showLine2 = relativeFrame >= 20;
  
  const line2Spring = spring({
    frame: relativeFrame - 20,
    fps,
    config: { damping: 12, stiffness: 180, mass: 1 },
  });
  
  const line2Scale = interpolate(line2Spring, [0, 1], [0.5, 1]);
  
  // Shake animation for 4 frames
  const shakeFrame = relativeFrame - 20;
  let shakeX = 0;
  if (shakeFrame >= 0 && shakeFrame < 6) {
    shakeX = shakeFrame % 2 === 0 ? 8 : -8;
  }
  
  return (
    <div style={{ 
      flex: 1, 
      display: 'flex', 
      flexDirection: 'column', 
      justifyContent: 'center', 
      alignItems: 'center',
      backgroundColor: THEME.colors.bg
    }}>
      <div style={{ 
        fontSize: THEME.fontSizes.subtitle, 
        color: THEME.colors.textMuted,
        fontWeight: 700,
        opacity: line1Opacity,
        transform: `translateY(${line1Y}px)`,
        marginBottom: 20
      }}>
        SAT/ACT prep...
      </div>
      
      {showLine2 && (
        <div style={{
          fontSize: THEME.fontSizes.hero,
          color: THEME.colors.white,
          fontWeight: 900,
          transform: `scale(${line2Scale}) translateX(${shakeX}px)`,
        }}>
          boring?
        </div>
      )}
    </div>
  );
};
