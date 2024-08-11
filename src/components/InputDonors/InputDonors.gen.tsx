/* TypeScript file generated from InputDonors.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as InputDonorsJS from './InputDonors.res.js';

import type {t as Dict_t} from './Dict.gen';

import type {t as Map_t} from './Map.gen';

export type props<errorMessage,legendSlot,persons,value,onChange> = {
  readonly errorMessage?: errorMessage; 
  readonly legendSlot?: legendSlot; 
  readonly persons: persons; 
  readonly value: value; 
  readonly onChange: onChange
};

export const make: React.ComponentType<{
  readonly errorMessage?: string; 
  readonly legendSlot?: JSX.Element; 
  readonly persons: Map_t<string,string>; 
  readonly value: Dict_t<number>; 
  readonly onChange: (_1:Dict_t<number>) => void
}> = InputDonorsJS.make as any;
