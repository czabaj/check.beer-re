type classesType = {root: string}

@module("./InputThrustDevice.module.css") external classes: classesType = "default"

@react.component
let make = () => {
  let (maybeThrustDevice, setThrustDevice) = AppStorage.useLocalStorage(AppStorage.keyThrustDevice)
  <div className=classes.root>
    <div>
      <label htmlFor="thrust_device"> {React.string(`Důvěřovat tomuto zařízení`)} </label>
      <p> {React.string(`Umožňuje fungování i bez internetu.`)} </p>
    </div>
    <InputToggle
      checked={maybeThrustDevice !== None}
      id="thrust_device"
      name="thrust_device"
      onChange={event => {
        let target = event->ReactEvent.Form.target
        let checked = target["checked"]
        setThrustDevice(. checked ? Some(`1`) : None)
      }}
    />
  </div>
}
