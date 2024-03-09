/* TypeScript file generated from OnboardingThrustDevice.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as OnboardingThrustDeviceJS from './OnboardingThrustDevice.res.js';

export type props<onSkip,onThrust,mentionWebAuthn> = {
  readonly onSkip: onSkip; 
  readonly onThrust: onThrust; 
  readonly mentionWebAuthn: mentionWebAuthn
};

export const make: React.ComponentType<{
  readonly onSkip: () => void; 
  readonly onThrust: () => void; 
  readonly mentionWebAuthn: boolean
}> = OnboardingThrustDeviceJS.make as any;
