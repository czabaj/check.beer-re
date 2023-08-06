type boxClasses = {base: string, variatnError: string}
@module("./box.module.css") external box: boxClasses = "default"

type buttonClasses = {
  base: string,
  iconOnly: string,
  sizeLarge: string,
  sizeMedium: string,
  sizeSmall: string,
  sizeExtraSmall: string,
  variantDanger: string,
  variantPrimary: string,
  variantStealth: string,
}
@module("./button.module.css") external button: buttonClasses = "default"

type checkboxClasses = {base: string}
@module("./checkbox.module.css") external checkbox: checkboxClasses = "default"

type descriptionListClasses = {hyphen: string, inline: string}
@module("./descriptionList.module.css")
external descriptionList: descriptionListClasses = "default"

type fieldsetClasses = {checkboxLabel: string, grid: string, gridSpan: string}
@module("./fieldset.module.css") external fieldset: fieldsetClasses = "default"

type linkClasses = {base: string}
@module("./link.module.css") external link: linkClasses = "default"

type listClasses = {base: string}
@module("./list.module.css") external list: listClasses = "default"

type messageBarClasses = {danger: string, info: string}
@module("./messageBar.module.css") external messageBar: messageBarClasses = "default"

type pageClasses = {centered: string, narrow: string}
@module("./page.module.css") external page: pageClasses = "default"

type radioClasses = {base: string}
@module("./radio.module.css") external radio: radioClasses = "default"

type stackClasses = {base: string}
@module("./stack.module.css") external stack: stackClasses = "default"

type tableClasses = {inDialog: string, stretch: string}
@module("./table.module.css") external table: tableClasses = "default"

type utilityClasses = {
  breakout: string,
  srOnly: string,
}
@module("./utility.module.css") external utility: utilityClasses = "default"
