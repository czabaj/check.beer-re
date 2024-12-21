type classesType = {notificationDialog: string}

@module("./NotificationDialog.module.css") external classes: classesType = "default"

@react.component
let make = (
  ~currentUserNotificationSubscription,
  ~currentUserUid,
  ~onDismiss,
  ~onUpdateSubscription,
  ~place,
) => {
  let sendTestNotification = NotificationHooks.useDispatchTestNotification(~currentUserUid, ~place)
  <Dialog className={classes.notificationDialog} visible={true}>
    <header>
      <h3> {React.string(`Nastavení notifikací`)} </h3>
      <p> {React.string(`Přihlaš se k odběru důležitých zpráv.`)} </p>
    </header>
    <form>
      <fieldset className={`reset ${Styles.fieldset.grid}`}>
        <InputWrapper
          inputName="free_table"
          inputSlot={<InputToggle
            checked={BitwiseUtils.bitAnd(
              currentUserNotificationSubscription,
              (NotificationEvents.FreeTable :> int),
            ) !== 0}
            onChange={event => {
              let target = event->ReactEvent.Form.target
              let checked = target["checked"]
              onUpdateSubscription(
                checked
                  ? BitwiseUtils.bitOr(
                      currentUserNotificationSubscription,
                      (NotificationEvents.FreeTable :> int),
                    )
                  : BitwiseUtils.bitAnd(
                      currentUserNotificationSubscription,
                      BitwiseUtils.bitNot((NotificationEvents.FreeTable :> int)),
                    ),
              )
            }}
          />}
          labelSlot={React.string("První pivo")}
        />
        <InputWrapper
          inputName="fresh_keg"
          inputSlot={<InputToggle
            checked={BitwiseUtils.bitAnd(
              currentUserNotificationSubscription,
              (NotificationEvents.FreshKeg :> int),
            ) !== 0}
            onChange={event => {
              let target = event->ReactEvent.Form.target
              let checked = target["checked"]
              onUpdateSubscription(
                checked
                  ? BitwiseUtils.bitOr(
                      currentUserNotificationSubscription,
                      (NotificationEvents.FreshKeg :> int),
                    )
                  : BitwiseUtils.bitAnd(
                      currentUserNotificationSubscription,
                      BitwiseUtils.bitNot((NotificationEvents.FreshKeg :> int)),
                    ),
              )
            }}
          />}
          labelSlot={React.string("Čerstvý sud")}
        />
      </fieldset>
    </form>
    {%raw(`import.meta.env.PROD`)
      ? React.null
      : <button className={Styles.button.base} type_="button" onClick={_ => sendTestNotification()}>
          {React.string("Send test notification")}
        </button>}
    <footer>
      <button className={Styles.button.base} type_="button" onClick={_ => onDismiss()}>
        {React.string("Zavřít")}
      </button>
    </footer>
  </Dialog>
}
