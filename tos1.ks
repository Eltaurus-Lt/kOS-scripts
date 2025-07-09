sas on.

stage.
lock throttle to 1.0.

wait until ship:resources[2]:amount = 0.
print "fuel exhausted".

wait until ship:altitude > 3000.
print "approaching max altitude".

wait until ship:altitude < 3000.
print "deploying chute".
stage.