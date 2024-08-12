/* TypeScript file generated from FirestoreModels.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {Timestamp_t as Firebase_Timestamp_t} from './Firebase.gen';

import type {documentReference as Firebase_documentReference} from './Firebase.gen';

export type personName = string;

export type tapName = string;

export type financialTransaction = {
  readonly amount: number; 
  readonly createdAt: Firebase_Timestamp_t; 
  readonly keg: (null | number); 
  readonly note: (null | string); 
  readonly person: (null | string)
};

export type consumption = { readonly milliliters: number; readonly person: Firebase_documentReference<person> };

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

export type person = { readonly createdAt: Firebase_Timestamp_t; readonly transactions: financialTransaction[] };

export type place = {
  readonly createdAt: Firebase_Timestamp_t; 
  readonly currency: string; 
  readonly name: string; 
  readonly taps: {[id: string]: (null | Firebase_documentReference<keg>)}; 
  readonly users: {[id: string]: number}
};

export type personsAllItem = [personName, Firebase_Timestamp_t, number, (null | string), (undefined | tapName)];

export type personsIndex = { readonly all: {[id: string]: personsAllItem} };

export type shareLink = {
  readonly createdAt: Firebase_Timestamp_t; 
  readonly person: string; 
  readonly place: string; 
  readonly role: number
};
