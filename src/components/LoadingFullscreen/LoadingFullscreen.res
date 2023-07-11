@module("../../assets/pouring.svg")
external srcPouring: string = "default"

type classesType = {container: string}

@module("./LoadingFullscreen.module.css") external classes: classesType = "default"

@genType @react.component
let make = () => {
  <div className=Styles.page.centered>
    <div className=classes.container>
      <img src=srcPouring alt="" />
      <p> {React.string(`Čepuju kilobajty ${HtmlEntities.hellip}`)} </p>
    </div>
  </div>
}
