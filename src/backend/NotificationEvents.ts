/**
 * An Enum of notification events. Contains binary flags to store user
 * subscibed events as binary mask.
 */
export enum NotificationEvent {
  unsubscribed = 0,
  /**
   * Dispatched when nobody has a beer in a sliding window (say no beer in last
   * 12 hours) and someone takes a beer. This informs subscribers the there is
   * someone in a place so they can join.
   */
  freeTable = 1,
  /**
   * Dispatched when first beer is drafted from a new keg. This is useful for
   * inventory management and also other subscribers may be interested in a
   * fresh keg or a new beer type.
   */
  freshKeg = 2,
}
