/* TypeScript file generated from BiometricAuthn.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as BiometricAuthnBS__Es6Import from './BiometricAuthn.bs';
const BiometricAuthnBS: any = BiometricAuthnBS__Es6Import;

// tslint:disable-next-line:interface-over-type-literal
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
}> = BiometricAuthnBS.make;
