@react.component
let make = (~value) => {
  let now = Date.make()
  let todayEOD = Date.makeWithYMD(
    ~year=Date.getFullYear(now),
    ~month=Date.getMonth(now),
    ~day=Date.getDate(now) + 1,
  )
  let differenceInDays = Math.Int.floor(
    (todayEOD->Date.getTime -. value->Date.getTime) /. DateUtils.dayInMilliseconds->Float.fromInt,
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
