function setBrakes {
	declare parameter brakes is 100.
	local gears to ship:partsnamed("GearFixed").
	for gear in gears {
		gear:getModule("ModuleWheelBrakes"):setField("brakes", brakes).
	}
	return .
}

function openBays {
	declare parameter n is -1.
	local cargoBays to ship:partsnamed("ServiceBay.125.v2").
	if n < 0 {
		for cargoBay in cargoBays {
			cargoBay:getModule("ModuleAnimateGeneric"):doevent("open").
		}
	}
}

function closeBays {
	declare parameter n is -1.
	local cargoBays to ship:partsnamed("ServiceBay.125.v2").
	if n < 0 {
		for cargoBay in cargoBays {
			cargoBay:getModule("ModuleAnimateGeneric"):doevent("close").
		}
	}
}

function cutChutes {
	declare parameter n is -1.
	local chutes to List().
	for chute in ship:partsnamed("parachuteSingle") {
		chutes:add(chute:getModule("ModuleParachute")).
	}
	for chute in ship:partsnamed("parachuteLarge") {
		chutes:add(chute:getModule("ModuleParachute")).
	}
	for chute in ship:partsnamed("parachuteRadial") {
		chutes:add(chute:getModule("ModuleParachute")).
	}
	if n < 0 {
		for chute in chutes {
			if chute:hasevent("cut parachute") {
				chute:doevent("cut parachute").
			}
		}
	}
}

function runTests {
	declare parameter partName is "".

	if (partName <> "") {
		set parts to ship:partsnamed(partName).
	} else {
		set parts to ship:parts.
	}

	for part in parts {
		if part:hasmodule("ModuleTestSubject") {
			part:getModule("ModuleTestSubject"):doevent("run test").
		}
	}
}