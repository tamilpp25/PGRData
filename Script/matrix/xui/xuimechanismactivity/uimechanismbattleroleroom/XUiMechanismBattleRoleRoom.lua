local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiMechanismBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, 'XUiMechanismBattleRoleRoom')

local XUiPanelMechanismBattleRoleRoomBuff = require('XUi/XUiMechanismActivity/UiMechanismBattleRoleRoom/XUiPanelMechanismBattleRoleRoomBuff')

function XUiMechanismBattleRoleRoom:AOPOnStartAfter(rootUi)
    if rootUi.BtnTeamPrefab then
        rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    end
end

function XUiMechanismBattleRoleRoom:AOPOnEnableAfter(rootUi)
    if self._PanelBuffs == nil then
        self._PanelBuffs = {}
        for i = 1, 3 do
            if rootUi['PanelEffectPlayBuff'..i] then
                local grid = XUiPanelMechanismBattleRoleRoomBuff.New(rootUi['PanelEffectPlayBuff'..i], rootUi, i)
                self._PanelBuffs[i] = grid
                grid:Open()
            end
        end
    else
        for i, v in pairs(self._PanelBuffs) do
            v:Open()
            v:Refresh()
        end
    end
end

function XUiMechanismBattleRoleRoom:GetRoleDetailProxy()
    return require('XUi/XUiMechanismActivity/UiMechanismBattleRoleRoom/XUiMechanismBattleRoleRoomDetailProxy')
end

---@overload
-- 检查关卡机器人是否使用自定义代理，默认不使用传入的代理，使用回默认代理，可以走回统一界面，避免多系统代理冲突
-- return : bool
function XUiMechanismBattleRoleRoom:CheckStageRobotIsUseCustomProxy(robotIds)
    return true
end

return XUiMechanismBattleRoleRoom