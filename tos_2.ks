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

set pitchTRG to 7.0.
set pitchSIN to sin(pitchTRG).

set ship:control:pitch to 0.5.
wait until pitchSIN - ship:up:vector * ship:facing:vector < 0.01.

sas on.
set ship:control:pitch to 1.
// set pitchPID to PIDLOOP(20.0, 150.0, 25.0, -1, 1).
until alt:radar > 200 {
	// set pitchTRG to min(7.0 + alt:radar / 2, 20.0).
	// set pitchPID:setpoint to sin(pitchTRG).
	// set ship:control:pitch to pitchPID:UPDATE(time:seconds, ship:up:vector * ship:facing:vector).
	print ship:control:pitch.
}
sas off.
until alt:radar > 400 {
	print ship:control:pitch.
}
set ship:control:pitch to 0.

print "cruising altitude reached".