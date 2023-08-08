type classesType = {description: string, errorMessage: string, hasError: string, root: string}
@module("./InputWrapper.module.css") external classes: classesType = "default"

module ErrorMessage = {
  @react.component
  let make = (~id=?, ~message) => {
    <p className=classes.errorMessage ?id role="alert"> {React.string(message)} </p>
  }
}

@react.component
let make = (~className=?, ~inputError=?, ~inputName, ~inputSlot, ~labelSlot, ~unitSlot=?) => {
  let unitId = unitSlot !== None ? `${inputName}_unit` : ""
  let hasError = inputError != None
  let errorId = hasError ? `${inputName}_error` : ""
  <div className={`inputWrapper ${className->Option.getWithDefault("")}`}>
    <label htmlFor=inputName> {labelSlot} </label>
    <div>
      <div>
        {React.cloneElement(
          inputSlot,
          {
            "aria-describedby": `${errorId} ${unitId}`,
            "aria-invalid": hasError ? "true" : "false",
            "id": inputName,
            "name": inputName,
          },
        )}
        {switch unitSlot {
        | None => React.null
        | Some(description) => <p className={classes.description} id={unitId}> {description} </p>
        }}
      </div>
      {switch inputError {
      | None => React.null
      | Some(errorMessage) => <ErrorMessage id={errorId} message={errorMessage} />
      }}
    </div>
  </div>
}
