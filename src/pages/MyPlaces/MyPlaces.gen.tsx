/* TypeScript file generated from MyPlaces.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MyPlacesJS from './MyPlaces.bs.js';

import type {Mouse_t as JsxEventU_Mouse_t} from './JsxEventU.gen';

import type {User_t as Firebase_User_t} from '../../../src/backend/Firebase.gen';

import type {place as FirestoreModels_place} from '../../../src/backend/FirestoreModels.gen';

export type Pure_props<currentUser,onPlaceAdd,onSignOut,onSettingsClick,usersPlaces> = {
  readonly currentUser: currentUser; 
  readonly onPlaceAdd: onPlaceAdd; 
  readonly onSignOut: onSignOut; 
  readonly onSettingsClick: onSettingsClick; 
  readonly usersPlaces: usersPlaces
};

export const Pure_make: React.ComponentType<{
  readonly currentUser: Firebase_User_t; 
  readonly onPlaceAdd: () => void; 
  readonly onSignOut: () => void; 
  readonly onSettingsClick: (_1:JsxEventU_Mouse_t) => void; 
  readonly usersPlaces: FirestoreModels_place[]
}> = MyPlacesJS.Pure.make as any;

export const Pure: { make: React.ComponentType<{
  readonly currentUser: Firebase_User_t; 
  readonly onPlaceAdd: () => void; 
  readonly onSignOut: () => void; 
  readonly onSettingsClick: (_1:JsxEventU_Mouse_t) => void; 
  readonly usersPlaces: FirestoreModels_place[]
}> } = MyPlacesJS.Pure as any;
