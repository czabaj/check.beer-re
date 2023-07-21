# check.beer

A web application for "home pub" operation. It solves the following problems:

- what beer is on which tap,
- how much beer is left in the kegs,
- how many kegs there are in the storage,
- who paid for which keg,
- who drank from which keg,
- how much beer was really taped from the keg until it was marked as depleted and count the depleted kegs among its consumers,
- settle accounts between keg owners and consumers (consumers owe for consumptions, but they can also pre-pay).

## History

This concept originates from an Android application BeerBook, which I developed years ago and never released publicly. It serves well for its users, although it has a few drawbacks, namely no cloud backup of the data and tricky release management, requiring me to backup data and deploy the app over a wire.

## Developer philosophy

This project is my playground for experiments. It uses no UI library, the styles are hand-crafted using modern CSS (e.g. there is no single media query), dialogs and menus utilizes HTML `<dialog>` and Popover API which is experimental, but will soon be supported in all major browsers and it helped me avoid libraries for this, although I'm loading polyfills.

The app is written in ReScript, which is a flavor of OCaml tailored to web development. The app is capable of running offline and when running online it features real-time data synchronization, this is achieved by using Firebase Firestore backend and SDK. The app uses React with Suspense for data-fetching and data are loaded and prepared through RxJS which enables fine-grained memoization.
