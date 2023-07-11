type classesType = {container: string}

@module("./LoadingFullscreen.module.css") external classes: classesType = "default"

@genType @react.component
let make = () => {
  <div className=Styles.page.centered>
    <div className=classes.container>
      <img alt="" src=Assets.pouring />
      <p> {React.string(`Čepuju kilobajty ${HtmlEntities.hellip}`)} </p>
    </div>
  </div>
}
