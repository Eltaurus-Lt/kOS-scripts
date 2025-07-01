// taking off
brakes on.
stage.
sas on.
lock throttle to 1.0.
wait 5.0.
brakes off.

wait until ship:velocity:surface:mag > 40.
sas off.
lock steering to heading(90.0, 7.0).

wait until ship:velocity:surface:mag > 70. 
print "lift off".


wait until ship:altitude > 400.
