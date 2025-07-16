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
      return module.
    }
  }
  print "all " + instumentName + "s already used".
}

function measureALL {
  measure("sensorBarometer").
  measure("sensorThermometer").

  measure("science.module").
  // wait 2.0.
  // measure("science.module").

  local goo to measure("GooExperiment").
  if goo <> 0 {
    when goo:hasdata then {
      set goo to measure("GooExperiment").
      if goo <> 0 {
        when goo:hasdata then {
          measure("GooExperiment").
        }
      }
    }
  }
}

function resetALL {
  local parts to ship:parts.

  for part in parts {
    if part:hasModule("ModuleScienceExperiment") {
      part:getModule("ModuleScienceExperiment"):reset.
      print part:name + " reset".
    }
  }
}

function transmitALL {
  local parts to ship:parts.

  for part in parts {
    if part:hasModule("ModuleScienceExperiment") {
      local module to part:getModule("ModuleScienceExperiment").
      if module:hasdata {
        module:transmit.
        print part:name + "'s data transmitted".
      }
    }
  }
}


function storeAll {
  parameter containerN is 0.

  local containers to getPartList(LIST("ScienceBox")).

  if containers:length <= containerN {
    print "no container with such number".
    return.
  }

  local container to containers[containerN].

  container:getModule("ModuleScienceContainer"):collectAll.
}


function getPartList {
  parameter nameList.

  local parts to LIST().

  for partName in nameList {
    for part in ship:partsnamed(partName) {
      parts:add(part).
    }
  }

  return parts.
}
