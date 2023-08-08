let joinPath = (path: list<string>) => "/" ++ path->List.toArray->Array.joinWith("/")

type pathSegments = {subtract: int, segments: list<string>}
let resolveRelativePath = pathname => {
  if !(pathname->String.startsWith(".")) {
    pathname
  } else {
    let pathnameSegments =
      pathname
      ->String.split("/")
      ->Array.reduceRight({subtract: 0, segments: list{}}, ({segments, subtract}, segment) => {
        switch segment {
        | "" => {subtract, segments}
        | "." => {subtract, segments}
        | ".." => {subtract: subtract + 1, segments}
        | _ => {subtract, segments: segments->List.add(segment)}
        }
      })
    let currentPath = RescriptReactRouter.dangerouslyGetInitialUrl().path
    let pathPrefix = currentPath->List.take(currentPath->List.length - pathnameSegments.subtract)
    let newPath = switch pathPrefix {
    | Some(prefix) => prefix->List.concat(pathnameSegments.segments)
    | None => pathnameSegments.segments
    }
    joinPath(newPath)
  }
}

let handleLinkClick = (handler, event) => {
  if (
    ReactEvent.Mouse.isDefaultPrevented(event) ||
    ReactEvent.Mouse.button(event) != 0 ||
    ReactEvent.Mouse.metaKey(event) ||
    ReactEvent.Mouse.altKey(event) ||
    ReactEvent.Mouse.ctrlKey(event) ||
    ReactEvent.Mouse.shiftKey(event)
  ) {
    ()
  } else {
    ReactEvent.Mouse.preventDefault(event)
    handler(.)
  }
}

let createLinkClickHandler = (~replace=false, pathname) => {
  handleLinkClick((. ()) =>
    replace ? RescriptReactRouter.replace(pathname) : RescriptReactRouter.push(pathname)
  )
}

let createAnchorProps = (~replace=false, pathname: string): JsxDOM.domProps => {
  let resolvedPath = resolveRelativePath(pathname)
  {href: resolvedPath, onClick: createLinkClickHandler(resolvedPath, ~replace)}
}

let createShareLink = shareLinkId => {
  open Webapi
  let origin = Dom.location->Dom.Location.origin
  `${origin}/s/${shareLinkId}`
}
