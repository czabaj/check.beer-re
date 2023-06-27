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

type utilityClassesType = {
  breakout: string,
  srOnly: string,
}
@module("./utility.module.css") external utilityClasses: utilityClassesType = "default"
