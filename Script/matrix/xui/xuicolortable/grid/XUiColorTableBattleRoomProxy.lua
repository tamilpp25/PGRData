local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiColorTableBattleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "UiColorTableBattleRoomProxy")
local MaxCharCnt = 3

--######################## AOP ########################

function XUiColorTableBattleRoomProxy:AOPRefreshRoleInfosAfter(rootUi)
    local team = rootUi.Team

    local entityIds = team:GetEntityIds()
    for i = 1, MaxCharCnt do
        -- 处理相同characterId的robot
        local characterId = XEntityHelper.GetCharacterIdByEntityId(entityIds[i])
        
        local isCaptain = XDataCenter.ColorTableManager.IsCaptainRole(characterId)
        rootUi["PanelGuildwarSupport"..i].gameObject:SetActiveEx(isCaptain)
        
        local isSpecialAtk = XDataCenter.ColorTableManager.IsSpecialRole(characterId)
        rootUi["PanelGuildwarUP"..i].gameObject:SetActiveEx(isSpecialAtk)
        rootUi["PanelColorTableTips"..i].gameObject:SetActiveEx(isCaptain or isSpecialAtk)
    end
end

-- 这里打开调色板战争的角色列表界面(不走XUiBattleRoomRoleDetail)
function XUiColorTableBattleRoomProxy:AOPOnCharacterClickBefore(rootUi, index)
    XLuaUiManager.Open("UiColorTableCharacter", rootUi.Team, index, rootUi.StageId)
    return true
end

-- 进入战斗
function XUiColorTableBattleRoomProxy:EnterFight(team, stageId, challengeCount, isAssist)
    XDataCenter.ColorTableManager.EnterFight(team, stageId)
end

return XUiColorTableBattleRoomProxy