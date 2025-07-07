// import
run shipstate.
run science.

// control params
set heightPID to PIDLOOP(0.15, 0.04, 0.1, -0.15, 0.3).
set headingPID to PIDLOOP(0.007, 0, 0.001, -0.6, 0.6).
set pitchPID to PIDLOOP(1.0, 0.1, 0.5, -1, 1).
set rollPID to PIDLOOP(1.0, 0.1, 0.5, -1, 1).

// prep
sas off.
brakes on.
stage.
lock throttle to 1.0.
wait 5.0.
brakes off.
wait until ship:velocity:surface:mag > 40.

// take off
print "take off".
set ship:control:pitch to 0.5.
set pitchSIN to sin(7.0).
wait until pitchSIN - ship:up:vector * ship:facing:vector < 0.01.
sas on.
wait until alt:radar > 25.
sas off.



// flight plan
set t0 to time:seconds.
set has_geotarget to false.
set heightPID:setpoint to 5000.
when ship:altitude > 500 then {
	set has_geotarget to true.
	set geotarget to waypoint("Site 1-KJ29"):geoposition.
	when geotarget:distance < 5000 then {
		measureALL().
		set geotarget to latlng(0.0489,-74.7).
	}
}
when ship:velocity:surface:mag > 250 then {
	lock throttle to 0.5.
}

// control loop
until false {
	set pitchPID:setpoint to heightPID:UPDATE(time:seconds, ship:altitude) + 0.01.
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, pitchSIN()) + 0.1.

	if has_geotarget {
		set headingPID:setpoint to geotarget:heading.
		set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).
		print geotarget:distance.
	} else {
		set rollPID:setpoint to 0.
	}
	set ship:control:roll to rollPID:UPDATE(time:seconds, rollSIN()).

}