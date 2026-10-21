---
id: nuhap8
status: closed
type: task
created: 2026-10-20T16:32:49Z
---
# Then rename user function in the 'Osobni Ucty' section added a pencil icon button in the dialog header, there is a logic that focuses the first button in tab-order in the dialog and now it is this pencil icon instead of a close button, either change order of the elements to make the close button first in the DOM or suppress the focus of the pencil icon which is not as important

## Note 2026-10-21T13:17:10Z

Fixed in DialogCycling: close button first in DOM, CSS order:1 keeps it right. Branch vg/dialog-close-focus (off vg/bump-rescript). Awaiting user validation before push/close.