// taking off
brakes on.
stage.
sas on.
lock throttle to 1.0.
wait 5.0.
brakes off.

wait until ship:velocity:surface:mag > 40.
print "take off".
sas off.
until alt:radar > 20 {
	set liftpitch to min(2.0 + 0.6 * alt:radar, 10.0).
	set liftsin to sin(liftpitch).
	set err to liftsin - ship:up:vector * ship:facing:vector.
	if err > 0 {
		print "full".
		unlock steering.
		set ship:control:pitch to 1.0.
	} else {
		print "auto".
		set ship:control:pitch to 0.0.
		lock steering to heading(90.0, liftpitch).
	}
}

print "gaining altitude".
lock steering to heading(90.0, 7.0).

wait until ship:altitude > 400.
print "cruising altitude reached".