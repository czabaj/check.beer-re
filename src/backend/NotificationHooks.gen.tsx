/* TypeScript file generated from NotificationHooks.res by genType. */

/* eslint-disable */
/* tslint:disable */

export type notificationEventMessages = 
    { TAG: 1; readonly place: string; readonly users: string[] }
  | { TAG: 2; readonly keg: string; readonly users: string[] };

export type updateDeviceTokenMessage = { readonly deviceToken: string };
