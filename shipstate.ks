function pitchSIN {
	return ship:up:vector * ship:facing:vector.
}

function rollSIN {
	return lookdirup( facing:vector, up:vector ):starvector * facing:upvector.
}

function slipSIN {
	return - ship:velocity:surface:normalized * facing:starvector.
}

function Vvert {
	return ship:velocity:surface * up:vector.
}

function realHEADING {
	declare parameter about is 0.

	local plane to lookdirup( up:vector, facing:vector ).
	local headed to arctan2( plane:starvector * north:vector, plane:upvector * north:vector).
	return mod(headed - about + 900, 360) + about - 180.
}

function landingOFS {

	return ship:body:position:y - 512.
}



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
	// for chute in ship:partsnamed("parachuteSingle") {
	// 	chutes:add(chute:getModule("ModuleParachute")).
	// }
	for chute in ship:partsnamed("parachuteRadial") {
		chutes:add(chute:getModule("ModuleParachute")).
	}
	if n < 0 {
		for chute in chutes {
			chute:doevent("cut parachute").
		}
	}
}