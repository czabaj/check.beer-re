/* TypeScript file generated from ButtonMenu.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ButtonMenuJS from './ButtonMenu.bs.js';

export type menuItem = {
  readonly disabled?: boolean; 
  readonly label: string; 
  readonly onClick: (_1:MouseEvent) => void
};

export type props<children,className,menuItems,title> = {
  readonly children: children; 
  readonly className?: className; 
  readonly menuItems: menuItems; 
  readonly title?: title
};

export const make: React.ComponentType<{
  readonly children: React.ReactNode; 
  readonly className?: string; 
  readonly menuItems: menuItem[]; 
  readonly title?: string
}> = ButtonMenuJS.make as any;
