//control params
set heightPID to PIDLOOP(0.15, 0.04, 0.1, -0.15, 0.3).
set pitchPID to PIDLOOP(1.0, 0.1, 0.5, -1, 1).

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
set heightPID:setpoint to 100.
set t0 to time:seconds.
when time:seconds - t0 > 20 then { 
	print "lowering down".
	set heightPID:setpoint to 10.0. 
}
when ship:altitude < 12 then {
	set heightPID:setpoint to 1.9.  
}

until false {
	set pitchPID:setpoint to heightPID:UPDATE(time:seconds, ship:altitude) + 0.01.
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, ship:up:vector * ship:facing:vector) + 0.1.
	// print heightPID:Iterm.
}