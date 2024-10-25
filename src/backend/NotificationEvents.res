type notificationEvent =
  | @as(0) Unsubscribed
  | @as(1) FreeTable
  | @as(2) FreshKeg
@module("./NotificationEvents.ts") external notificationEvent: notificationEvent = "NotificationEvent"

let notificationEventFromInt = (notificationEvent: int) =>
  switch notificationEvent {
  | 0 => Some(Unsubscribed)
  | 1 => Some(FreeTable)
  | 2 => Some(FreshKeg)
  | _ => None
  }

let roleI18n = (notificationEvent: notificationEvent) =>
  switch notificationEvent {
  | Unsubscribed => "Nepřihlášen"
  | FreeTable => "Prázdný stůl"
  | FreshKeg => "Čerstvý sud"
  }
