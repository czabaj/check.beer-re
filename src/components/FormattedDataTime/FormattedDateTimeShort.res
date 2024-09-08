@react.component
let make = (~value) => {
  let now = Js.Date.make()
  let todayEOD = Js.Date.makeWithYMD(
    ~year=Js.Date.getFullYear(now),
    ~month=Js.Date.getMonth(now),
    ~date=Js.Date.getDate(now) +. 1.0,
    (),
  )
  let differenceInDays = Js.Math.floor_int(
    (todayEOD->Js.Date.getTime -. value->Js.Date.getTime) /.
      DateUtils.dayInMilliseconds->Float.fromInt,
  )
  switch differenceInDays {
  | 0 => <ReactIntl.FormattedTime hour=#numeric minute=#numeric value />
  | 1 =>
    <>
      {React.string("včera\xA0")}
      <ReactIntl.FormattedTime hour=#numeric minute=#numeric value />
    </>
  | 2 =>
    <>
      {React.string("předevčírem\xA0")}
      <ReactIntl.FormattedTime hour=#numeric minute=#numeric value />
    </>
  | 3
  | 4
  | 5
  | 6 =>
    <ReactIntl.FormattedDate
      year=?None month=?None day=?None hour=#numeric minute=#numeric value weekday=#long
    />
  | _ =>
    <ReactIntl.FormattedDate
      month=#numeric day=#numeric hour=#numeric minute=#numeric value weekday=#short
    />
  }
}
