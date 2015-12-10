class HijinksPlayerCharacterController extends antics_v5.anticsCharacterController;

import enum EAllyType from ObjectiveInfo;
import enum EObjectiveType from ObjectiveInfo;

var Hijinks HijinksMutator;

var int CurrentSpeedHackViolations;
var int TotalSpeedHackViolations;

var float SpeedHackDeltaModifier;

simulated function PostBeginPlay(){
	
	super.PostBeginPlay();
	CurrentSpeedHackViolations = 0;
	TotalSpeedHackViolations = 0;
	SpeedHackDeltaModifier = 1;	// initial value, set the proper one in the mutator
}

simulated function initHUDObjects()
{
	if (HUDManager == None)
	{
		HUDManager = new class'HijinksTribesHUDManager';
		HUDManager.Initialise(self);
	}

	if (clientSideChar == None)
	{
		clientSideChar = new class'ClientSideCharacter';
	}
}

simulated function Vector calculateScreenPosition(class objectClass, Vector objectPos)
{

	local Vector ScreenPos;
	local bool Reset;
	local ObjectiveInfo ObjInfo;
	local int i;
	
	local Vector HitLocation;
	local Vector HitNormal;
	local Actor TraceReceiver;
		
	// TODO Remove this line after testing
	// return super.calculateScreenPosition(objectClass, objectPos);
	
	Reset = false;
	
	/*
	We can probably skip this one, since we "fix" the info in the hud manager
	
	if (ClassIsChildOf(objectClass, class'ObjectiveInfo'))
	{
		ObjInfo = character.team().objectives.first();
		
		while (ObjInfo != None && !Reset)
		{
			if (ObjInfo.numObjectiveActors > 0 && 
				ObjInfo.type == EObjectiveType.ObjectiveType_Primary  &&
				ObjInfo.class == objectClass)
			{
				for (i = 0; i < ObjInfo.numObjectiveActors; ++i){
				
					if (ObjInfo.allyType[i] != EAllyType.AllyType_Neutral && 
						ObjInfo.pos[i].X == objectPos.X && 
						ObjInfo.pos[i].Y == objectPos.Y)
					{
						Reset = true;
						break;
					}
				}
			}
			
			ObjInfo = ObjInfo.next;
		}
	}
	*/
	
	if (!Reset && ClassIsChildOf(objectClass, class'RadarInfo')){
		
		Reset = true;
		
		TraceReceiver = Trace(HitLocation, HitNormal, objectPos, Pawn.Location + Pawn.EyePosition(), true);
		
		if (TraceReceiver != None && ClassIsChildOf(TraceReceiver.class, class'Rook')){
			reset = false;
		}
	}
	if (Reset){
		ScreenPos.x = -1;
		ScreenPos.y = -1;
	}else{
		ScreenPos = super.calculateScreenPosition(objectClass, objectPos);
	}
	
	return ScreenPos;
}

function TribesServerMove
(
	float TimeStamp, 
	Vector ClientLoc,
	int View,
	EDigitalAxisInput digitalForward,
	EDigitalAxisInput digitalStrafe,
	bool ski,
	bool thrust,
	bool jump,
    optional byte CompressedImportantTimeDelta,
	optional int ImportantMoveData
)
{
	local float DeltaTime, clientErr, ImportantTimeStamp;
	local rotator Rot, ViewRot;
	local vector LocDiff;
	local int ViewPitch, ViewYaw;
	local float analogueForward;
	local float analogueStrafe;
	local float importantStrafe, importantForward, importantDelta;
	local int importantJump, importantSki, importantThrust;
	local int importantPitch, importantYaw;

	analogueForward = digitalToAnalogue(digitalForward, 1);
	analogueStrafe = digitalToAnalogue(digitalStrafe, 1);

	// first move will have no previous timestamp to form delta, so set CurrentTimeStamp to use as delta and that's all
	if ( CurrentTimeStamp == 0 )
	{
		if (debugLogLevel > 0)
			LOG("SERVER FIRST MOVE!");
		CurrentTimeStamp = TimeStamp;
		return;
	}

	// If this move is outdated, discard it.
	if ( CurrentTimeStamp >= TimeStamp )
	{
		if (debugLogLevel > 0) LOG("Discarded");
		return;
	}

    // check if an important move was lost
    if ( CompressedImportantTimeDelta != 0 )
    {
		class'SavedMove'.static.decodeImportantData(
			ImportantMoveData, 
			CompressedImportantTimeDelta,
			importantThrust, 
			importantSki, 
			importantJump, 
			importantForward, 
			importantStrafe, 
			importantPitch, 
			importantYaw, 
			importantDelta
			);

		// CurrentTimeStamp is time of last processed packet from client.
		// Timestamp is time of incoming client packet and CurrentTimeStamp + [client delta] should equal Timestamp.
		// If Timestamp - ImportantDelta is greater than CurrentTimeStamp, then a packet must have been lost
		// before the current packet was received. Perform the important movement before the current movement for greater prediction accuracy
		// on lossy connections.
        ImportantTimeStamp = TimeStamp - importantDelta - 0.001;
        if ( CurrentTimeStamp < ImportantTimeStamp - 0.001 )
        {
			ViewRot.Roll = 0;
			ViewRot.Pitch = importantPitch;
			ViewRot.Yaw = importantYaw;

            ImportantTimeStamp = FMin(ImportantTimeStamp, CurrentTimeStamp + MaxResponseTime);
            TribesMoveAutonomous(ImportantTimeStamp - CurrentTimeStamp, ViewRot, importantForward, importantStrafe, importantSki != 0, importantThrust != 0, importantJump != 0);
			CurrentTimeStamp = ImportantTimeStamp;
		}
	}

	// View components
	ViewPitch = class'SavedMove'.static.decodeViewPitch(View);
	ViewYaw = class'SavedMove'.static.decodeViewYaw(View);

	// Save move parameters.
    DeltaTime = FMin(MaxResponseTime, TimeStamp - CurrentTimeStamp);

	if ( Pawn == None )
	{
		TimeMargin = 0;
	}
	else if (!CheckSpeedHack(DeltaTime*SpeedHackDeltaModifier))
	{
		CurrentSpeedHackViolations++;
		TotalSpeedHackViolations++;
	}
		
	CurrentTimeStamp = TimeStamp;
	ServerTimeStamp = Level.TimeSeconds;
	ViewRot.Pitch = ViewPitch;
	ViewRot.Yaw = ViewYaw;
	ViewRot.Roll = 0;
	SetRotation(ViewRot);

	if ( Pawn != None )
	{
		Rot.Yaw = ViewYaw;
		Pawn.SetRotation(Rot);
	}

    // Perform actual movement
	if ( (Level.Pauser == None) && (DeltaTime > 0) )
	{
        TribesMoveAutonomous(DeltaTime, ViewRot, analogueForward, analogueStrafe, ski, thrust, jump);
	}

	if (debugLogLevel > 1)
		log(character.movementObject.getEndPosition());

	// Accumulate movement error.
    if ( ClientLoc == vect(0,0,0) )
		return;		// first part of double servermove
	else if ( Level.TimeSeconds - LastUpdateTime > 0.3 )
		ClientErr = 10000;
	else if ( Level.TimeSeconds - LastUpdateTime > 180.0/Player.CurrentNetSpeed )
	{
	    if (character!=None && character.movementObject!=None)
		    LocDiff = character.movementObject.getEndPosition() - ClientLoc;
		else if (Pawn!=None)
			LocDiff = Pawn.Location - ClientLoc;
		else
			LocDiff = Location - ClientLoc;
		ClientErr = LocDiff Dot LocDiff;
	}

	// If client has accumulated a noticeable positional error, correct him.
	if ( ClientErr > 3 )
	{
		PendingAdjustment.Timestamp = Timestamp;
		PendingAdjustment.newState = GetStateName();

        if (character!=None && Pawn != None)
        {
			PendingAdjustment.energy = character.energy;
			PendingAdjustment.NewVel = character.Velocity;
			PendingAdjustment.movement = character.movement;
			
			if (character.movementObject!=None)
			{
				PendingAdjustment.StartLoc = character.movementObject.getStartPosition();
				PendingAdjustment.EndLoc = character.movementObject.getEndPosition();
				PendingAdjustment.accumulator = character.movementObject.getAccumulator();
			}
		    else
			{
				PendingAdjustment.StartLoc = Location;
				PendingAdjustment.EndLoc = Location;
			}
        }
		else if (Pawn!=None)
		{
			PendingAdjustment.StartLoc = Pawn.Location;
			PendingAdjustment.EndLoc = Pawn.Location;
			PendingAdjustment.NewVel = Pawn.Velocity;
		}
		else
		{
			PendingAdjustment.StartLoc = Location;
			PendingAdjustment.EndLoc = Location;
			PendingAdjustment.NewVel = Velocity;
		}

		if (debugLogLevel > 0 && ClientErr != 10000)
			log("Client Error at "$TimeStamp$" is "$ClientErr$" LocDiff "$LocDiff$" Physics "$Pawn.Physics);
	}

	//log("Server moved stamp "$TimeStamp$" location "$Pawn.Location$" Acceleration "$Pawn.Acceleration$" Velocity "$Pawn.Velocity);
}