open Vitest
open Bindings
open ReactTestingLibrary
open JsDom

testAsync("renders component without crashing", async t => {
  t->assertions(0)
  render(<App />)
  let _ = screen->getByRole("link", {name: "Do aplikace"})
})
