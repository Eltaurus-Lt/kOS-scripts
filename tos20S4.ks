// import
run shipstate.
run shipsystems.
run science.

// control params
set steerPID to PIDLOOP(-0.01, 0, 0, -0.15, 0.15).
set speedPID to PIDLOOP(0.1, 0.01, 0.2, 0, 1).

stage.

function stopAndMeasure {

	local goo to ship:partsnamed("GooExperiment")[0]:getModule("ModuleScienceExperiment").
	local sci to ship:partsnamed("science.module")[0]:getModule("ModuleScienceExperiment").
	local trm to ship:partsnamed("sensorThermometer")[0]:getModule("ModuleScienceExperiment").
	local bar to ship:partsnamed("sensorBarometer")[0]:getModule("ModuleScienceExperiment").

	set speedPID:setpoint to 0.
	set ship:control:mainthrottle to 0.
	brakes on.

	print "taking measurements".
	wait 5.0.
	set ship:control:mainthrottle to 0.
	measureALL().

	wait until goo:hasdata and sci:hasdata.
	wait 5.0.
	storeAll(0).
	set ship:control:mainthrottle to 0.
	print "all stored, waiting for cleanup".

	wait until not (goo:inoperable or sci:inoperable).
	print "cleaned up".
	wait 5.0.
	print "remeasuring".
	set ship:control:mainthrottle to 0.
	measureALL().

	wait until goo:hasdata and sci:hasdata.
	wait 5.0.
	set ship:control:mainthrottle to 0.
	storeAll(1).
	print "all stored, waiting for cleanup (2)".

	wait until not (goo:inoperable or sci:inoperable or goo:hasdata or sci:hasdata or trm:hasdata or bar:hasdata).
	print "cleaned up".
	wait 5.0.
	print "rolling out".

	brakes off.
	set speedPID:setpoint to 10.

}

set speedPID:setpoint to 10.

set phase to 0.

set geotarget to latlng( -0.094469, -74.658433). // administartion
set geotarget to latlng( -0.086692, -74.663039). // administartion

when geotarget:distance < 10 then {
	stopAndMeasure().
	set geotarget to latlng( -0.094686, -74.647744). // astronaut complext
	set geotarget to latlng( -0.095321, -74.654667). // astronaut complext

	when geotarget:distance < 10 then {
		stopAndMeasure().
		set geotarget to latlng( -0.103452, -74.637692). // RnD
		set geotarget to latlng( -0.102822, -74.643380). // RnD

		when geotarget:distance < 10 then {
			stopAndMeasure().
			set geotarget to latlng( -0.090729, -74.614654). // VAB
			set geotarget to latlng( -0.100779, -74.629151). // VAB
			set geotarget to latlng( -0.103834, -74.631518). // VAB

			when geotarget:distance < 10 then {
				stopAndMeasure().
				set geotarget to latlng( -0.112747, -74.614847). // KSC

				when geotarget:distance < 10 then {
					stopAndMeasure().
					set geotarget to latlng( -0.123962, -74.611376). // tracking station
					set geotarget to latlng( -0.116044, -74.609753). // tracking station

					when geotarget:distance < 10 then {
						stopAndMeasure().
						set geotarget to latlng( -0.096976, -74.600203). // crawlerway

						when geotarget:distance < 15 then {
							stopAndMeasure().
							set geotarget to latlng( -0.079782, -74.616950). // mission control
							set geotarget to latlng( -0.069980, -74.610802). // mission control

							when geotarget:distance < 10 then {
								stopAndMeasure().
								set geotarget to latlng( -0.067253, -74.628492). // SPH
								set geotarget to latlng( -0.060558, -74.622420). // SPH

								when geotarget:distance < 10 then {
									stopAndMeasure().
									set geotarget to latlng( -0.0485, -74.7131). // return home

									when geotarget:distance < 10 then {
										set phase to 4.
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

setBrakes(20).

until phase = 4 {
	// throttle
	set ship:control:mainthrottle to speedPID:UPDATE(time:seconds, ship:velocity:surface:mag).
	if (ship:velocity:surface:mag - speedPID:setpoint > 2 ) {
		brakes on.
	} else {
		brakes off.
	}

	set steerPID:setpoint to geotarget:heading.
	set ship:control:wheelsteer to steerPID:UPDATE(time:seconds, realHEADING(steerPID:setpoint)).

	print realHEADING(steerPID:setpoint) + "->" + geotarget:heading + " | " + geotarget:distance.
}

set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
lock throttle to 0.
brakes on.
wait until ship:velocity:surface:mag < 1.0.
wait 5.0.
setBrakes(50).
print "done".