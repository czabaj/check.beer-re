/* TypeScript file generated from InputDonors.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as InputDonorsBS__Es6Import from './InputDonors.bs';
const InputDonorsBS: any = InputDonorsBS__Es6Import;

import type {element as Jsx_element} from './Jsx.gen';

import type {t as Dict_t} from './Dict.gen';

// tslint:disable-next-line:interface-over-type-literal
export type props<errorMessage,legendSlot,persons,value,onChange> = {
  readonly errorMessage?: errorMessage; 
  readonly legendSlot?: legendSlot; 
  readonly persons: persons; 
  readonly value: value; 
  readonly onChange: onChange
};

export const make: (_1:props<string,JSX.Element,string[],Dict_t<number>,((_1:Dict_t<number>) => void)>) => Jsx_element = InputDonorsBS.make;
