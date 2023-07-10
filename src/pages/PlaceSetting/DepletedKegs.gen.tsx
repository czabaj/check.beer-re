/* TypeScript file generated from DepletedKegs.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as DepletedKegsBS__Es6Import from './DepletedKegs.bs';
const DepletedKegsBS: any = DepletedKegsBS__Es6Import;

import type {kegConverted as Db_kegConverted} from '../../../src/backend/Db.gen';

// tslint:disable-next-line:interface-over-type-literal
export type props<maybeFetchMoreDepletedKegs,maybeDepletedKegs> = { readonly maybeFetchMoreDepletedKegs: maybeFetchMoreDepletedKegs; readonly maybeDepletedKegs: maybeDepletedKegs };

export const make: React.ComponentType<{ readonly maybeFetchMoreDepletedKegs: (undefined | (() => void)); readonly maybeDepletedKegs: (undefined | Db_kegConverted[]) }> = DepletedKegsBS.make;
