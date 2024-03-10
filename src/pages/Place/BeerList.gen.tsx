/* TypeScript file generated from BeerList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as BeerListJS from './BeerList.res.js';

import type {Map_String_key as Belt_Map_String_key} from './Belt.gen';

import type {Map_String_t as Belt_Map_String_t} from './Belt.gen';

import type {personsAllRecord as Db_personsAllRecord} from '../../../src/backend/Db.gen';

import type {role as UserRoles_role} from '../../../src/backend/UserRoles.gen';

import type {t as Map_t} from './Map.gen';

import type {userConsumption as Db_userConsumption} from '../../../src/backend/Db.gen';

export type props<activePersonsChanges,activePersonEntries,currentUserUid,isUserAuthorized,onAddConsumption,onAddPerson,recentConsumptionsByUser,setActivePersonsChanges> = {
  readonly activePersonsChanges: activePersonsChanges; 
  readonly activePersonEntries: activePersonEntries; 
  readonly currentUserUid: currentUserUid; 
  readonly isUserAuthorized: isUserAuthorized; 
  readonly onAddConsumption: onAddConsumption; 
  readonly onAddPerson: onAddPerson; 
  readonly recentConsumptionsByUser: recentConsumptionsByUser; 
  readonly setActivePersonsChanges: setActivePersonsChanges
};

export const make: React.ComponentType<{
  readonly activePersonsChanges: (undefined | Belt_Map_String_t<boolean>); 
  readonly activePersonEntries: Array<[string, Db_personsAllRecord]>; 
  readonly currentUserUid: string; 
  readonly isUserAuthorized: (_1:UserRoles_role) => boolean; 
  readonly onAddConsumption: (_1:[Belt_Map_String_key, Db_personsAllRecord]) => void; 
  readonly onAddPerson: () => void; 
  readonly recentConsumptionsByUser: Map_t<Belt_Map_String_key,Db_userConsumption[]>; 
  readonly setActivePersonsChanges: (_1:((_1:any) => (undefined | Belt_Map_String_t<boolean>))) => void
}> = BeerListJS.make as any;
