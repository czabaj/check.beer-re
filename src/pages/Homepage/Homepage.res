type classesType = {root: string}

@module("./Homepage.module.css") external classes: classesType = "default"

@react.component
let make = () => {
  <div className={`${Styles.page.centered} ${classes.root}`}>
    <div>
      <h1 className="text-center">
        {React.string(`Check`)}
        <br />
        {React.string(`beer${HtmlEntities.nbsp}`)}
        <span ariaHidden=true> {React.string(`IIX`)} </span>
      </h1>
      <p> {React.string("Kamarádské pivní účetnictví 🍻")} </p>
      <a
        {...RouterUtils.createAnchorProps(`/misto`)}
        className={`${Styles.button.base} ${Styles.button.variantPrimary}`}>
        {React.string("Do aplikace")}
      </a>
    </div>
  </div>
}
