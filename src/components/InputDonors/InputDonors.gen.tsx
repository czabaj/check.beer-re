/* TypeScript file generated from InputDonors.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as InputDonorsJS from './InputDonors.bs.js';

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
  readonly persons: Map<string,string>; 
  readonly value: {[id: string]: number}; 
  readonly onChange: (_1:{[id: string]: number}) => void
}> = InputDonorsJS.make as any;
