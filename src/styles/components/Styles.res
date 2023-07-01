type boxClassesType = {base: string}
@module("./box.module.css") external boxClasses: boxClassesType = "default"

type buttonClassesType = {
  button: string,
  iconOnly: string,
  sizeLarge: string,
  sizeMedium: string,
  sizeSmall: string,
  variantDanger: string,
  variantPrimary: string,
  variantStealth: string,
}
@module("./button.module.css") external buttonClasses: buttonClassesType = "default"

type fieldsetClassesType = {grid: string}
@module("./fieldset.module.css") external fieldsetClasses: fieldsetClassesType = "default"

type utilityClassesType = {
  breakout: string,
  srOnly: string,
}
@module("./utility.module.css") external utilityClasses: utilityClassesType = "default"
