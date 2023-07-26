local XUiAreaWarBoss = require("XUi/XUiAreaWar/XUiAreaWarBoss")

local XUiAreaWarBossSpecial = XLuaUiManager.Register(XUiAreaWarBoss, "UiAreaWarBossSpecial")

function XUiAreaWarBossSpecial:OnAwake()
    self.UiType = XAreaWarConfigs.WorldBossUiType.Special
end
