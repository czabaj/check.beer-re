/* TypeScript file generated from SignInForm.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as SignInFormBS__Es6Import from './SignInForm.bs';
const SignInFormBS: any = SignInFormBS__Es6Import;

import type {t as Promise_t} from './Promise.gen';

// tslint:disable-next-line:interface-over-type-literal
export type FormFields_state = { readonly email: string; readonly password: string };

// tslint:disable-next-line:interface-over-type-literal
export type props<initialEmail,isStandaloneMode,onForgottenPassword,onGoogleAuth,onPasswordAuth,onSignUp> = {
  readonly initialEmail: initialEmail; 
  readonly isStandaloneMode: isStandaloneMode; 
  readonly onForgottenPassword: onForgottenPassword; 
  readonly onGoogleAuth: onGoogleAuth; 
  readonly onPasswordAuth: onPasswordAuth; 
  readonly onSignUp: onSignUp
};

export const make: React.ComponentType<{
  readonly initialEmail: string; 
  readonly isStandaloneMode: (undefined | boolean); 
  readonly onForgottenPassword: (_1:string) => void; 
  readonly onGoogleAuth: () => void; 
  readonly onPasswordAuth: (_1:FormFields_state) => Promise_t<void>; 
  readonly onSignUp: () => void
}> = SignInFormBS.make;
