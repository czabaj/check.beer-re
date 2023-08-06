/* TypeScript file generated from SignUpForm.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as SignUpFormBS__Es6Import from './SignUpForm.bs';
const SignUpFormBS: any = SignUpFormBS__Es6Import;

import type {t as Promise_t} from './Promise.gen';

// tslint:disable-next-line:interface-over-type-literal
export type submitValues = { readonly email: string; readonly password: string };

// tslint:disable-next-line:interface-over-type-literal
export type props<onSubmit,onGoBack> = { readonly onSubmit: onSubmit; readonly onGoBack: onGoBack };

export const make: React.ComponentType<{ readonly onSubmit: (_1:submitValues) => Promise_t<void>; readonly onGoBack: () => void }> = SignUpFormBS.make;
