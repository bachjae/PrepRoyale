import React from "react";
import { useCurrentFrame, spring, useVideoConfig, interpolate } from "remotion";
import { THEME } from "../config/theme";

interface Props {
  children: React.ReactNode;
  /** Frame when the phone should animate in */
  enterFrame?: number;
  /** Optional slight rotation in degrees (Z-axis) */
  tilt?: number;
  scale?: number;
  style?: React.CSSProperties;
}

/**
 * PhoneFrame — renders a stylised phone bezel around any content.
 *
 * Entry animation: phone falls from below with translateY AND a 3D rotateX
 * (perspective tilt) that springs from 38° to 0°, giving a "face-forward drop" feel.
 *
 * The children are clipped inside the phone screen area.
 * Pass mock app screens or a <Video> as children.
 */
export const PhoneFrame: React.FC<Props> = ({
  children,
  enterFrame = 0,
  tilt = 0,
  scale = 1,
  style,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const { w, h, radius } = THEME.phone;

  const entrance = spring({
    frame: frame - enterFrame,
    fps,
    config: { damping: 22, stiffness: 90, mass: 1.2 },
    durationInFrames: 35,
  });

  const translateY = interpolate(entrance, [0, 1], [120, 0]);
  const opacity = interpolate(entrance, [0, 0.3, 1], [0, 0.6, 1]);

  // 3D perspective tilt on entry: starts at 38° rotateX, springs to 0°
  const rotateXDeg = interpolate(entrance, [0, 1], [38, 0]);

  // Gentle floating after landing
  const floatY = 8 * Math.sin(frame / 60);

  return (
    // Perspective container — enables CSS 3D transforms on the child
    <div
      style={{
        position: "absolute",
        top: THEME.phone.y - 20,
        left: THEME.phone.x,
        width: w,
        height: h,
        perspective: "1100px",
        perspectiveOrigin: "50% 40%",
      }}
    >
      <div
        style={{
          width: "100%",
          height: "100%",
          opacity,
          transform: `
            translateY(${translateY + floatY}px)
            rotateX(${rotateXDeg}deg)
            rotate(${tilt}deg)
            scale(${scale})
          `,
          willChange: "transform, opacity",
          transformStyle: "preserve-3d",
        }}
      >
        {/* Outer shell / shadow */}
        <div
          style={{
            position: "absolute",
            inset: -6,
            borderRadius: radius + 8,
            background: "rgba(0,0,0,0.7)",
            boxShadow: `
              0 0 0 2px rgba(255,255,255,0.08),
              0 40px 80px rgba(0,0,0,0.8),
              0 0 60px ${THEME.colors.primary}33
            `,
          }}
        />

        {/* Screen area with clipping */}
        <div
          style={{
            position: "relative",
            width: w,
            height: h,
            borderRadius: radius,
            overflow: "hidden",
            background: "#0A0A1A",
            border: "1.5px solid rgba(255,255,255,0.12)",
          }}
        >
          {children}

          {/* Notch / Dynamic Island */}
          <div
            style={{
              position: "absolute",
              top: 14,
              left: "50%",
              transform: "translateX(-50%)",
              width: 120,
              height: 30,
              borderRadius: 20,
              background: "#000",
              zIndex: 10,
            }}
          />

          {/* Screen glare */}
          <div
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              width: "60%",
              height: "45%",
              background:
                "linear-gradient(135deg, rgba(255,255,255,0.06) 0%, transparent 60%)",
              borderRadius: `${radius}px 0 0 0`,
              pointerEvents: "none",
            }}
          />
        </div>
      </div>
    </div>
  );
};
