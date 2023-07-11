@react.component
let make = () => {
  <div className={Styles.page.centered}>
    <div>
      <h1 className="text-center"> {React.string("Untap.beer")} </h1>
      <a
        {...RouterUtils.createAnchorProps(`/misto`)}
        className={`${Styles.button.button} ${Styles.button.variantPrimary}`}>
        {React.string("Do aplikace")}
      </a>
    </div>
  </div>
}
