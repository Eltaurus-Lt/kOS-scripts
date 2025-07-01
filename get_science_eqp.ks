function RunBarometerScience {
  for part in ship:parts {
    local mlist is part:modules:withType("ModuleScienceExperiment").
    if mlist:length > 0 {
      for each m in mlist {
        if m:experimentID = "barometerExperiment" {
          if m:isDeployed = false and m:isInoperable = false {
            print "→ Collecting barometer data…".
            m:deployExperiment().    // fire the experiment
            return.                   // one shot only
          }
        }
      }
    }
  }
  print "No Barometer experiment found!".
}

RunBarometerScience().