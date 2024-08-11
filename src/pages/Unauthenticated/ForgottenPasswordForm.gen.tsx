/* TypeScript file generated from ForgottenPasswordForm.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ForgottenPasswordFormJS from './ForgottenPasswordForm.bs.js';

import type {t as Promise_t} from './Promise.gen';

export type FormFields_state = { readonly email: string };

export type props<initialEmail,isOnline,onGoBack,onSubmit> = {
  readonly initialEmail: initialEmail; 
  readonly isOnline: isOnline; 
  readonly onGoBack: onGoBack; 
  readonly onSubmit: onSubmit
};

export const make: React.ComponentType<{
  readonly initialEmail: string; 
  readonly isOnline: (undefined | boolean); 
  readonly onGoBack: () => void; 
  readonly onSubmit: (_1:FormFields_state) => Promise_t<void>
}> = ForgottenPasswordFormJS.make as any;
