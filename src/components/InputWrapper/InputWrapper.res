type classesType = {errorMessage: string, hasError: string, root: string}
@module("./InputWrapper.module.css") external classes: classesType = "default"

module ErrorMessage = {
  @react.component
  let make = (~id=?, ~message) => {
    <p className=classes.errorMessage ?id role="alert"> {React.string(message)} </p>
  }
}

@react.component
let make = (~className=?, ~inputError=?, ~inputName, ~inputSlot, ~labelSlot) => {
  let hasError = inputError != None
  let errorId = `${inputName}-error`
  <div className={`inputWrapper ${className->Option.getWithDefault("")}`}>
    <label htmlFor=inputName> {labelSlot} </label>
    <div>
      {React.cloneElement(
        inputSlot,
        {
          "aria-invalid": hasError ? "true" : "",
          "aria-describedby": hasError ? errorId : "",
          "id": inputName,
          "name": className,
        },
      )}
      {switch inputError {
      | None => React.null
      | Some(errorMessage) => <ErrorMessage id={errorId} message={errorMessage} />
      }}
    </div>
  </div>
}
