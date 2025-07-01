// global eqp to Lexicon().

// eqp:ADD( "bar", List() ).
// eqp:ADD( "therm", List() ).

// for part in ship:parts {

//   local instrument is "".
//   if part:name = "sensorBarometer" {
//     eqp["bar"]:add(part:getModule("ModuleScienceExperiment")).
//   } else if part:name = "sensorThermometer" {
//     eqp["therm"]:add(part:getModule("ModuleScienceExperiment")).
//   }

// }

function measure {
  declare parameter instumentName is "".

  local instuments is ship:partsnamed(instumentName).
  if instuments:length = 0 {
    print "no " + instumentName + "s onboard".
    return.
  }

  for instument in instuments {
    if not instument:hasModule("ModuleScienceExperiment") {
      print instumentName + " is not a scientific instument".
      return.
    }
    local module is instument:getModule("ModuleScienceExperiment").
    if not (module:inoperable or module:deployed or module:hasdata) {
      module:deploy.
      print instumentName + " deployed".
      return.
    }
  }
  print "all " + instumentName + "s already used".
}