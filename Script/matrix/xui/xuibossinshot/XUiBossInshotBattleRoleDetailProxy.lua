local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiBossInshotBattleRoleDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy,"XUiBossInshotBattleRoleDetailProxy")

function XUiBossInshotBattleRoleDetailProxy:AOPOnStartAfter(rootUi)
    self.RootUi = rootUi
end

function XUiBossInshotBattleRoleDetailProxy:GetEntities()
    local agency = XMVCA:GetAgency(ModuleId.XBossInshot)
    return agency:GetActivityBattleRoleRoomEntities()
end

function XUiBossInshotBattleRoleDetailProxy:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("PanelBossInshotCharacterDetail"),
            proxy = require("XUi/XUiBossInshot/XUiPanelBossInshotCharacterDetail"),
            proxyArgs = { "Team", "StageId", self.RootUi }
        }
    end
    return self.ChildPanelData
end

-- 是否屏蔽效应筛选
function XUiBossInshotBattleRoleDetailProxy:IsHideGeneralSkill()
    return true
end

return XUiBossInshotBattleRoleDetailProxy