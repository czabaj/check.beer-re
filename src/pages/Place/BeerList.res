type classesType = {consumption: string, emptyMessage: string, labelShowAll: string, list: string}

@module("./BeerList.module.css") external classes: classesType = "default"

// Handles the animation for changed consumption
module PersonListItem = {
  @react.component
  let make = (
    ~consumptions: array<Db.userConsumption>,
    ~isCurrent,
    ~isUserAuthorized,
    ~onAddConsumption,
    ~onTogglePersonVisibility,
    ~personName,
    ~personVisible,
  ) => {
    let listItemEl = React.useRef(Js.Nullable.null)
    let consumptionsStr =
      consumptions
      ->Array.map(consumption => {
        consumption.milliliters > 400 ? "X" : "I"
      })
      ->Array.join("")
    let lastConsumptionsStr = React.useRef(consumptionsStr)
    React.useEffect1(() => {
      switch (
        consumptionsStr === lastConsumptionsStr.current,
        Nullable.toOption(listItemEl.current),
      ) {
      | (false, Some(el)) =>
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
      {isUserAuthorized(UserRoles.Staff) || (isCurrent && isUserAuthorized(UserRoles.SelfService))
        ? <button
            className={Styles.utility.breakout}
            onClick={_ => onAddConsumption()}
            title="Detail konzumace"
            type_="button"
          />
        : React.null}
      <div className={classes.consumption}> {React.string(consumptionsStr)} </div>
      <label>
        <input
          checked={personVisible} onChange={_ => onTogglePersonVisibility()} type_="checkbox"
        />
        <img src={personVisible ? Assets.eyeShow : Assets.eyeHidden} />
      </label>
    </li>
  }
}

@genType @react.component
let make = (
  ~currentUserUid,
  ~isUserAuthorized,
  ~onAddConsumption,
  ~onAddPerson,
  ~onTogglePersonVisibility,
  ~personEntries: array<(string, Db.personsAllRecord)>,
  ~recentConsumptionsByUser,
) => {
  let (showAll, setShowAll) = React.useState(() => false)
  let personsToShow = React.useMemo2(() => {
    showAll ? personEntries : personEntries->Array.filter(((_, p)) => Db.isPersonActive(p))
  }, (personEntries, showAll))
  <SectionWithHeader
    buttonsSlot={<>
      {isUserAuthorized(UserRoles.Staff)
        ? <button className={Styles.button.base} type_="button" onClick={_ => onAddPerson()}>
            {React.string("Přidat hosta")}
          </button>
        : React.null}
      {React.cloneElement(
        <label
          className={`${classes.labelShowAll} ${Styles.button.base} ${Styles.button.iconOnly}`}>
          <span> {React.string("👁️")} </span>
          <span className={Styles.utility.srOnly}> {React.string("Zobrazit všechny")} </span>
          <input
            type_="checkbox"
            checked={showAll}
            onChange={e => {
              let target = e->ReactEvent.Form.target
              let checked = target["checked"]
              setShowAll(_ => checked)
            }}
          />
        </label>,
        {"data-checked": showAll ? "true" : "false"},
      )}
    </>}
    headerId="active_persons"
    headerSlot={React.string("Lístek")}>
    {!showAll && personsToShow->Array.length === 0
      ? <p className={`${SectionWithHeader.classes.emptyMessage} ${classes.emptyMessage}`}>
          {React.string("Všichni jsou schovaní, posviť si na ně přes tlačítko zobrazit ⤴")}
        </p>
      : {
          React.cloneElement(
            <ol className={`${Styles.list.base} ${classes.list}`}>
              {personsToShow
              ->Array.map(personEntry => {
                let (personId, person) = personEntry
                let consumptions = recentConsumptionsByUser->Map.get(personId)->Option.getOr([])
                let personVisible = !showAll || Db.isPersonActive(person)
                <PersonListItem
                  consumptions={consumptions}
                  isCurrent={person.userId->Null.mapOr(false, userId => userId === currentUserUid)}
                  isUserAuthorized
                  key={personId}
                  onAddConsumption={() => onAddConsumption(personEntry)}
                  onTogglePersonVisibility={() => onTogglePersonVisibility(personEntry)}
                  personName={person.name}
                  personVisible
                />
              })
              ->React.array}
            </ol>,
            {"data-show-all": showAll ? "true" : "false"},
          )
        }}
  </SectionWithHeader>
}
