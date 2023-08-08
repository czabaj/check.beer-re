/* TypeScript file generated from OnboardingThrustDevice.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as OnboardingThrustDeviceBS__Es6Import from './OnboardingThrustDevice.bs';
const OnboardingThrustDeviceBS: any = OnboardingThrustDeviceBS__Es6Import;

// tslint:disable-next-line:interface-over-type-literal
export type props<onSkip,onThrust,mentionWebAuthn> = {
  readonly onSkip: onSkip; 
  readonly onThrust: onThrust; 
  readonly mentionWebAuthn: mentionWebAuthn
};

export const make: React.ComponentType<{
  readonly onSkip: () => void; 
  readonly onThrust: () => void; 
  readonly mentionWebAuthn: boolean
}> = OnboardingThrustDeviceBS.make;
