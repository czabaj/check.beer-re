/* TypeScript file generated from Unauthenticated.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as UnauthenticatedBS__Es6Import from './Unauthenticated.bs';
const UnauthenticatedBS: any = UnauthenticatedBS__Es6Import;

import type {element as Jsx_element} from './Jsx.gen';

import type {t as Promise_t} from './Promise.gen';

// tslint:disable-next-line:interface-over-type-literal
export type FormFields_state = { readonly email: string };

// tslint:disable-next-line:interface-over-type-literal
export type Pure_props<initialEmail,onBackToForm,onGoogleAuth,onPasswordAuth,signInEmailSent> = {
  readonly initialEmail: initialEmail; 
  readonly onBackToForm: onBackToForm; 
  readonly onGoogleAuth: onGoogleAuth; 
  readonly onPasswordAuth: onPasswordAuth; 
  readonly signInEmailSent?: signInEmailSent
};

export const Pure_make: (_1:Pure_props<string,(() => void),(() => void),((_1:FormFields_state) => Promise_t<void>),string>) => Jsx_element = UnauthenticatedBS.Pure.make;

export const Pure: { make: (_1:Pure_props<string,(() => void),(() => void),((_1:FormFields_state) => Promise_t<void>),string>) => Jsx_element } = UnauthenticatedBS.Pure
