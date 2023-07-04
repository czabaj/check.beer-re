type boxClassesType = {base: string, variatnError: string}
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

type descriptionListClassesType = {inline: string}
@module("./descriptionList.module.css")
external descriptionListClasses: descriptionListClassesType = "default"

type fieldsetClassesType = {grid: string}
@module("./fieldset.module.css") external fieldsetClasses: fieldsetClassesType = "default"

type linkClassesType = {base: string}
@module("./link.module.css") external linkClasses: linkClassesType = "default"

type messageBarClassesType = {info: string}
@module("./messageBar.module.css") external messageBarClasses: messageBarClassesType = "default"

type tableClassesType = {consumptions: string, stretch: string}
@module("./table.module.css") external tableClasses: tableClassesType = "default"

type utilityClassesType = {
  breakout: string,
  srOnly: string,
}
@module("./utility.module.css") external utilityClasses: utilityClassesType = "default"
