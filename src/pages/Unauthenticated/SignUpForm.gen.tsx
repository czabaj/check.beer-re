/* TypeScript file generated from SignUpForm.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SignUpFormJS from './SignUpForm.bs.js';

import type {t as Promise_t} from './Promise.gen';

export type submitValues = { readonly email: string; readonly password: string };

export type props<isOnline,onSubmit,onGoBack> = {
  readonly isOnline: isOnline; 
  readonly onSubmit: onSubmit; 
  readonly onGoBack: onGoBack
};

export const make: React.ComponentType<{
  readonly isOnline: (undefined | boolean); 
  readonly onSubmit: (_1:submitValues) => Promise_t<void>; 
  readonly onGoBack: () => void
}> = SignUpFormJS.make as any;
