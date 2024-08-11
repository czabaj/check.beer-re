/* TypeScript file generated from ShareLinkResolver.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ShareLinkResolverJS from './ShareLinkResolver.bs.js';

import type {place as FirestoreModels_place} from '../../../src/backend/FirestoreModels.gen';

import type {shareLink as FirestoreModels_shareLink} from '../../../src/backend/FirestoreModels.gen';

export type Pure_props<data,loading,onAccept> = {
  readonly data: data; 
  readonly loading?: loading; 
  readonly onAccept?: onAccept
};

export const Pure_make: React.ComponentType<{
  readonly data: (undefined | [FirestoreModels_shareLink, FirestoreModels_place]); 
  readonly loading?: boolean; 
  readonly onAccept?: () => void
}> = ShareLinkResolverJS.Pure.make as any;

export const Pure: { make: React.ComponentType<{
  readonly data: (undefined | [FirestoreModels_shareLink, FirestoreModels_place]); 
  readonly loading?: boolean; 
  readonly onAccept?: () => void
}> } = ShareLinkResolverJS.Pure as any;
