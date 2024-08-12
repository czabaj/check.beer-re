/* TypeScript file generated from OnboardingNickName.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as OnboardingNickNameJS from './OnboardingNickName.bs.js';

import type {t as Promise_t} from './Promise.gen';

export type FormFields_state = { readonly name: string };

export type props<initialName,onSubmit> = { readonly initialName: initialName; readonly onSubmit: onSubmit };

export const make: React.ComponentType<{ readonly initialName: string; readonly onSubmit: (_1:FormFields_state) => Promise_t<void> }> = OnboardingNickNameJS.make as any;
