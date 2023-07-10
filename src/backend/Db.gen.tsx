/* TypeScript file generated from Db.res by genType. */
/* eslint-disable import/first */


import type {Timestamp_t as Firebase_Timestamp_t} from './Firebase.gen';

import type {consumption as FirestoreModels_consumption} from './FirestoreModels.gen';

import type {documentReference as Firebase_documentReference} from './Firebase.gen';

import type {keg as FirestoreModels_keg} from './FirestoreModels.gen';

// tslint:disable-next-line:interface-over-type-literal
export type personsAllRecord = {
  readonly balance: number; 
  readonly name: string; 
  readonly preferredTap: (undefined | string); 
  readonly recentActivityAt: Firebase_Timestamp_t
};

// tslint:disable-next-line:interface-over-type-literal
export type placeConverted = {
  readonly createdAt: Firebase_Timestamp_t; 
  readonly currency: string; 
  readonly name: string; 
  readonly personsAll: {[id: string]: personsAllRecord}; 
  readonly taps: {[id: string]: (null | Firebase_documentReference<FirestoreModels_keg>)}
};

// tslint:disable-next-line:interface-over-type-literal
export type kegConverted = {
  readonly beer: string; 
  readonly consumptions: {[id: string]: FirestoreModels_consumption}; 
  readonly consumptionsSum: number; 
  readonly createdAt: Firebase_Timestamp_t; 
  readonly donors: {[id: string]: number}; 
  readonly depletedAt: (null | Firebase_Timestamp_t); 
  readonly milliliters: number; 
  readonly price: number; 
  readonly recentConsumptionAt: (null | Firebase_Timestamp_t); 
  readonly serial: number; 
  readonly serialFormatted: string
};
