# check.beer

A web application for "home pub" operation. It solves the following problems:

- which keg is on which tap,
- how much beer is left in the tapped kegs,
- stored kegs management,
- accounting between keg investors and consumers concerning the net consumption from the keg. Say the keg of 100 beers costs 1000 credits, then one beer should cost 10 credits but there are always wastes, in reality, only around 95 beers are drafted and this app divides the _net_ consumption between consumers.

See for your selves on [check.beer](https://check.beer)

## History

This app originates from an Android application "BeerBook", which I made _years_ ago and never released publicly. It serves well for its users, although it has a few drawbacks, most notably no cloud backup 🧨

## Developer facts of interest
- this app is written in [ReScript, a flavor of OCaml programming language](https://rescript-lang.org) which compiles to clean JavaScript,
- this app is a [progressive-web-app (PWA)](https://web.dev/learn/pwa/), it can be installed as a standalone app and is capable of running offline with almost no limitations,
- this app **runs on Firebase** and utilizes most of its goodies - offline support, near real-time synchronization, reliability and speed,
- this app is written in React using **Suspense for data-fetching**, RxJS is used to construct data-pipes for React components,
- this app uses vanilla CSS for styling with an emphasis on modern CSS features, like [Colors Module 4](https://developer.mozilla.org/en-US/blog/css-color-module-level-4/), [Logical Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values) or [Anchor Positioning](https://developer.chrome.com/blog/tether-elements-to-each-other-with-css-anchor-positioning/), using modern layouts to _eschew screen-width media queries as much as possible_,
- appropriate HTML elements are used in the right places concerning accessibility (A11Y), the HTML structure is always shallow, _no extra `<div>` ever_,
- modern HTML elements are used, like [`<dialog>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog) or [`<details>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details),
- modern browser APIs are used, like [Intl API](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl), bleeding-edge [Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API) or [View Transition API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API),
- the app implements [Web Authentication API (WebAuthn)](https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API) protocol which allows password-less login on devices with biometric authenticators 🐾

There is no UI framework employed nor many libraries, I aim at replacing them with new Web APIs. Expect instability, but if you want to learn more about PWA and the modern Web, you are in the right place.

GitHub Issues welcomed 🙇‍♂️
