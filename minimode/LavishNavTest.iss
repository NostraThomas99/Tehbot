objectdef obj_Configuration_LavishNavTest inherits obj_Configuration_Base
{
	method Initialize()
	{
		This[parent]:Initialize["LavishNavTest"]
	}

	method Set_Default_Values()
	{
		ConfigManager.ConfigRoot:AddSet[${This.SetName}]
	}

}

objectdef obj_LavishNavTest inherits obj_StateQueue
{
	; Avoid name conflict with common config.
	variable obj_Configuration_LavishNavTest Config
	; Still working out what these do and how.
	variable lnavregionref CorridorContainer
	; These would be used, if I felt the need to. I do not feel the need to at this moment.
	variable float64 CurrentXOffset
	variable float64 CurrentYOffset
	variable float64 CurrentZOffset
	; This queue holds our future positions, we will use these to place Sphere LavishNav regions.
	variable queue:point3f FuturePositions
	; How many seconds ahead will we be looking?
	variable int SecondsFromNow = 300
	; This bool will be set by Mining when it is time to make the orb.
	variable bool TimeForOrb
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		This.PulseFrequency:Set[1000]
		DynamicAddMiniMode("LavishNavTest", "LavishNavTest")

		This.LogLevelBar:Set[${CommonConfig.LogLevelBar}]

	}

	method Start()
	{
		This:QueueState["LavishNavTest"]
	}

	method Stop()
	{
		LavishNav:Clear
		SystemContainer:Remove
		This:Clear
	}
	
	method InitializeRegions()
	{
		;This:Output["Initializing regions."]
		LavishNav.Tree:AddChild[universe,EVE,-unique]

		LNavRegion[EVE]:AddChild[universe,TheSystem,-unique,-coordinatesystem]

		LNavRegion[TheSystem]:AddChild[universe,TheGrid,-unique]
	}
	
	; Alright so this will use your current velocity (and its x/y/z components) to determine where we will be in some
	; amount of time. I think I am doing this to make the align structure option in the mining mode work more effectively.
	method EstablishFuturePositions()
	{
		variable float64 MyVelocityX = ${Me.ToEntity.vX}
		variable float64 MyVelocityY = ${Me.ToEntity.vY}
		variable float64 MyVelocityZ = ${Me.ToEntity.vZ}
		variable float64 MyCoordX = ${Me.ToEntity.X}
		variable float64 MyCoordY = ${Me.ToEntity.Y}
		variable float64 MyCoordZ = ${Me.ToEntity.Z}
		variable float64 TempFutureCoordX
		variable float64 TempFutureCoordY
		variable float64 TempFutureCoordZ
		
		echo ${Me.ToEntity.vX} vX ${Me.ToEntity.vY} vY ${Me.ToEntity.vZ} vZ
		echo ${Me.ToEntity.X} X ${Me.ToEntity.Y} Y ${Me.ToEntity.Z} Z	
		if ${MyCoordX} !~ NULL && ${MyVelocityX} !~ NULL
		{
			; Lets see if I can remember how to make the SIMPLEST OF MATH occur
			TempFutureCoordX:Set[${Math.Calc[${MyCoordX} + (${MyVelocityX} * ${SecondsFromNow})]}]
			TempFutureCoordY:Set[${Math.Calc[${MyCoordY} + (${MyVelocityY} * ${SecondsFromNow})]}]
			TempFutureCoordZ:Set[${Math.Calc[${MyCoordZ} + (${MyVelocityZ} * ${SecondsFromNow})]}]
			
			;echo ${TempFutureCoordX}

			if ${TempFutureCoordX} !~ NULL
			{
				FuturePositions:Queue[${TempFutureCoordX},${TempFutureCoordY},${TempFutureCoordZ}]
				;echo ${FuturePositions.Peek.X}, ${FuturePositions.Peek.Y}, ${FuturePositions.Peek.Z}
			}
		}
	}
	; This method will place a Sphere centered on our FuturePositions coordinates, the size will be based on 85% of our mining range (for now)
	method PlaceTheOrb()
	{
		SystemContainer:Add[sphere,"auto",${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * 0.85]},${FuturePositions.Peek.X},${FuturePositions.Peek.Y},${FuturePositions.Peek.Z}]
		FuturePositions:Dequeue
	}
	; I think a box will be better suited to this tbh
	method DrawTheBox()
	{
		variable float64 MyCoordX = ${Me.ToEntity.X}
		variable float64 MyCoordY = ${Me.ToEntity.Y}
		variable float64 MyCoordZ = ${Me.ToEntity.Z}
		variable float64 BoxX1
		variable float64 BoxX2
		variable float64 BoxY1		
		variable float64 BoxY2
		variable float64 BoxZ1
		variable float64 BoxZ2
		
		; Alright so here is what will happen here. We are going to create a box that defines a corridor ahead of us.
		; The starting point will be centered on our current position, but LavishNav would just generate a box with half
		; Of it behind us and half of it ahead of us. Instead we need to define 8 coordinates. The first 4 will define a square
		; Centered on our current position. The second set of 4 coords will define a square centered on our position 5 minutes
		; From now. The box input takes only 6 numbers though so you are basically telling it where one of the corners
		; Of the square starts and then how long one side of the square is, how tall the other side is, and how far away
		; The second square is. I think, man idk math.
		; Actually, X1,Y1,Z1 defines one corner of the box and X2,Y2,Z2 defines the opposite corner. Although apparently
		; Mathematically speaking the statements are equivalent.
		; Anywho, the length of each side of the squares will be 80% of your mining range, for now.

		BoxX1:Set[${Math.Calc[${MyCoordX} - (${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * 0.8]} * 0.5)]}]
		BoxY1:Set[${Math.Calc[${MyCoordY} - (${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * 0.8]} * 0.5)]}]
		BoxZ1:Set[${Math.Calc[${MyCoordZ}]}]		
		
		BoxX2:Set[${Math.Calc[${FuturePositions.Peek.X} + (${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * 0.8]} * 0.5)]}]
		BoxY2:Set[${Math.Calc[${FuturePositions.Peek.Y} + (${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * 0.8]} * 0.5)]}]
		BoxZ2:Set[${Math.Calc[${FuturePositions.Peek.Z}]}]				
		
		;echo ${FuturePositions.Peek.X}, ${FuturePositions.Peek.Y}, ${FuturePositions.Peek.Z}
		
		;echo ${BoxX1},${BoxX2},${BoxY1},${BoxY2},${BoxZ1},${BoxZ2}
		if ${LNavRegion[Corridor.TheGrid](exists)}
		{
			LNavRegion[Corridor.TheGrid]:Remove
		}
		
		LNavRegion[EVE].Children[TheSystem].Children[TheGrid]:AddChild[box,"Corridor",-unique,${BoxX1},${BoxX2},${BoxY1},${BoxY2},${BoxZ1},${BoxZ2}]

		;LocalContainer:SetRegion[${SystemContainer.AddChild[box,"Corridor",-unique,${BoxX1},${BoxX2},${BoxY1},${BoxY2},${BoxZ1},${BoxZ2}]}]
		;LocalContainer:SetRegion[box,"Corridor",${BoxX1},${BoxX2},${BoxY1},${BoxY2},${BoxZ1},${BoxZ2}]
		FuturePositions:Dequeue
		

	}
	member:bool LavishNavTest()
	{
		if ${TimeForOrb}
		{
			if !${LNavRegion[Corridor.TheGrid](exists)}
			{
				This:InitializeRegions
			}

			if ${Client.InSpace}
			{
				This:EstablishFuturePositions
			}
			
			if ${FuturePositions.Peek.X}
			{
				;This:PlaceTheOrb
				This:DrawTheBox
				TimeForOrb:Set[FALSE]
			}
		}
		return FALSE
	}
}