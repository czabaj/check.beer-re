type classesType = {root: string}

@module("./Homepage.module.css") external classes: classesType = "default"

@gentype @react.component
let make = () => {
  <div className={`${Styles.page.centered} ${classes.root}`}>
    <div>
      <h1 ariaLabel="Check Beerk" className="text-center" />
      <p> {React.string("Pivní zápisník 🍻")} </p>
      <a
        {...RouterUtils.createAnchorProps(`/misto`)}
        className={`${Styles.button.base} ${Styles.button.variantPrimary}`}>
        {React.string("Otevřít")}
      </a>
    </div>
  </div>
}
