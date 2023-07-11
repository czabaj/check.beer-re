/* TypeScript file generated from FirestoreModels.res by genType. */
/* eslint-disable import/first */


import type {Timestamp_t as Firebase_Timestamp_t} from './Firebase.gen';

import type {documentReference as Firebase_documentReference} from './Firebase.gen';

// tslint:disable-next-line:interface-over-type-literal
export type personName = string;

// tslint:disable-next-line:interface-over-type-literal
export type tapName = string;

// tslint:disable-next-line:interface-over-type-literal
export type financialTransaction = {
  readonly amount: number; 
  readonly createdAt: Firebase_Timestamp_t; 
  readonly keg: (null | number); 
  readonly note: (null | string)
};

// tslint:disable-next-line:interface-over-type-literal
export type userAccount = {
  readonly email: string; 
  readonly name: string; 
  readonly places: {[id: string]: string}
};

// tslint:disable-next-line:interface-over-type-literal
export type consumption = { readonly milliliters: number; readonly person: Firebase_documentReference<person> };

// tslint:disable-next-line:interface-over-type-literal
export type keg = {
  readonly beer: string; 
  readonly consumptions: {[id: string]: consumption}; 
  readonly createdAt: Firebase_Timestamp_t; 
  readonly depletedAt: (null | Firebase_Timestamp_t); 
  readonly donors: {[id: string]: number}; 
  readonly milliliters: number; 
  readonly price: number; 
  readonly recentConsumptionAt: (null | Firebase_Timestamp_t); 
  readonly serial: number
};

// tslint:disable-next-line:interface-over-type-literal
export type person = {
  readonly account: (null | Firebase_documentReference<userAccount>); 
  readonly createdAt: Firebase_Timestamp_t; 
  readonly name: personName; 
  readonly transactions: financialTransaction[]
};

// tslint:disable-next-line:interface-over-type-literal
export type personsAllItem = [personName, Firebase_Timestamp_t, number, (undefined | tapName)];

// tslint:disable-next-line:interface-over-type-literal
export type place = {
  readonly createdAt: Firebase_Timestamp_t; 
  readonly currency: string; 
  readonly name: string; 
  readonly personsAll: {[id: string]: personsAllItem}; 
  readonly taps: {[id: string]: (null | Firebase_documentReference<keg>)}
};
