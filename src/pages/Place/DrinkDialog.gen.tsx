/* TypeScript file generated from DrinkDialog.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as DrinkDialogJS from './DrinkDialog.bs.js';

import type {kegConverted as Db_kegConverted} from '../../../src/backend/Db.gen';

import type {userConsumption as Db_userConsumption} from '../../../src/backend/Db.gen';

export type FormFields_state = { readonly tap: string; readonly consumption: number };

export type props<formatConsumption,personName,preferredTap,onDeleteConsumption,onDismiss,onSubmit,tapsWithKegs,unfinishedConsumptions> = {
  readonly formatConsumption: formatConsumption; 
  readonly personName: personName; 
  readonly preferredTap: preferredTap; 
  readonly onDeleteConsumption: onDeleteConsumption; 
  readonly onDismiss: onDismiss; 
  readonly onSubmit: onSubmit; 
  readonly tapsWithKegs: tapsWithKegs; 
  readonly unfinishedConsumptions: unfinishedConsumptions
};

export const make: React.ComponentType<{
  readonly formatConsumption: (_1:number) => string; 
  readonly personName: string; 
  readonly preferredTap: string; 
  readonly onDeleteConsumption: (_1:Db_userConsumption) => void; 
  readonly onDismiss: () => void; 
  readonly onSubmit: (_1:FormFields_state) => T1; 
  readonly tapsWithKegs: {[id: string]: Db_kegConverted}; 
  readonly unfinishedConsumptions: Db_userConsumption[]
}> = DrinkDialogJS.make as any;
