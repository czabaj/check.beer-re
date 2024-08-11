/* TypeScript file generated from DepletedKegs.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as DepletedKegsJS from './DepletedKegs.bs.js';

import type {kegConverted as Db_kegConverted} from '../../../src/backend/Db.gen';

export type props<maybeFetchMoreDepletedKegs,maybeDepletedKegs> = { readonly maybeFetchMoreDepletedKegs: maybeFetchMoreDepletedKegs; readonly maybeDepletedKegs: maybeDepletedKegs };

export const make: React.ComponentType<{ readonly maybeFetchMoreDepletedKegs: (undefined | (() => void)); readonly maybeDepletedKegs: (undefined | Db_kegConverted[]) }> = DepletedKegsJS.make as any;
