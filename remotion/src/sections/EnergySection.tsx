import React from "react";
import { useCurrentFrame, useVideoConfig, spring } from "remotion";
import { THEME } from "../config/theme";

interface Props {
  words: readonly { in: number; out: number; text: string; bgColor: string }[];
}

/**
 * EnergySection — Fast-cut word stamps on colored backgrounds
 */
export const EnergySection: React.FC<Props> = ({ words }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const activeWord = words.find(w => frame >= w.in && frame < w.out);
  if (!activeWord) return null;
  
  const wordFrame = frame - activeWord.in;
  const punch = spring({
    frame: wordFrame,
    fps,
    config: { damping: 14, stiffness: 200 }
  });
  
  // Spring from 1.4 down to 1.0
  const scale = 1.4 - (punch * 0.4);
  
  return (
    <div style={{
      flex: 1,
      backgroundColor: activeWord.bgColor,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <div style={{
        fontSize: 140,
        fontWeight: 900,
        color: THEME.colors.white,
        transform: `scale(${scale})`,
        textShadow: '0 20px 40px rgba(0,0,0,0.3)'
      }}>
        {activeWord.text}
      </div>
    </div>
  );
};
