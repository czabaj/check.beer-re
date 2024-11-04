type notificationEvent =
  | @as(0) Unsubscribed
  | @as(1) FreeTable
  | @as(2) FreshKeg
@module("./NotificationEvents.ts")
external notificationEvent: notificationEvent = "NotificationEvent"

let roleI18n = (notificationEvent: notificationEvent) =>
  switch notificationEvent {
  | Unsubscribed => "Nepřihlášen"
  | FreeTable => "Prázdný stůl"
  | FreshKeg => "Čerstvý sud"
  }
