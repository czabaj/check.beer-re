type classesType = {consumption: string}

@module("./BeerList.module.css") external classes: classesType = "default"

type placeClassesType = {
  detailButton: string,
  inactiveUsers: string,
  list: string,
  root: string,
}

@module("./Place.module.css") external placeClasses: placeClassesType = "default"

// Handles the animation for changed consumption
module ActivePersonListItem = {
  @react.component
  let make = (
    ~activeCheckbox: option<React.element>,
    ~consumptions: array<Db.userConsumption>,
    ~isCurrent,
    ~isUserAuthorized,
    ~onAddConsumption,
    ~personName,
  ) => {
    let listItemEl = React.useRef(Js.Nullable.null)
    let consumptionsStr =
      consumptions
      ->Array.map(consumption => {
        React.string(consumption.milliliters > 400 ? "X" : "I")
      })
      ->Array.joinWith("")
    let lastConsumptionsStr = React.useRef(consumptionsStr)
    let changeActive = React.useRef(false)
    changeActive.current = activeCheckbox !== None
    React.useEffect1(() => {
      switch (
        consumptionsStr === lastConsumptionsStr.current,
        changeActive.current,
        Js.Nullable.toOption(listItemEl.current),
      ) {
      | (false, false, Some(el)) =>
        lastConsumptionsStr.current = consumptionsStr
        el
        ->Webapi.Dom.Element.animate(
          {
            "backgroundColor": "var(--surface-warning)",
          },
          {
            "duration": 500,
            "iterations": 3,
            "direction": "reverse",
          },
        )
        ->ignore
      | _ => ()
      }
      None
    }, [consumptionsStr])

    <li ariaCurrent={isCurrent ? #"true" : #"false"} ref={ReactDOM.Ref.domRef(listItemEl)}>
      <div> {React.string(personName)} </div>
      {switch activeCheckbox {
      | Some(node) => node
      | None =>
        <>
          {isUserAuthorized(UserRoles.Staff) ||
          (isCurrent && isUserAuthorized(UserRoles.SelfService))
            ? <button
                className={Styles.utility.breakout}
                onClick={_ => onAddConsumption()}
                title="Detail konzumace"
                type_="button"
              />
            : React.null}
          <div className={classes.consumption}> {React.string(consumptionsStr)} </div>
        </>
      }}
    </li>
  }
}

@genType @react.component
let make = (
  ~activePersonsChanges,
  ~activePersonEntries: array<(string, Db.personsAllRecord)>,
  ~currentUserUid,
  ~isUserAuthorized,
  ~onAddConsumption,
  ~onAddPerson,
  ~recentConsumptionsByUser,
  ~setActivePersonsChanges,
) => {
  <SectionWithHeader
    buttonsSlot={isUserAuthorized(UserRoles.Staff)
      ? <button className={Styles.button.base} type_="button" onClick={_ => onAddPerson()}>
          {React.string("Přidat hosta")}
        </button>
      : React.null}
    headerId="active_persons"
    headerSlot={React.string("Lístek")}>
    {activePersonEntries->Array.length === 0
      ? <p className=SectionWithHeader.classes.emptyMessage>
          {React.string("Nikdo tu není, zkontrolujte nepřítomnost ⤵")}
        </p>
      : <ol className={`${Styles.list.base} ${placeClasses.list}`}>
          {activePersonEntries
          ->Array.map(activePerson => {
            let (personId, person) = activePerson
            let consumptions =
              recentConsumptionsByUser->Map.get(personId)->Option.getWithDefault([])
            <ActivePersonListItem
              activeCheckbox={activePersonsChanges->Option.map(changes =>
                <ActiveCheckbox
                  changes initialActive=true personId setChanges=setActivePersonsChanges
                />
              )}
              consumptions={consumptions}
              isCurrent={person.userId->Null.mapWithDefault(false, userId =>
                userId === currentUserUid
              )}
              isUserAuthorized
              key={personId}
              onAddConsumption={() => onAddConsumption(activePerson)}
              personName={person.name}
            />
          })
          ->React.array}
        </ol>}
  </SectionWithHeader>
}
