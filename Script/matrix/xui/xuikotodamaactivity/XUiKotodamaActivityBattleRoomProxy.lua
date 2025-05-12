local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiKotodamaActivityBattleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, 'XUiKotodamaActivityBattleRoomProxy')

function XUiKotodamaActivityBattleRoomProxy:GetRoleDetailProxy()
    return require('XUi/XUiKotodamaActivity/XUiKotodamaActivityBattleRoomDetailProxy')
end

return XUiKotodamaActivityBattleRoomProxy