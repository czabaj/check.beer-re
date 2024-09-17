type classesType = {
  cellConsumption: string,
  cellToggleVisibility: string,
  consumption: string,
  emptyMessage: string,
  gridBeer: string,
  labelShowAll: string,
  root: string,
  showAll: string,
}

@module("./BeerList.module.css") external classes: classesType = "default"

// Handles the animation for changed consumption
module PersonCell = {
  @react.component
  let make = (
    ~consumptions: array<Db.userConsumption>,
    ~formatConsumption,
    ~isCurrent,
    ~isUserAuthorized,
    ~onAddConsumption,
    ~personName,
  ) => {
    let rootNodeRef = React.useRef(Js.Nullable.null)
    let consumptionsStr =
      consumptions
      ->Array.map(c => formatConsumption(c.milliliters))
      ->Array.join("")
    let recentConsumptionTimestamp =
      consumptions->Array.at(-1)->Option.map(c => c.createdAt->Date.getTime)
    let prevRecentConsumptionTimestampRef = React.useRef(recentConsumptionTimestamp)
    React.useEffect1(() => {
      let prevRecentConsumptionTimestamp = prevRecentConsumptionTimestampRef.current
      prevRecentConsumptionTimestampRef.current = recentConsumptionTimestamp
      switch Nullable.toOption(rootNodeRef.current) {
      | Some(listElement) =>
        let initialEffect = recentConsumptionTimestamp === prevRecentConsumptionTimestamp
        if !initialEffect {
          let changedDueToExpiredConsumptions =
            recentConsumptionTimestamp === None &&
              prevRecentConsumptionTimestamp->Option.mapOr(false, t =>
                Date.now() -. t > Db.slidingWindowInMillis
              )
          if !changedDueToExpiredConsumptions {
            listElement
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
          }
        }
      | _ => ()
      }
      None
    }, [recentConsumptionTimestamp])

    <div className={classes.cellConsumption} ref={ReactDOM.Ref.domRef(rootNodeRef)} role="gridcell">
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
    </div>
  }
}

@genType @react.component
let make = (
  ~currentUserUid,
  ~formatConsumption,
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
        ? <button className={`${Styles.button.base}`} type_="button" onClick={_ => onAddPerson()}>
            {React.string("Nový host")}
          </button>
        : React.null}
      {React.cloneElement(
        <label
          className={`${classes.labelShowAll} ${Styles.button.base} ${Styles.button.iconOnly} ${Styles.button.variantStealth}`}>
          {React.string("👁️")}
          <span className={Styles.utility.srOnly}> {React.string("Zobrazit všechny hosty")} </span>
          <input
            type_="checkbox"
            checked={showAll}
            onChange={e => {
              let target = e->ReactEvent.Form.target
              let checked = target["checked"]
              setShowAll(_ => checked)
            }}
            role="switch"
          />
        </label>,
        {"data-checked": showAll ? "true" : "false"},
      )}
    </>}
    className={`${classes.root} ${showAll ? classes.showAll : ""}`}
    headerId="active_persons"
    headerSlot={React.string("Lístek")}>
    {!showAll && personsToShow->Array.length === 0
      ? <p className={`${SectionWithHeader.classes.emptyMessage} ${classes.emptyMessage}`}>
          <span> {React.string("Všichni jsou schovaní, koukni na ně přes očičko")} </span>
          <span> {React.string("⤴")} </span>
        </p>
      : {
          <div className={classes.gridBeer} role="grid">
            {personsToShow
            ->Array.map(personEntry => {
              let (personId, person) = personEntry
              let consumptions = recentConsumptionsByUser->Map.get(personId)->Option.getOr([])
              let isCurrent = person.userId->Null.mapOr(false, userId => userId === currentUserUid)
              let personVisible = !showAll || Db.isPersonActive(person)
              <div ariaCurrent={isCurrent ? #"true" : #"false"} key={personId} role="row">
                <PersonCell
                  consumptions={consumptions}
                  formatConsumption
                  isCurrent
                  isUserAuthorized
                  key={personId}
                  onAddConsumption={() => onAddConsumption(personEntry)}
                  personName={person.name}
                />
                <div className={classes.cellToggleVisibility} role="gridcell">
                  <label>
                    <input
                      checked={personVisible}
                      onChange={_ => onTogglePersonVisibility(personEntry)}
                      type_="checkbox"
                      role="switch"
                    />
                    <img src={personVisible ? Assets.eyeShow : Assets.eyeHidden} />
                  </label>
                </div>
              </div>
            })
            ->React.array}
          </div>
        }}
  </SectionWithHeader>
}
