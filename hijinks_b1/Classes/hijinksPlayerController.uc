class hijinksPlayerController extends antics_v5.anticsCharacterController;

import enum EAllyType from ObjectiveInfo;
import enum EObjectiveType from ObjectiveInfo;

simulated function Vector calculateScreenPosition(class objectClass, Vector objectPos)
{
	local Vector screenPos;
	local bool reset;
	local ObjectiveInfo objInfo;
	local int i;
	
	reset = false;
	
	if(ClassIsChildOf(objectClass, class'ObjectiveInfo'))
	{
		objInfo = character.team().objectives.first();
		
		while (objInfo != None && !reset)
		{
			if (objInfo.numObjectiveActors > 0 && 
				objInfo.type == EObjectiveType.ObjectiveType_Primary  &&
				objInfo.class == objectClass)
			{
				for (i = 0; i < objInfo.numObjectiveActors; ++i){
				
					if (objInfo.allyType[i] != EAllyType.AllyType_Neutral && 
						objInfo.pos[i].X == objectPos.X && 
						objInfo.pos[i].Y == objectPos.Y)
					{
						reset = true;
						break;
					}
				}
			}
			
			objInfo = objInfo.next;
		}
	}

	if (reset){
		screenPos.x = 0;
		screenPos.y = 0;
	}else{
		screenPos = super.calculateScreenPosition(objectClass, objectPos);
	}
	
	return screenPos;
}