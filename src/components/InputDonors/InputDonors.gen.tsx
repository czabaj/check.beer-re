/* TypeScript file generated from InputDonors.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as InputDonorsJS from './InputDonors.res.js';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {t as Dict_t} from './Dict.gen';

import type {t as Map_t} from './Map.gen';

export type props<errorMessage,legendSlot,persons,value,onChange> = {
  readonly errorMessage?: errorMessage; 
  readonly legendSlot?: legendSlot; 
  readonly persons: persons; 
  readonly value: value; 
  readonly onChange: onChange
};

export const make: (_1:props<string,JSX.Element,Map_t<string,string>,Dict_t<number>,((_1:Dict_t<number>) => void)>) => PervasivesU_Jsx_element = InputDonorsJS.make as any;
