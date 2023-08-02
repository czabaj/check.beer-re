@react.component
let make = () => {
  open UserRoles
  let roleOptions = [Viewer, SelfService, Staff, Admin]
  <section ariaLabelledby="role_description">
    <h3 id="role_description"> {React.string("Popis rolí")} </h3>
    <dl className=Styles.descriptionList.hyphen>
      {roleOptions
      ->Array.map(role => {
        let name = role->UserRoles.roleI18n
        <div key={name}>
          <dt>
            <dfn> {React.string(name)} </dfn>
          </dt>
          <dd> {React.string(role->UserRoles.roleDescription)} </dd>
        </div>
      })
      ->React.array}
    </dl>
  </section>
}
