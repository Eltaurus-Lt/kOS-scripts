run science.

sas on.

stage.
lock throttle to 0.8.

wait until ship:resources[2]:amount = 0.
print "fuel exhausted".

wait until ship:altitude > 3000.
print "approaching max altitude".

measure("sensorBarometer").
measure("sensorThermometer").
measure("GooExperiment").
wait 1.5.
measure("GooExperiment").
wait 1.5.
measure("GooExperiment").

wait until ship:altitude < 3000.
print "deploying chute".
stage.

