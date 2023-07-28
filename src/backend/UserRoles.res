@genType.import("./roles") @genType.as("Role") @deriving(jsConverter)
type role =
  | @as(10) Viewer
  | @as(20) SelfService
  | @as(50) Staff
  | @as(80) Admin
  | @as(100) Owner

let roleI18n = (role: role) =>
  switch role {
  | Viewer => "Pozorovatel"
  | SelfService => "Kumpán"
  | Staff => "Výčepní"
  | Admin => "Správce"
  | Owner => "Vlastník"
  }

let roleDescription = (role: role) => {
  switch role {
  | Viewer => `může sledovat lístek, ale nemůže dělat čárky.`
  | SelfService => `může sledovat lístek a psát čárky sám sobě.`
  | Staff => `může psát čárky komukoliv, může přidávat návštěvníky a naskladňovat 
  nebo přerážet sudy. Nemůže ale provádět nevratné peněžní operace, jako je
  dopití a rozúčtování sudu nebo zadávat platby.`
  | Admin => `může dělat všechno, kromě úprav účtu vlastníka.`
  | Owner => `může dělat úplně všechno, včetně převodu vlastnictví místa.`
  }
}

let isAuthorized = (userRole: int, requiredRole: role) => {
  userRole >= requiredRole->roleToJs
}
