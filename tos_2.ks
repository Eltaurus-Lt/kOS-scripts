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
wait until alt:radar > 25.
sas off.

set pitchPID to PIDLOOP(1.0, 0.1, 0.5, -1, 1).
set pitchI0 to 0.1.
set pitchPID:setpoint to pitchSIN.
when alt:radar > 250 then {
	print "cruising altitude reached".
	set pitchPID:setpoint to 0.
}
until false {
	// set pitchTRG to min(7.0 + alt:radar / 2, 20.0).
	// set pitchPID:setpoint to sin(pitchTRG).
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, ship:up:vector * ship:facing:vector) + pitchI0.
	print pitchPID:Iterm.
}