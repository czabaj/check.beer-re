/* TypeScript file generated from OnboardingNickName.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as OnboardingNickNameBS__Es6Import from './OnboardingNickName.bs';
const OnboardingNickNameBS: any = OnboardingNickNameBS__Es6Import;

import type {t as Promise_t} from './Promise.gen';

// tslint:disable-next-line:interface-over-type-literal
export type FormFields_state = { readonly name: string };

// tslint:disable-next-line:interface-over-type-literal
export type props<initialName,onSubmit> = { readonly initialName: initialName; readonly onSubmit: onSubmit };

export const make: React.ComponentType<{ readonly initialName: string; readonly onSubmit: (_1:FormFields_state) => Promise_t<void> }> = OnboardingNickNameBS.make;
