@react.component
let make = (~keg: Db.kegConverted, ~onDismiss, ~onPreviousKeg, ~onNextKeg) => {
  <DialogCycling
    header={`${keg.serialFormatted} ${keg.beer}`}
    onDismiss
    onNext=onNextKeg
    onPrevious=onPreviousKeg
    visible=true>
    {React.string(
      "Naraženo, naskladněno, cena nákup, cena finální, všechny konzumace, možnost odstranit pokud je nedotčený, ...",
    )}
  </DialogCycling>
}
