
objectdef obj_Configuration_Observer inherits obj_Configuration_Base
{
	method Initialize()
	{
		This[parent]:Initialize["Observer"]
	}

	method Set_Default_Values()
	{
		ConfigManager.ConfigRoot:AddSet[${This.SetName}]

	}

	Setting(bool, Halt, SetHalt)
	; We intend to do nothing more than watch local.
	Setting(bool, LocalWatchOnly, SetLocalWatchOnly)
	; We intend to watch local from within a station
	Setting(bool, StationPost, SetStationPost)
	; We intend to watch a Structure
	Setting(bool, StructureWatch, SetStructureWatch)
	; Name of the Structure (Bookmark)
	Setting(string, StructureWatchName, SetStructureWatchName)
	; We intend to watch a specific Grid (Bookmark)
	Setting(bool, GridWatch, SetGridWatch)
	; Name of that Grid (Bookmark)
	Setting(string, GridWatchName, SetGridWatchName)
	; We intend to watch Wormholes in a Single Wormhole System. This implies A) We are running multiple watchers
	; on a single machine and B) We want the observers to move to new wormholes as they exist / leave bookmarks as
	; they expire.
	Setting(bool, WormholeSystemWatch, SetWormholeSystemWatch)
	; We intend to watch a Gate
	Setting(bool, GateWatch, SetGateWatch)
	; Gate name (Bookmark)
	Setting(string, GateWatchName, SetGateWatchName)
	; Relay information to Chat Minimode
	Setting(bool, RelayToChat, SetRelayToChat)
	; This bool will have us relay more information about things to the chat relay.
	Setting(bool, SPORTSMode, SetSPORTSMode)

	
	

}

objectdef obj_Observer inherits obj_StateQueue
{


	variable obj_Configuration_Observer Config
	variable obj_ObserverUI LocalUI


	method Initialize()
	{
		This[parent]:Initialize

		DynamicAddBehavior("Observer", "Observer")
		This.PulseFrequency:Set[3500]

		This.LogInfoColor:Set["g"]
		This.LogLevelBar:Set[${Config.LogLevelBar}]

		LavishScript:RegisterEvent[Tehbot_ScheduleHalt]
		Event[Tehbot_ScheduleHalt]:AttachAtom[This:ScheduleHalt]
		LavishScript:RegisterEvent[Tehbot_ScheduleResume]
		Event[Tehbot_ScheduleResume]:AttachAtom[This:ScheduleResume]

	}

	method ScheduleHalt()
	{
		halt:Set[TRUE]
	}

	method ScheduleResume()
	{
		halt:Set[FALSE]
		if ${This.IsIdle}
		{
			This:Start
		}
	}

	method Start()
	{


		if ${This.IsIdle}
		{
			This:LogInfo["Starting"]
			This:QueueState["CheckForWork", 5000]
			EVE:RefreshBookmarks
		}


		Tehbot.Paused:Set[FALSE]
		UIElement[Run@TitleBar@Tehbot]:SetText[Stop]

	}

	method Stop()
	{
		This:LogInfo["Stopping."]
		This:Clear
		Tehbot.Paused:Set[TRUE]
		UIElement[Run@TitleBar@Tehbot]:SetText[Run]

	}


	; Subverting this old chestnut for my own purposes. In here is where our direction mostly comes from.
	; Where are we, whats our current state, what should we do next.
	member:bool CheckForWork()
	{

		; We are in space, in a pod. Might figure out something more complicated for this later.
		if ${Client.InSpace} && ${MyShip.ToEntity.Type.Equal[Capsule]}
		{
			This:LogInfo["We dead"]
			This:Stop
		}
		; We are in station, in a pod. Might figure out something more complicated for this later.
		if ${Me.InStation} && ${MyShip.ToItem.Type.Equal[Capsule]}
		{
			This:LogInfo["We dead"]
			This:Stop
		}
		; We are in station, and at our post. We are doing Local Observation Only.
		if ${Me.InStation} && ${This.AtPost}
		{
			This:LogInfo["Commence Watch from Station"]
			This:QueueState["BeginObservation"]
		}
		; We are in space, but not at our post.
		if ${Client.InSpace} && !${This.AtPost}
		{
			This:LogInfo["Status Check"]
			This:InsertState["FindPost", 5000]
			return TRUE
		}
		; We are at our observation point, begin the observation
		if ${Client.InSpace} && ${This.AtPost}
		{
			This:LogInfo["We appear to be at the right place"]
			This:QueueState["BeginObservation"]
			return TRUE
		}
		; We have hit the halt button, might want to like, stop the bot or something.
		if ${Me.InStation} && (${Config.Halt} || ${Halt})
		{
			This:LogInfo["Halt Requested"]
			This:InsertState["HaltBot"]
			return TRUE
		}
	}
	
	; We will use this to get to our Observation Post
	member:bool FindPost()
	{	
		; We are here just to watch local and report on pilot entries and exits. If you are somewhere without local I am not doing
		; A sanity check for that.
		if ${Config.LocalWatchOnly}
		{
		
		}
		; We are here to watch a specific Structure, and its grid. We will report on pilots on grid.
		if ${Config.StructureWatch}
		{
		
		}
		; We are here to watch an entire wormhole system, we will shuffle between bookmarks and watch the grids at them.
		if ${Config.WormholeSystemWatch}
		{
		
		}
		; We are here to watch a specific gate, and its grid. We will report on pilots on grid.
		if ${Config.GateWatch}
		{
		
		}
		This:InsertState["CheckForWork", 5000]
		return TRUE
	}
	
	; This is where the bulk of observer logic will go.
	member:bool BeginObservation()
	{
		; Something went wrong here
		if !${This.AtPost}
		{
			This:QueueState["CheckForWork", 10000]
			return TRUE
		}


	}
	; Are we at our observation post?
	member:bool AtPost()
	{
		if ${Me.InStation} && ${Config.StationPost}
		{
			return TRUE
		}
		if !${Client.InSpace} && !${Config.StationPost}
		{
			return FALSE
		}
		
	}

	member:bool WaitTill(int timestamp, bool start = TRUE)
	{
		if ${start}
		{
			variable time waitUntil
			waitUntil:Set[${timestamp}]

			variable int hour
			hour:Set[${waitUntil.Time24.Token[1, ":"]}]
			variable int minute
			minute:Set[${waitUntil.Time24.Token[2, ":"]}]

			if ${hour} == 10 && ${minute} >= 30 && ${minute} <= 59
			{
				This:LogInfo["Specified time ${waitUntil.Time24} is close to downtime, just halt."]

				This:InsertState["WaitTill", 5000, ${timestamp:Inc[3600]}]
				return TRUE
			}

			This:LogInfo["Start waiting until ${waitUntil.Date} ${waitUntil.Time24}."]
		}

		if ${Utility.EVETimestamp} < ${timestamp}
		{
			This:InsertState["WaitTill", 5000, "${timestamp}, FALSE"]
			return TRUE
		}

		This:LogInfo["Finished waiting."]
		return TRUE
	}



	member:bool RefreshBookmarks()
	{
		This:LogInfo["Refreshing bookmarks"]
		EVE:RefreshBookmarks
		return TRUE
	}


	member:bool HaltBot()
	{
		This:Stop
		return TRUE
	}
}


objectdef obj_ObserverUI inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}

	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["Update", 5]
		}
	}

	method Stop()
	{
		This:Clear
	}

}