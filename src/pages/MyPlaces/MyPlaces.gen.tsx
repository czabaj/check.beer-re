/* TypeScript file generated from MyPlaces.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as MyPlacesBS__Es6Import from './MyPlaces.bs';
const MyPlacesBS: any = MyPlacesBS__Es6Import;

import type {Mouse_t as JsxEvent_Mouse_t} from './JsxEvent.gen';

import type {User_t as Firebase_User_t} from '../../../src/backend/Firebase.gen';

import type {element as Jsx_element} from './Jsx.gen';

import type {place as FirestoreModels_place} from '../../../src/backend/FirestoreModels.gen';

// tslint:disable-next-line:interface-over-type-literal
export type Pure_props<currentUser,onPlaceAdd,onSignOut,onSettingsClick,usersPlaces> = {
  readonly currentUser: currentUser; 
  readonly onPlaceAdd: onPlaceAdd; 
  readonly onSignOut: onSignOut; 
  readonly onSettingsClick: onSettingsClick; 
  readonly usersPlaces: usersPlaces
};

export const Pure_make: (_1:Pure_props<Firebase_User_t,(() => void),(() => void),((_1:JsxEvent_Mouse_t) => void),FirestoreModels_place[]>) => Jsx_element = MyPlacesBS.Pure.make;

export const Pure: { make: (_1:Pure_props<Firebase_User_t,(() => void),(() => void),((_1:JsxEvent_Mouse_t) => void),FirestoreModels_place[]>) => Jsx_element } = MyPlacesBS.Pure
