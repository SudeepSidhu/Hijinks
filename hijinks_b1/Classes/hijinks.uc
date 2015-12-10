class hijinks extends Gameplay.Mutator;

var string selfServerPackage;
var string anticsServerPackage;

function PreBeginPlay()
{
	super.PreBeginPlay();
	
	selfServerPackage = "hijinks_b1";
	anticsServerPackage = "antics_v5";

	AddServerPackage(anticsServerPackage);
	AddServerPackage(selfServerPackage);
	
	LoadCharacterController();	
}

function PostBeginPlay()
{
	super.PostBeginPlay();
}

function AddServerPackage(string package)
{
	local bool addServerPackage;
	local int i;
	
	addServerPackage = true;
	
	for(i = 0; i < class'Engine.GameEngine'.default.ServerPackages.Length; i++)
	{
		if(class'Engine.GameEngine'.default.ServerPackages[i] == package)
		{
			addServerPackage = false;
			break;
		}
	}
	
	if(addServerPackage)
	{
		class'Engine.GameEngine'.default.ServerPackages[class'Engine.GameEngine'.default.ServerPackages.Length] = package;
		class'Engine.GameEngine'.static.StaticSaveConfig();
		log("Added a server package, server requires a restart for setup to complete!", 'hijinks');     
	}
}

function LoadCharacterController()
{
	local Gameplay.ModeInfo MI;
	
	foreach AllActors(class'Gameplay.ModeInfo', MI)
	{
		if (MI != None)
		{
			MI.PlayerControllerClassName = selfServerPackage $ ".hijinksPlayerController";
			log("hijinks player controller loaded successfully!", 'hijinks');
			break;
		}
	}
}