class HijinksTribesHUDManager extends GamePlay.TribesHUDManager threaded transient;

import enum EAllyType from ObjectiveInfo;
import enum EObjectiveType from ObjectiveInfo;

function FixObjectiveData()
{
	local ObjectiveInfo ObjInfo;
	local int i;
	
	if (Controller != None)
	{
		ObjInfo = Controller.character.team().objectives.first();
			
		while (ObjInfo != None)
		{
			if (ObjInfo.numObjectiveActors > 0 && 
				ObjInfo.type == EObjectiveType.ObjectiveType_Primary)
			{
				for (i = 0; i < ObjInfo.numObjectiveActors; ++i){
				
					if (ObjInfo.allyType[i] != EAllyType.AllyType_Neutral)
					{
						ObjInfo.pos[i].Z = 200000;
					}
				}
			}
			
			ObjInfo = ObjInfo.next;
		}
	}
}

function UpdateHUDData()
{
	FixObjectiveData();
	super.UpdateHUDData();
}