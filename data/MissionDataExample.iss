; This is a template for writing mission configs.  One thing to keep in mind: For some reason CCP has added a space after some mission names.

function main()
{
	;
	; For most missions, all you need to do is use the DamageType collection to specify the mission name and the damage type.
	; Thus, the bot knows the mission is valid and what type of ammo to load.
	; The bot will fly to the mission location, kill everything, and follow gates until it sees the mission is done.
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["Gone Berserk", "Kinetic"]

	;
	; Some missions also require that you kill a target.  To configure these, use the TargetToDestroy collection.
	; This collection requires the mission name and a search string.  Most of these use the Name member.  Note the single equal and the \ escaped quotes!
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["The Right Hand Of Zazzmatazz", "Kinetic"]
	Script[Tehbot].VariableScope.Mission.TargetToDestroy:Set["The Right Hand Of Zazzmatazz", "Name = \"Outpost Headquarters\""]

	;
	; Some missions further require that you receive an item.  To configure these, use the AquireItem collection.
	; This collection requires the mission name and the name of the item.  Note that this will not loot the item from a container - it's for missions that deposit an item in your cargo hold
	; when you kill a target.  For looting a needed item, see the next section.
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["The Damsel In Distress", "Kinetic"]
	Script[Tehbot].VariableScope.Mission.TargetToDestroy:Set["The Damsel In Distress", "Name = \"Kruul's Pleasure Gardens\""]
	Script[Tehbot].VariableScope.Mission.AquireItem:Set["The Damsel In Distress", "The Damsel"]

	;
	; For some missions, you must loot an item.  To configure these, use the ContainerToLoot AND the AquireItem collections.
	; This collection requires the mission name and a search string.  Most of these use the Name member, but also empty wrecks need to be excluded.  Note the single equal and the \ escaped quotes!
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["Worlds Collide", "EM"]
	Script[Tehbot].VariableScope.Mission.ContainerToLoot:Set["Worlds Collide", "Name = \"Damaged Heron\" && !IsWreckEmpty"]
	Script[Tehbot].VariableScope.Mission.AquireItem:Set["Worlds Collide", "Ship's Crew"]

	;
	; For some missions, you need a gate key to activate the acceleration gate.
	; The gate key item can either be obtained in the mission or brought to the mission.
	; Set the gate key item as below. If you already have the gate key, the bot will bring it to the mission, OTHERWISE it will search for the key in the specified container.
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["Dread Pirate Scarlet", "Kinetic"]
	Script[Tehbot].VariableScope.Mission.GateKey:Set["Dread Pirate Scarlet", "Gate Key"]
	Script[Tehbot].VariableScope.Mission.GateKeyContainer:Set["Dread Pirate Scarlet", "Name = \"Cargo Container\""]

	;
	; Setting example of multistep mission 'The Anomaly'.
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["The Anomaly (1 of 3)", "EM"]
	Script[Tehbot].VariableScope.Mission.GateKey:Set["The Anomaly (1 of 3)", "Oura Madusaari"]
	; 'Type' attribute tells the real Life Pod from the 3 fakes.
	Script[Tehbot].VariableScope.Mission.GateKeyContainer:Set["The Anomaly (1 of 3)", "Type = \"Life Pod\""]
	Script[Tehbot].VariableScope.Mission.TargetToDestroy:Set["The Anomaly (1 of 3)", "Name = \"Pressure Silo Debris\""]
	Script[Tehbot].VariableScope.Mission.ContainerToLoot:Set["The Anomaly (1 of 3)", "Name = \"Cargo Container\""]
	Script[Tehbot].VariableScope.Mission.AquireItem:Set["The Anomaly (1 of 3)", "Fajah Ateshi"]

	;
	; For some missions, you need to deliver an item to a container.
	; Set the delivery as below.
	;
	Script[Tehbot].VariableScope.Mission.DamageType:Set["The Anomaly (2 of 3)", "EM"]
	Script[Tehbot].VariableScope.Mission.DeliverItem:Set["The Anomaly (2 of 3)", "Neurowave Pattern Scanner"]
	Script[Tehbot].VariableScope.Mission.DeliverItemContainer:Set["The Anomaly (2 of 3)", "Name = \"The Anomaly\""]

	Script[Tehbot].VariableScope.Mission.DamageType:Set["The Anomaly (3 of 3)", "EM"]
	Script[Tehbot].VariableScope.Mission.DeliverItem:Set["The Anomaly (3 of 3)", "Fajah Ateshi"]
	Script[Tehbot].VariableScope.Mission.DeliverItemContainer:Set["The Anomaly (3 of 3)", "Name = \"The Anomaly\""]

	;
	; Finally, use the BlackListedMissions set to specify mission the bot should skip. TAKE NOTE, this is NOT a collection like all the above tools.
	; It only takes one argument (the name of the mission) and uses the "Add" method instead of the "Set" method.
	;
	Script[Tehbot].VariableScope.Mission.BlackListedMissions:Add["Surprise Surprise"]

	echo done
}