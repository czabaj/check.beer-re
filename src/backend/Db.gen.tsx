/* TypeScript file generated from Db.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as DbJS from './Db.bs.js';

import type {Dict_key as Js_Dict_key} from '../../src/shims/Js.shim';

import type {Timestamp_t as Firebase_Timestamp_t} from './Firebase.gen';

import type {collectionReference as Firebase_collectionReference} from './Firebase.gen';

import type {consumption as FirestoreModels_consumption} from './FirestoreModels.gen';

import type {documentReference as Firebase_documentReference} from './Firebase.gen';

import type {firestore as Firebase_firestore} from './Firebase.gen';

import type {personsAllItem as FirestoreModels_personsAllItem} from './FirestoreModels.gen';

import type {place as FirestoreModels_place} from './FirestoreModels.gen';

import type {t as Map_t} from './Map.gen';

export type personsAllRecord = {
  readonly balance: number; 
  readonly name: string; 
  readonly preferredTap: (undefined | string); 
  readonly recentActivityAt: Firebase_Timestamp_t; 
  readonly userId: (null | string)
};

export type personsIndexConverted = { readonly all: {[id: string]: personsAllRecord} };

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

export type userConsumption = {
  readonly consumptionId: string; 
  readonly kegId: string; 
  readonly beer: string; 
  readonly milliliters: number; 
  readonly createdAt: Date
};

export const placeCollection: (firestore:Firebase_firestore) => Firebase_collectionReference<FirestoreModels_place> = DbJS.placeCollection as any;

export const placeDocument: (firestore:Firebase_firestore, placeId:string) => Firebase_documentReference<FirestoreModels_place> = DbJS.placeDocument as any;

export const personsAllRecordToTuple: (param:personsAllRecord) => FirestoreModels_personsAllItem = DbJS.personsAllRecordToTuple as any;

export const Keg_finalizeGetUpdateObjects: (keg:kegConverted, place:FirestoreModels_place, personsIndex:personsIndexConverted) => [{ readonly depletedAt: Firebase_Timestamp_t }, Map_t<Js_Dict_key,{ readonly transactions: {} }>, {}, {}] = DbJS.Keg.finalizeGetUpdateObjects as any;

export const Keg: { finalizeGetUpdateObjects: (keg:kegConverted, place:FirestoreModels_place, personsIndex:personsIndexConverted) => [{ readonly depletedAt: Firebase_Timestamp_t }, Map_t<Js_Dict_key,{ readonly transactions: {} }>, {}, {}] } = DbJS.Keg as any;
