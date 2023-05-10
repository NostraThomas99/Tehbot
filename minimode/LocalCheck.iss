/*

Tehbot  Copyright � 2012  Tehtsuo and Vendan

This file is part of Tehbot.

Tehbot is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Tehbot is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Tehbot.  If not, see <http://www.gnu.org/licenses/>.

*/

objectdef obj_Configuration_LocalCheck inherits obj_Configuration_Base
{
	method Initialize()
	{
		This[parent]:Initialize["LocalCheck"]
	}

	method Set_Default_Values()
	{
		ConfigManager.ConfigRoot:AddSet[${This.SetName}]
	}

}

objectdef obj_LocalCheck inherits obj_StateQueue
{

	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		This.PulseFrequency:Set[1000]
		DynamicAddMiniMode("LocalCheck", "LocalCheck")

		This.LogLevelBar:Set[${CommonConfig.LogLevelBar}]
		PCs:ClearQueryString
	}

	method Start()
	{
		This:QueueState["LocalCheck"]
	}

	method Stop()
	{
		This:Clear
	}

	function getHighestStanding(pilot p)
	{
		variable int highestStanding

		highestStanding:Set[0]

		if ${p.Standing.AllianceToAlliance} > ${highestStanding}
		{
			highestStanding:Set[${p.Standing.AllianceToAlliance}]
		}
		if ${p.Standing.AllianceToCorp} > ${highestStanding}
		{
			highestStanding:Set[${p.Standing.AllianceToCorp}]
		}
		if ${p.Standing.AllianceToPilot} > ${highestStanding}
		{
			highestStanding:Set[${p.Standing.AllianceToPilot}]
		}
		if ${p.Standing.CorpToAlliance} > ${highestStanding}
		{
			highestStanding:Set[${p.Standing.CorpToAlliance}]
		}
		if ${p.Standing.CorpToCorp} > ${highestStanding}
		{
			highestStanding:Set[${p.Standing.CorpToCorp}]
		}
		if ${p.Standing.CorpToPilot} > ${highestStanding}
		{
			highestStanding:Set[${p.Standing.CorpToPilot}]
		}
		if ${p.Standing.MeToAlliance.Equal[5]}
		{
			highestStanding:Set[5]
		}

		if ${p.Alliance.Equal[${Me.Alliance}]}
		{
			highestStanding:Set[11]
		}
		if ${p.Standing.MeToPilot.Equal[-10]}
		{
			highestStanding:Set[-10]
		}
		if ${p.Standing.CorpToAlliance.Equal[-10]}
		{
			highestStanding:Set[-10]
		}
		if ${p.Standing.CorpToCorp.Equal[-10]}
		{
			highestStanding:Set[-10]
		}

		;echo ${p.Name}
		;echo ${highestStanding}
		;echo ${p.AllianceTicker}

		return ${highestStanding}
	}

	; Checking local
	function checkLocal()
	{
		variable index:pilot LocalPilots
		variable int counter
		variable bool allGood

		EVE:GetLocalPilots[LocalPilots]
		counter:Set[1]
		allGood:Set[TRUE]

		while ${LocalPilots.Get[${counter}]}
		{
			call getHighestStanding ${LocalPilots.Get[${counter}]}

			if (${Return} <= 0)
			{
				allGood:Set[FALSE]
			}
			counter:Inc
		}

		return ${allGood}
	}
	
	member:bool LocalCheck()
	{
		FriendlyLocal:Set[FALSE]
		call checkLocal
		if ${Return}
		{
			FriendlyLocal:Set[TRUE]
		}
		if !${Return}
		{
			FriendlyLocal:Set[FALSE]
		}
	}

}