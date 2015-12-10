class HijinksGameMessage extends Gameplay.TribesGameMessage;

var localized string SpeedHackPublicShamingMessage;
var localized string SpeedHackKickMessage;
var localized string SpeedHackTempBanMessage;
var localized string SpeedHackPermaBanMessage;

static function string GetString(optional int Switch, optional Core.Object Related1, optional Core.Object Related2, optional Core.Object OptionalObject, optional String OptionalString) {

    local PlayerReplicationInfo PRI;

    PRI = PlayerReplicationInfo(Related1);
   
    switch (Switch) {
		case 1337:
            return replaceStr(default.SpeedHackPublicShamingMessage, PRI.PlayerName);
            break;
		case 1338:
            return replaceStr(default.SpeedHackKickMessage, PRI.PlayerName);
            break;
		case 1339:
            return replaceStr(default.SpeedHackTempBanMessage, PRI.PlayerName);
            break;
		case 1340:
            return replaceStr(default.SpeedHackPermaBanMessage, PRI.PlayerName);
            break;
    }
	
    return super.GetString(Switch, Related1, Related2, OptionalObject, OptionalString);
}

defaultproperties
{
	SpeedHackPublicShamingMessage = "%1 is likely speed hacking..."
	SpeedHackKickMessage = "%1 has been kicked for speed hacking!"
	SpeedHackTempBanMessage = "%1 has been banned temporarily for speed hacking!"
	SpeedHackPermaBanMessage = "%1 has been banned permanently for speed hacking!"
}