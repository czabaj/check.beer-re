type boxClasses = {base: string, variatnError: string}
@module("./box.module.css") external box: boxClasses = "default"

type buttonClasses = {
  button: string,
  iconOnly: string,
  sizeLarge: string,
  sizeMedium: string,
  sizeSmall: string,
  variantDanger: string,
  variantPrimary: string,
  variantStealth: string,
}
@module("./button.module.css") external button: buttonClasses = "default"

type descriptionListClasses = {inline: string}
@module("./descriptionList.module.css")
external descriptionList: descriptionListClasses = "default"

type fieldsetClasses = {grid: string}
@module("./fieldset.module.css") external fieldset: fieldsetClasses = "default"

type linkClasses = {base: string}
@module("./link.module.css") external link: linkClasses = "default"

type listClasses = {base: string}
@module("./list.module.css") external list: listClasses = "default"

type messageBarClasses = {info: string}
@module("./messageBar.module.css") external messageBar: messageBarClasses = "default"

type pageClases = {centered: string, narrow: string}
@module("./page.module.css") external page: pageClases = "default"

type tableClasses = {consumptions: string, stretch: string}
@module("./table.module.css") external table: tableClasses = "default"

type utilityClasses = {
  breakout: string,
  srOnly: string,
}
@module("./utility.module.css") external utility: utilityClasses = "default"
