run science.
function measureAll {
	measure("sensorBarometer").
	measure("sensorThermometer").
	measure("GooExperiment").
	wait 1.5.
	measure("GooExperiment").
	wait 1.5.
	measure("GooExperiment").
}

sas on.

stage.
lock throttle to 0.9.

wait until ship:altitude > 100.
sas off.
lock steering to heading(90, 15).

wait until ship:resources[2]:amount = 0.
print "fuel exhausted".

wait until ship:altitude > 1400.
print "approaching max altitude".

wait until ship:altitude < 1400.
print "deploying chute".
stage.
unlock steering.

wait until ship:altitude < 1.
wait 5.0.
measureAll().


