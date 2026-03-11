import { Config } from "@remotion/cli/config";

// Overwrite existing output files automatically
Config.setOverwriteOutput(true);

// Use JPEG for video frames (faster render, smaller intermediate files)
Config.setVideoImageFormat("jpeg");
