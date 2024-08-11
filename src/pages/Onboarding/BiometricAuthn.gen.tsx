/* TypeScript file generated from BiometricAuthn.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as BiometricAuthnJS from './BiometricAuthn.bs.js';

export type props<loadingOverlay,onSetupAuthn,onSkip,setupError> = {
  readonly loadingOverlay: loadingOverlay; 
  readonly onSetupAuthn: onSetupAuthn; 
  readonly onSkip: onSkip; 
  readonly setupError?: setupError
};

export const make: React.ComponentType<{
  readonly loadingOverlay: boolean; 
  readonly onSetupAuthn: () => void; 
  readonly onSkip: () => void; 
  readonly setupError?: any
}> = BiometricAuthnJS.make as any;
