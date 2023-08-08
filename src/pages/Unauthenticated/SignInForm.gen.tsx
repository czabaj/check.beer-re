/* TypeScript file generated from SignInForm.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as SignInFormBS__Es6Import from './SignInForm.bs';
const SignInFormBS: any = SignInFormBS__Es6Import;

import type {t as Promise_t} from './Promise.gen';

// tslint:disable-next-line:interface-over-type-literal
export type FormFields_state = { readonly email: string; readonly password: string };

// tslint:disable-next-line:interface-over-type-literal
export type props<isOnline,loadingOverlay,onForgottenPassword,onSignInWithGoogle,onSignInWithPasskey,onSignInWithPassword,onSignUp> = {
  readonly isOnline: isOnline; 
  readonly loadingOverlay: loadingOverlay; 
  readonly onForgottenPassword: onForgottenPassword; 
  readonly onSignInWithGoogle: onSignInWithGoogle; 
  readonly onSignInWithPasskey: onSignInWithPasskey; 
  readonly onSignInWithPassword: onSignInWithPassword; 
  readonly onSignUp: onSignUp
};

export const make: React.ComponentType<{
  readonly isOnline: (undefined | boolean); 
  readonly loadingOverlay: boolean; 
  readonly onForgottenPassword: (_1:string) => void; 
  readonly onSignInWithGoogle: () => void; 
  readonly onSignInWithPasskey: (undefined | (() => void)); 
  readonly onSignInWithPassword: (_1:FormFields_state) => Promise_t<void>; 
  readonly onSignUp: () => void
}> = SignInFormBS.make;
