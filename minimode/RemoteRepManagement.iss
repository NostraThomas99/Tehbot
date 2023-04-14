objectdef obj_Configuration_RemoteRepManagement inherits obj_Configuration_Base
{
	method Initialize()
	{
		This[parent]:Initialize["RemoteRepManagement"]
	}

	method Set_Default_Values()
	{
		This.ConfigRef:AddSetting[IsLeader, FALSE]
		This.ConfigRef:AddSetting[MaintainFleetLock, FALSE]
		This.ConfigRef:AddSetting[UseLogisticsDrones, FALSE]
		This.ConfigRef:AddSetting[UseSecondaryTargetList, FALSE]
		This.ConfigRef:AddSetting[GankSpoilMode, FALSE]
		This.ConfigRef:AddSetting[DistanceMaintain, 10000]
		This.ConfigRef:AddSetting[OrbitDistance, 7500]
		This.ConfigRef:AddSetting[ReservedTargetLocks, 2]
		This.ConfigRef:AddSetting[RepShieldThreshold, 50]
		This.ConfigRef:AddSetting[RepArmorThreshold, 80]
		This.ConfigRef:AddSetting[StopRepShieldThreshold, 90]
		This.ConfigRef:AddSetting[StopRepArmorThreshold, 99]
		This.ConfigRef:AddSetting[CapOutThreshold, 30]
		This.ConfigRef:AddSetting[LogLevelBar, LOG_INFO]
	}
	
	Setting(bool, IsLeader, SetIsLeader)
	Setting(bool, MaintainFleetLock, SetMaintainFleetLock)
	Setting(bool, UseLogisticsDrones, SetUseLogisticsDrones)
	Setting(bool, UseSecondaryTargetList, SetUseSecondaryTargetList)
	Setting(bool, GankSpoilMode, SetGankSpoilMode)
	Setting(int, DistanceMaintain, SetDistanceMaintain)
	Setting(int, OrbitDistance, SetOrbitDistance)
	Setting(int, ReservedTargetLocks, SetReservedTargetLocks)
	Setting(int, RepShieldThreshold, SetRepShieldThreshold)
	Setting(int, StopRepShieldThreshold, SetRepShieldThreshold)
	Setting(int, RepArmorThreshold, SetRepArmorThreshold)
	Setting(int, StopRepArmorThreshold, SetRepArmorThreshold)
	Setting(int, CapOutThreshold, SetCapOutThreshold)
	Setting(int, LogLevelBar, SetLogLevelBar)
}

objectdef obj_RemoteRepManagement inherits obj_StateQueue
{
	; Avoid name conflict with common config.
	variable obj_Configuration_RemoteRepManagement Config

	variable bool IsWarpScrambled = FALSE
	variable bool IsOtherPilotsDetected = FALSE
	variable bool IsAttackedByGankers = FALSE
	variable bool IsEngagingGankers = FALSE

	variable bool BotRunningFlag = FALSE
	
	;Of the bots, who leads - Key is Char ID , Bool is true if leader
	variable collection:bool Participants 
	
	;Primary list of rep targets - Key is Entity Name, int is shield or armour HP
	variable collection:int PrimaryReps
	
	;Secondary list of rep targets - Key is Entity Name, int is shield or armour HP - This is for repping blues, corp mates, or randos in highsec for gank spoiling.
	variable collection:int SecondaryReps
	
	;Register the leader - Int is the Char ID of the leader
	variable int RegisteredLeader
	
	;What reps we got
	variable bool WeArmorRep
	variable bool WeShieldRep
	
	;How many things can we target
	variable int MaxTarget = ${MyShip.MaxLockedTargets}
	
	;Register Participants in a non collection list
	variable set RegisteredParticipants
	
	variable obj_TargetList PCs
	variable obj_TargetList NPCs
	variable collection:int AttackTimestamp
	variable int64 currentTarget = 0

	method Initialize()
	{
		This[parent]:Initialize

		DynamicAddMiniMode("RemoteRepManagement", "RemoteRepManagement")
		This.PulseFrequency:Set[500]

		This.NonGameTiedPulse:Set[TRUE]

		; We need to create a list of participants, and determine who is the leader.
		
		LavishScript:RegisterEvent[RR_Participants]
		Event[RR_Participants]:AttachAtom[This:ParticipantRecorder]
		
		This.LogLevelBar:Set[${Config.LogLevelBar}]
	}

	method Start()
	{
		AttackTimestamp:Clear

		if ${This.IsIdle}
		{
			This:LogInfo["Starting"]
			This:QueueState["RemoteRepManagement"]
		}
	}
	
	method Stop()
	{
		This:Clear
	}
	
	
	method ParticipantRecorder(int ParticipantID, bool ParticipantLead)
	{
		;echo ${ParticipantID} ${ParticipantLead}
		Participants:Set[${ParticipantID},${ParticipantLead}]
		;echo ${Participants.Used}
	}
	
	method DetermineRepType()
	{
		if ${Ship.ModuleList_ArmorProjectors.Count} > 0
		{
			WeArmorRep:Set[TRUE]
		}
		if ${Ship.ModuleList_ShieldTransporters.Count} > 0
		{
			WeShieldRep:Set[TRUE]
		}
		
	}
	
	method ParticipantTrigger()
	{
		relay all "Event[RR_Participants]:Execute[${Me.CharID},${Config.IsLeader}]"
	}
	
	member:int TargetCount()
	{
		return ${Math.Calc[${Me.TargetCount} + ${Me.TargetingCount} + ${Config.ReservedTargetLocks}]}
	}
	;The below method is for keeping a list of fleet members who need reps.
	method PrimaryListCompile()
	{
		variable index:entity PrimaryEntities
		variable iterator PrimaryEntitiez
		if ${Client.InSpace}
		{
			EVE:QueryEntities[PrimaryEntities, "IsPC = 1 && Distance > 0 && IsFleetMember = 1"]
			;echo ${PrimaryEntities.Used}
			if ${PrimaryEntities.Used} > 0

			{
				PrimaryEntities:GetIterator[PrimaryEntitiez]
				if ${PrimaryEntitiez:First(exists)}
				{
					do
					{
						if ( ${PrimaryEntitiez.Value.ShieldPct} < ${Config.RepShieldThreshold} ) && ${WeShieldRep} && ( ${PrimaryEntitiez.Value.GroupID} != 900 ) && ( ${PrimaryEntitiez.Value.Distance} < ${Ship.ModuleList_ShieldTransporters.Range} )
							{
								PrimaryReps:Set[${PrimaryEntitiez.Value.Name},${PrimaryEntitiez.Value.ShieldPct}]
								echo Add ${PrimaryEntitiez.Value.Name} to rep list ${PrimaryEntitiez.Value.ShieldPct}
							}
						if ( ${PrimaryEntitiez.Value.ArmorPct} < ${Config.RepArmorThreshold} ) && ${WeArmorRep} && ( ${PrimaryEntitiez.Value.GroupID} != 900 ) && ( ${PrimaryEntitiez.Value.Distance} < ${Ship.ModuleList_ArmorProjectors.Range} )
							{
								PrimaryReps:Set[${PrimaryEntitiez.Value.Name},${PrimaryEntitiez.Value.ArmorPct}]
								echo Add ${PrimaryEntitiez.Value.Name} to rep list ${PrimaryEntitiez.Value.ArmorPct}
							}
					}
					while ${PrimaryEntitiez:Next(exists)}
				}
			}
		}
	}
	;The below method is for keeping a list of corp/alliance members that need reps OR randos for gank spoilage
	method SecondaryListCompile()
	{
		variable index:entity SecondaryEntities
		variable iterator SecondaryEntitiez
		if ${Client.InSpace} && ${Config.UseSecondaryTargetList}
		{
			EVE:QueryEntities[SecondaryEntities, "IsPC = 1 && Distance > 0"]
			echo ${SecondaryEntities.Used}
			if ${SecondaryEntities.Used} > 0
			{
				SecondaryEntities:GetIterator[SecondaryEntitiez]
				if ${SecondaryEntitiez:First(exists)}
				{
					do
					{
						if ( ${SecondaryEntitiez.Value.ShieldPct} < ${Config.RepShieldThreshold} ) && ${WeShieldRep} && ( ${SecondaryEntitiez.Value.IsOwnedByCorpMember} || ${SecondaryEntitiez.Value.IsOwnedByAllianceMember} || ${Config.GankSpoilMode} ) && ${SecondaryEntitiez.Value.Mode} != 3 && !${SecondaryEntitiez.Value.Owner.IsSuspect} && !${SecondaryEntitiez.Value.Owner.IsCriminal} && !${SecondaryEntitiez.Value.Owner.IsLimitedEngagement}
							{
								SecondaryReps:Set[${SecondaryEntitiez.Value.Name},${SecondaryEntitiez.Value.ShieldPct}]
								echo Add ${SecondaryEntitiez.Value.Name} to rep list ${SecondaryEntitiez.Value.ShieldPct}
							}
						if ( ${SecondaryEntitiez.Value.ArmorPct} < ${Config.RepArmorThreshold} ) && ${WeArmorRep} && ( ${SecondaryEntitiez.Value.IsOwnedByCorpMember} || ${SecondaryEntitiez.Value.IsOwnedByAllianceMember} || ${Config.GankSpoilMode} ) && ${SecondaryEntitiez.Value.Mode} != 3 && !${SecondaryEntitiez.Value.Owner.IsSuspect} && !${SecondaryEntitiez.Value.Owner.IsCriminal} && !${SecondaryEntitiez.Value.Owner.IsLimitedEngagement}
							{
								SecondaryReps:Set[${SecondaryEntitiez.Value.Name},${SecondaryEntitiez.Value.ArmorPct}]
								echo Add ${SecondaryEntitiez.Value.Name} to rep list ${SecondaryEntitiez.Value.ArmorPct}
							}
					}
					while ${SecondaryEntitiez:Next(exists)}
				}
			}
		}		
	}
	; Register the Char ID of the Leader and compile a second list of participants for some other things. 
	method RegisterLeader()
	{
		if ${Participants.FirstKey(exists)} && ( ${Participants.Used} > ${RegisteredParticipants.Used} )
		{
			do
			{
				if ${Participants.CurrentValue} == TRUE
				{
					RegisteredLeader:Set[${Participants.CurrentKey}]
					RegisteredParticipants:Add[${Participants.CurrentKey}]
				}
				if ${Participants.CurrentValue} == FALSE
				{
					RegisteredParticipants:Add[${Participants.CurrentKey}]
				}
			}
			while ${Participants.NextKey(exists)}
		}
	}
	; This cleans up the primary rep list as things go away or stop being relevant
	method CleanupPrimary()
	{
		;echo ${PrimaryReps.Used}
		if ${PrimaryReps.FirstKey(exists)}
		{
			do
			{
				if !${Entity[Name == "${PrimaryReps.CurrentKey}"]}
				{
					echo ${PrimaryReps.Used} No More Exist
					PrimaryReps:Erase[${PrimaryReps.CurrentKey}]
				}
				if ${Entity[Name == "${PrimaryReps.CurrentKey}"].ShieldPct} > ${Config.StopRepShieldThreshold} && ${WeShieldRep}
				{
					if ${Entity[Name == "${PrimaryReps.CurrentKey}"].IsLockedTarget} && ( !${RegisteredParticipants.Contains[${Entity[Name == "${PrimaryReps.CurrentKey}"].CharID}]} || !${Config.MaintainFleetLock} )
					{
						Entity[Name == "${PrimaryReps.CurrentKey}"]:UnlockTarget
					}
					echo ${PrimaryReps.Used} Above Shield Threshold
					PrimaryReps:Erase[${PrimaryReps.CurrentKey}]
				}
				if ${Entity[Name == "${PrimaryReps.CurrentKey}"].ArmorPct} > ${Config.StopRepArmorThreshold} && ${WeArmorRep}
				{
					if ${Entity[Name == "${PrimaryReps.CurrentKey}"].IsLockedTarget} && ( !${RegisteredParticipants.Contains[${Entity[Name == "${PrimaryReps.CurrentKey}"].CharID}]} || !${Config.MaintainFleetLock} )
					{
						Entity[Name == "${PrimaryReps.CurrentKey}"]:UnlockTarget
					}
					echo ${PrimaryReps.Used} Above Armour Threshold
					PrimaryReps:Erase[${PrimaryReps.CurrentKey}]
				}
			}
			while ${PrimaryReps.NextKey(exists)}
		}
	}
	; This cleans up the secondary rep list as things go away or stop being relevant	
	method CleanupSecondary()
	{
		if ${SecondaryReps.FirstKey(exists)} && ${Config.UseSecondaryTargetList}
		{
			do
			{
				if !${Entity[Name == "${SecondaryReps.CurrentKey}"]}
				{
					SecondaryReps:Erase[${SecondaryReps.CurrentKey}]
				}
				if ${Entity[Name == "${SecondaryReps.CurrentKey}"].ShieldPct} > ${Config.StopRepShieldThreshold} && ${WeShieldRep}
				{
					if ${Entity[Name == "${SecondaryReps.CurrentKey}"].IsLockedTarget} && ( !${RegisteredParticipants.Contains[${Entity[Name == "${SecondaryReps.CurrentKey}"].CharID}]} || !${Config.MaintainFleetLock} )
					{
						Entity[Name == "${SecondaryReps.CurrentKey}"]:UnlockTarget
					}
					SecondaryReps:Erase[${SecondaryReps.CurrentKey}]
				}
				if ${Entity[Name == "${SecondaryReps.CurrentKey}"].ArmorPct} > ${Config.StopRepArmorThreshold} && ${WeArmorRep}
				{
					if ${Entity[Name == "${SecondaryReps.CurrentKey}"].IsLockedTarget} && ( !${RegisteredParticipants.Contains[${Entity[Name == "${SecondaryReps.CurrentKey}"].CharID}]} || !${Config.MaintainFleetLock} )
					{
						Entity[Name == "${SecondaryReps.CurrentKey}"]:UnlockTarget
					}
					SecondaryReps:Erase[${SecondaryReps.CurrentKey}]
				}
			}
			while ${SecondaryReps.NextKey(exists)}
		}
	}
	
	; Maintain Range on The Leader
	method MaintainRangeToLeader()
	{
		if ${RegisteredLeader} > 0 && ( ${RegisteredLeader} != ${Me.CharID} )
		{
			if ( ${Entity[CharID == ${RegisteredLeader}].Distance} > ${Config.DistanceMaintain} ) && ${MyShip.ToEntity.Mode} != MOVE_ORBITING && ${MyShip.ToEntity.Mode} != MOVE_APPROACHING && ${MyShip.ToEntity.Mode} != MOVE_WARPING
			{
				Entity[CharID == ${RegisteredLeader}]:Orbit[${Config.OrbitDistance}]
			}
		}
	}
	; Maintain locks on participants if configured
	method LockFleetAtAllTimes()
	{
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		if ${Config.MaintainFleetLock}
		{
			if ${This.TargetCount} < ${MaxTarget}
			{
				echo vavoom
				if ${Participants.FirstKey(exists)}
				{
					do
					{
						if !${Entity[CharID == "${Participants.CurrentKey}"].IsLockedTarget} && !${Entity[CharID == "${Participants.CurrentKey}"].BeingTargeted} && ${Entity[CharID == "${Participants.CurrentKey}"].Name.NotEqual[NULL]}
						{
							Entity[CharID == "${Participants.CurrentKey}"]:LockTarget
						}
					}
					while ${Participants.NextKey(exists)} 
				}
			}
		}
	}
	; Do locks on demand if too many people or if we are gank spoiling
	method LockTheNeedy()
	{
		;echo ${This.TargetCount} ${MaxTarget}
		;echo ${PrimaryReps.Used}
		if ${This.TargetCount} < ${MaxTarget}
		{
			if ${PrimaryReps.FirstKey(exists)}
			{
				do
				{
					if !${Entity[Name == "${PrimaryReps.CurrentKey}"].IsLockedTarget} && !${Entity[Name == "${PrimaryReps.CurrentKey}"].BeingTargeted} && ${Entity[Name == "${PrimaryReps.CurrentKey}"].Name.NotEqual[NULL]}
					{
						Entity[Name == "${PrimaryReps.CurrentKey}"]:LockTarget
					}
				}
				while ${PrimaryReps.NextKey(exists)}
			}
		}
		if ${This.TargetCount} < ${MaxTarget}
		{
			if ${SecondaryReps.FirstKey(exists)} && ${Config.UseSecondaryTargetList}
			{
				do
				{
					if !${Entity[Name == "${SecondaryReps.CurrentKey}"].IsLockedTarget} && !${Entity[Name == "${SecondaryReps.CurrentKey}"].BeingTargeted} && ${Entity[Name == "${SecondaryReps.CurrentKey}"].Name.NotEqual[NULL]}
					{
						Entity[Name == "${SecondaryReps.CurrentKey}"]:LockTarget
					}
				}
				while ${SecondaryReps.NextKey(exists)}
			}
		}
		
	}
	; Time for the real stuff, let us remote rep
	method RepActivation()
	{
		if ${PrimaryReps.FirstKey(exists)}
		{
			if ${Entity[Name == "${PrimaryReps.CurrentKey}"].IsLockedTarget} && ${Ship.ModuleList_ArmorProjectors.Count} > ${Ship.ModuleList_ArmorProjectors.ActiveCount}
			{
				Ship.ModuleList_ArmorProjectors:ActivateAll[${Entity[Name == "${PrimaryReps.CurrentKey}"].ID}]
			}
			if ${Entity[Name == "${PrimaryReps.CurrentKey}"].IsLockedTarget} && ${Ship.ModuleList_ShieldTransporters.Count} > ${Ship.ModuleList_ShieldTransporters.ActiveCount}
			{
				Ship.ModuleList_ShieldTransporters:ActivateAll[${Entity[Name == "${PrimaryReps.CurrentKey}"].ID}]
			}
		}
		if ${SecondaryReps.FirstKey(exists)} && ${Config.UseSecondaryTargetList}
		{
			if ${Entity[Name == "${SecondaryReps.CurrentKey}"].IsLockedTarget} && ${Ship.ModuleList_ArmorProjectors.Count} > ${Ship.ModuleList_ArmorProjectors.ActiveCount}
			{
				Ship.ModuleList_ArmorProjectors:ActivateAll[${Entity[Name == "${SecondaryReps.CurrentKey}"].ID}]
			}
			if ${Entity[Name == "${SecondaryReps.CurrentKey}"].IsLockedTarget} && ${Ship.ModuleList_ShieldTransporters.Count} > ${Ship.ModuleList_ShieldTransporters.ActiveCount}
			{
				Ship.ModuleList_ShieldTransporters:ActivateAll[${Entity[Name == "${SecondaryReps.CurrentKey}"].ID}]
			}
		}
	}
	; Let us deactivate the remote reps due to cap shortage, or we need to stop them for the forced fleet lock setup when the fleet members have no damage.
	method RepDeactivation()
	{
		variable index:entity StopRepHelper
		variable iterator StopRepHelper2
		
		EVE:QueryEntities[StopRepHelper, "IsLockedTarget = 1"]
		if ${StopRepHelper.Used} > 0
		StopRepHelper:GetIterator[StopRepHelper2]
		if ${StopRepHelper2:First(exists)}
		{
			do
			{
				if ${Ship.ModuleList_ArmorProjectors.ActiveCount} > 0
				{
					if ${MyShip.CapacitorPct.Int} < ${Config.CapOutThreshold}
					{
						Ship.ModuleList_ArmorProjectors:DeactivateAll
					}
					if ${StopRepHelper2.Value.ArmorPct} > ${Config.StopRepArmorThreshold}
					{
						Ship.ModuleList_ArmorProjectors:DeactivateOn[${StopRepHelper2.Value.ID}]
					}
				}
				if ${Ship.ModuleList_ShieldTransporters.ActiveCount} > 0
				{
					if ${MyShip.CapacitorPct.Int} < ${Config.CapOutThreshold}
					{
						Ship.ModuleList_ArmorProjectors:DeactivateAll			
					}
					if ${StopRepHelper2.Value.ShieldPct} > ${Config.StopRepShieldThreshold}
					{
						Ship.ModuleList_ArmorProjectors:DeactivateOn[${StopRepHelper2.Value.ID}]
					}
				}
			}
			while ${StopRepHelper2:Next(exists)}
		}
	}
	member:bool RemoteRepManagement()
	{
		if ${Me.InStation}
		{
			return FALSE
		}

		; While currently jumping, Me.InSpace is false and status numbers will be null.
		if !${Client.InSpace}
		{
			This:LogDebug["Not in space, jumping?"]
			return FALSE
		}
		if ${MyShip.ToEntity.Mode} == MOVE_WARPING
		{
			return FALSE
		}
		This:ParticipantTrigger
		This:DetermineRepType
		This:PrimaryListCompile
		This:SecondaryListCompile
		This:RegisterLeader
		This:CleanupPrimary
		This:CleanupSecondary
		This:MaintainRangeToLeader
		This:LockFleetAtAllTimes
		This:LockTheNeedy
		if ${MyShip.CapacitorPct.Int} > ${Config.CapOutThreshold}
		{
			This:RepActivation
		}
		This:RepDeactivation
		
		return FALSE
	}
}