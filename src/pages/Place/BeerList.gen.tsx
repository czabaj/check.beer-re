/* TypeScript file generated from BeerList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as BeerListJS from './BeerList.bs.js';

import type {personsAllRecord as Db_personsAllRecord} from '../../../src/backend/Db.gen';

import type {role as UserRoles_role} from '../../../src/backend/UserRoles.gen';

import type {t as Map_t} from './Map.gen';

import type {userConsumption as Db_userConsumption} from '../../../src/backend/Db.gen';

export type props<currentUserUid,formatConsumption,isUserAuthorized,onAddConsumption,onAddPerson,onTogglePersonVisibility,personEntries,recentConsumptionsByUser> = {
  readonly currentUserUid: currentUserUid; 
  readonly formatConsumption: formatConsumption; 
  readonly isUserAuthorized: isUserAuthorized; 
  readonly onAddConsumption: onAddConsumption; 
  readonly onAddPerson: onAddPerson; 
  readonly onTogglePersonVisibility: onTogglePersonVisibility; 
  readonly personEntries: personEntries; 
  readonly recentConsumptionsByUser: recentConsumptionsByUser
};

export const make: React.ComponentType<{
  readonly currentUserUid: string; 
  readonly formatConsumption: (_1:number) => string; 
  readonly isUserAuthorized: (_1:UserRoles_role) => boolean; 
  readonly onAddConsumption: (_1:[string, Db_personsAllRecord]) => void; 
  readonly onAddPerson: () => void; 
  readonly onTogglePersonVisibility: (_1:[string, Db_personsAllRecord]) => void; 
  readonly personEntries: Array<[string, Db_personsAllRecord]>; 
  readonly recentConsumptionsByUser: Map_t<string,Db_userConsumption[]>
}> = BeerListJS.make as any;
