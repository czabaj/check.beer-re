type classesType = {root: string}

@module("./Homepage.module.css") external classes: classesType = "default"

@react.component
let make = () => {
  <div className={classes.root}>
    <div>
      <h1 className="text-center"> {React.string("Untap.beer")} </h1>
      <a
        {...RouterUtils.createAnchorProps(`/misto`)}
        className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}>
        {React.string("Do aplikace")}
      </a>
    </div>
  </div>
}
