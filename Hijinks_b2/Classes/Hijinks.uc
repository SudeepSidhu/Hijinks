class Hijinks extends Gameplay.Mutator config(Hijinks);

var string SelfServerPackage;
var string AnticsServerPackage;

var config string LogFileName;

var config float SpeedHackSensitivity;
var config bool StopSpeedHackerOnDetection;

var config int SpeedHackViolationsBeforeDiscipline;
var config bool SpeedHackDisciplineWithCrater;
var config bool SpeedHackDisciplineWithKick;
var config bool SpeedHackDisciplineWithBan;
var config bool SpeedHackBanIsPermanent;
var config bool SpeedHackDisciplineWithPublicShaming;

var config bool BroadcastKicksAndBans;

function PreBeginPlay()
{
	super.PreBeginPlay();
	
	SelfServerPackage = "Hijinks_b2";
	AnticsServerPackage = "antics_v5";

	AddServerPackage(AnticsServerPackage);
	AddServerPackage(SelfServerPackage);
	
	LoadCharacterController();	
	
	SetTimer(10, true);
}

function PostBeginPlay()
{
	super.PostBeginPlay();
}

function Destroyed()
{
	local Controller C;
	local HijinksPlayerCharacterController PC;
	
	for(C = Level.ControllerList; C != None && C.PlayerReplicationInfo != None; C = C.NextController)
	{
		PC = HijinksPlayerCharacterController(C);

		if (PC != None)
		{
			LogPlayerSession(PC);
		}
	}
	
	Super.Destroyed();
}

// Notification that a player is exiting
function NotifyLogout(Controller Exiting)
{
	local HijinksPlayerCharacterController C;
	
	C = HijinksPlayerCharacterController(Exiting);
	
	LogPlayerSession(C);
	
	C.HijinksMutator = Self;
	C.SpeedHackDeltaModifier = 1.0;
	C.StopSpeedHacker = false;
	
	ResetSpeedViolations(C, true);
	
	Super.NotifyLogout(Exiting);
}

function AddServerPackage(string Package)
{
	local bool AddServerPackage;
	local int i;
	
	AddServerPackage = true;
	
	for(i = 0; i < class'Engine.GameEngine'.default.ServerPackages.Length; i++)
	{
		if (class'Engine.GameEngine'.default.ServerPackages[i] == Package)
		{
			AddServerPackage = false;
			break;
		}
	}
	
	if (AddServerPackage)
	{
		class'Engine.GameEngine'.default.ServerPackages[class'Engine.GameEngine'.default.ServerPackages.Length] = Package;
		class'Engine.GameEngine'.static.StaticSaveConfig();
		LogInternal("Added a server package '" $ Package $ "'. Server requires a restart for setup to complete!", true);     
	}
}

function LoadCharacterController()
{
	local Gameplay.ModeInfo MI;
	
	foreach AllActors(class'Gameplay.ModeInfo', MI)
	{
		if (MI != None)
		{
			MI.PlayerControllerClassName = SelfServerPackage $ ".HijinksPlayerCharacterController";
			LogInternal("Hijinks player controller loaded successfully!", true);
			break;
		}
	}
}

function Timer()
{	
	// LogInternal("tick", true);
	CheckCurrentPlayers();
}

function CheckCurrentPlayers()
{
	local Controller C;
	local HijinksPlayerCharacterController PC;
	
	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		PC = HijinksPlayerCharacterController(C);
	
		if (PC != None && PC.PlayerReplicationInfo != None)
		{
			if (PC.HijinksMutator != Self)
			{
				TrackPlayer(PC);
			}
			else if (PC.currentSpeedHackViolations > SpeedHackViolationsBeforeDiscipline)
			{
				LogSpeedHacker(PC);
				DisciplineSpeedHacker(PC);
				ResetSpeedViolations(PC, false);
			}
		}
	}
}

function TrackPlayer(HijinksPlayerCharacterController C)
{
	C.HijinksMutator = Self;
	C.SpeedHackDeltaModifier = SpeedHackSensitivity;
	C.StopSpeedHacker = StopSpeedHackerOnDetection;
	
	ResetSpeedViolations(C, true);
	LogInternal(GetPlayerCard(C)$" is now being tracked by Hijinks", true);
}

function LogPlayerSession(HijinksPlayerCharacterController C)
{
	LogInternal("Session stats for "$GetPlayerCard(C)$" -> Speed violations: "$C.TotalSpeedHackViolations, true);
}

function LogSpeedHacker(HijinksPlayerCharacterController C)
{
	LogInternal(GetPlayerCard(C)$" has exceeded violation count for speed hacking!", true);
}

function DisciplineSpeedHacker(HijinksPlayerCharacterController C)
{
	
	if (SpeedHackDisciplineWithCrater)
	{
		C.Pawn.unifiedSetVelocity(vect(0,0,-10000));
	}

	if (SpeedHackDisciplineWithPublicShaming)
	{
		Level.Game.BroadcastLocalized(self, class'HijinksGameMessage', 1337, C.PlayerReplicationInfo);
	}

	if (SpeedHackDisciplineWithKick)
	{
		Level.Game.AccessControl.KickPlayer(C);
		LogInternal(GetPlayerCard(C)$" has been kicked for speed hacking!", true);
		
		if (BroadcastKicksAndBans)
		{
			Level.Game.BroadcastLocalized(self, class'HijinksGameMessage', 1338, C.PlayerReplicationInfo);
		}
	}
	else if (SpeedHackDisciplineWithBan)
	{
		Level.Game.AccessControl.BanPlayer((C), !SpeedHackBanIsPermanent);
		
		if (SpeedHackBanIsPermanent)
		{
			LogInternal(GetPlayerCard(C)$" has been permanently banned for speed hacking!", true);
			
			if (BroadcastKicksAndBans)
			{
				Level.Game.BroadcastLocalized(self, class'HijinksGameMessage', 1340, C.PlayerReplicationInfo);
			}
		}
		else
		{
			LogInternal(GetPlayerCard(C)$" has been temporarily banned  for speed hacking!", true);
			
			if (BroadcastKicksAndBans)
			{
				Level.Game.BroadcastLocalized(self, class'HijinksGameMessage', 1339, C.PlayerReplicationInfo);
			}
		}
	}
}

function ResetSpeedViolations(HijinksPlayerCharacterController C, bool ResetTotal)
{
	C.CurrentSpeedHackViolations = 0;
	
	if (ResetTotal)
	{
		C.TotalSpeedHackViolations = 0;
	}
}

function string GetPlayerCard(HijinksPlayerCharacterController C)
{
	local string PlayerName;
	local string PlayerIP;
	
	PlayerName = C.PlayerReplicationInfo.PlayerName;
	PlayerIP = GetIPAddress(C);
	
	if (Len(PlayerIP) > 0)
	{
		return "'"$PlayerName$"'("$PlayerIP$")";
	}
	else
	{
		return "'"$PlayerName$"'";
	}
}

function string GetIPAddress(HijinksPlayerCharacterController C)
{
	local string IPAddressLong;
	local string IPAddress;
	local string IPAddressPort;
	
	IPAddressLong = C.GetPlayerNetworkAddress();
	Div(IPAddressLong, ":", IPAddress, IPAddressPort);
	
	return IPAddress;
}

function LogInternal(string LogString, bool LogToConsole)
{
	local FileLog LogFile;
	local string TimeString;
	
	LogFile = spawn(class 'FileLog');
	
	if (LogFile == None)
	{
		Log("Could not spawn hijinks log", 'Hijinks');
	}
	else
	{
		TimeString = CurrentTimeString();
		
		LogFile.OpenLog(LogFileName);
		LogFile.LogF(TimeString$":"@LogString);
		
		// we do this so the data is flushed immediately for the admin to view
		// since we're not logging that often, the inefficiency of this shouldn't matter
		LogFile.CloseLog();
		LogFile.Destroy();	
	}
	
	if (LogToConsole)
	{
		Log(LogString, 'Hijinks');
	}
}

function string CurrentTimeString()
{

	local string Year;
	local string Month;
	local string Day;
	local string Hour;
	local string Minute;
	local string Second;
	
	Year = CorrectDateFormat(Level.Year, 4);
	Month = CorrectDateFormat(Level.Month, 2);
	Day = CorrectDateFormat(Level.Day, 2);
	Hour = CorrectDateFormat(Level.Hour, 2);
	Minute = CorrectDateFormat(Level.Minute, 2);
	Second = CorrectDateFormat(Level.Second, 2);
	
	return Year$"-"$Month$"-"$Day$" "$Hour$":"$Minute$":"$Second;
}

function string CorrectDateFormat(Int Value, int Places)
{
	local string StringValue;
	
	StringValue = ""$Value;
	
	while (Len(StringValue) < Places)
	{
		StringValue = "0"$StringValue;
	}
	
	return StringValue;
}

defaultproperties
{
	LogFileName = "HijinksLog";
	SpeedHackSensitivity = 1.0;
	StopSpeedHackerOnDetection = false;
	SpeedHackViolationsBeforeDiscipline = 100;
	SpeedHackDisciplineWithCrater = true;
	SpeedHackDisciplineWithKick = false;
	SpeedHackDisciplineWithBan = false;
	SpeedHackBanIsPermanent = false;
	SpeedHackDisciplineWithPublicShaming = false;
	BroadcastKicksAndBans = false;
}