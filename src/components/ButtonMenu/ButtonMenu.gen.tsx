/* TypeScript file generated from ButtonMenu.res by genType. */
/* eslint-disable import/first */


// @ts-ignore: Implicit any on import
import * as ButtonMenuBS__Es6Import from './ButtonMenu.bs';
const ButtonMenuBS: any = ButtonMenuBS__Es6Import;

// tslint:disable-next-line:interface-over-type-literal
export type menuItem = {
  readonly disabled?: boolean; 
  readonly label: string; 
  readonly onClick: (_1:MouseEvent) => void
};

// tslint:disable-next-line:interface-over-type-literal
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
}> = ButtonMenuBS.make;
