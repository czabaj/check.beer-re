/* TypeScript file generated from ShareLinkResolver.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as ShareLinkResolverBS__Es6Import from './ShareLinkResolver.bs';
const ShareLinkResolverBS: any = ShareLinkResolverBS__Es6Import;

import type {element as Jsx_element} from './Jsx.gen';

import type {place as FirestoreModels_place} from '../../../src/backend/FirestoreModels.gen';

import type {shareLink as FirestoreModels_shareLink} from '../../../src/backend/FirestoreModels.gen';

// tslint:disable-next-line:interface-over-type-literal
export type Pure_props<data,loading,onAccept> = {
  readonly data: data; 
  readonly loading?: loading; 
  readonly onAccept?: onAccept
};

export const Pure_make: (_1:Pure_props<(undefined | [FirestoreModels_shareLink, FirestoreModels_place]),boolean,(() => void)>) => Jsx_element = ShareLinkResolverBS.Pure.make;

export const Pure: { make: (_1:Pure_props<(undefined | [FirestoreModels_shareLink, FirestoreModels_place]),boolean,(() => void)>) => Jsx_element } = ShareLinkResolverBS.Pure
