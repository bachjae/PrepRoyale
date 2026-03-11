import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from "remotion";
import { THEME } from "../config/theme";

interface Props {
  startFrame: number;
}

/**
 * NewCTASection — Clean outro with logo bounce and subtitle
 */
export const NewCTASection: React.FC<Props> = ({ startFrame }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const relativeFrame = frame - startFrame;
  
  const logoSpring = spring({
    frame: relativeFrame,
    fps,
    config: { damping: 12, stiffness: 150 }
  });
  
  const logoScale = interpolate(logoSpring, [0, 1], [0.5, 1]);
  
  const subtitleSpring = spring({
    frame: relativeFrame - 20,
    fps,
    config: { damping: 14, stiffness: 120 }
  });
  
  const subY = interpolate(subtitleSpring, [0, 1], [50, 0]);
  const subOpacity = interpolate(subtitleSpring, [0, 1], [0, 1]);
  
  return (
    <div style={{
      flex: 1,
      backgroundColor: THEME.colors.bg,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <div style={{ transform: `scale(${logoScale})`, textAlign: 'center' }}>
        <Img src={staticFile("app-icon.jpg")} style={{ width: 180, height: 180, borderRadius: 42, marginBottom: 32, boxShadow: '0 20px 40px rgba(0,0,0,0.5)' }} />
        <div style={{ fontSize: THEME.fontSizes.title, fontWeight: 900, color: THEME.colors.white }}>
          Prep Royale
        </div>
      </div>
      
      <div style={{
        marginTop: 60,
        fontSize: THEME.fontSizes.body,
        fontWeight: 700,
        color: THEME.colors.primary,
        transform: `translateY(${subY}px)`,
        opacity: subOpacity,
        background: THEME.colors.card,
        padding: '24px 48px',
        borderRadius: 32,
        boxShadow: `0 20px 40px rgba(0,0,0,0.2)`
      }}>
        Free to play. Start today.
      </div>
    </div>
  );
};
