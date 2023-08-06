/* TypeScript file generated from ForgottenPasswordForm.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as ForgottenPasswordFormBS__Es6Import from './ForgottenPasswordForm.bs';
const ForgottenPasswordFormBS: any = ForgottenPasswordFormBS__Es6Import;

import type {t as Promise_t} from './Promise.gen';

// tslint:disable-next-line:interface-over-type-literal
export type FormFields_state = { readonly email: string };

// tslint:disable-next-line:interface-over-type-literal
export type props<initialEmail,onGoBack,onSubmit> = {
  readonly initialEmail: initialEmail; 
  readonly onGoBack: onGoBack; 
  readonly onSubmit: onSubmit
};

export const make: React.ComponentType<{
  readonly initialEmail: string; 
  readonly onGoBack: () => void; 
  readonly onSubmit: (_1:FormFields_state) => Promise_t<void>
}> = ForgottenPasswordFormBS.make;
