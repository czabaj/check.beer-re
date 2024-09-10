/* TypeScript file generated from InputToggle.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as InputToggleJS from './InputToggle.bs.js';

import type {Form_t as JsxEventU_Form_t} from './JsxEventU.gen';

export type props<ariaDescribedby,ariaInvalid,checked,id,name,onChange> = {
  readonly ariaDescribedby?: ariaDescribedby; 
  readonly ariaInvalid?: ariaInvalid; 
  readonly checked: checked; 
  readonly id?: id; 
  readonly name?: name; 
  readonly onChange: onChange
};

export const make: React.ComponentType<{
  readonly ariaDescribedby?: string; 
  readonly ariaInvalid?: 
    "false"
  | "grammar"
  | "spelling"
  | "true"; 
  readonly checked: boolean; 
  readonly id?: string; 
  readonly name?: string; 
  readonly onChange: (_1:JsxEventU_Form_t) => void
}> = InputToggleJS.make as any;
