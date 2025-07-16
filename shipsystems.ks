function getPartList {
	parameter nameList.

	local parts to LIST().

	for partName in nameList {
		for part in ship:partsnamed(partName) {
			parts:add(part).
		}
	}

	return parts.
}

function setBrakes {
	parameter brakes is 100.

	local gears to getPartList(LIST("GearFixed", "SmallGearBay")).

	for gear in gears {
		gear:getModule("ModuleWheelBrakes"):setField("brakes", brakes).
	}
	return .
}

function openBays {
	parameter n is -1.

	local cargoBays to ship:partsnamed("ServiceBay.125.v2").
	if n < 0 {
		for cargoBay in cargoBays {
			local module to cargoBay:getModule("ModuleAnimateGeneric").
			if module:hasevent("open") {
				module:doevent("open").
			}
		}
	}
}

function closeBays {
	parameter n is -1.

	local partsWithDoors to getPartList(LIST("ServiceBay.125.v2", "science.module")).

	if n < 0 {
		for part in partsWithDoors {
			local module to part:getModule("ModuleAnimateGeneric").
			if module:hasevent("close") {
				module:doevent("close").
			}
			if module:hasevent("close doors") {
				module:doevent("close doors").
			}
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
			local module to part:getModule("ModuleTestSubject").
			if module:hasevent("run test") {
				module:doevent("run test").
			}
		}
	}
}

function powerDown {
	set module to ship:partsnamed("KR-2042")[0]:getModule("kOSProcessor").
	module:doevent("toggle power").
}
