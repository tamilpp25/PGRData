local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiMultiDimSingleCopyRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiMultiDimSingleCopyRoleRoom")
-- 多维挑战 单人副本

local MaxCharacterCount = 1
function XUiMultiDimSingleCopyRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiMultiDimSingleCopyRoleRoom:CheckIsCanDrag()
    return false
end

-- 检查是否能战斗，单人挑战副本只能上阵1人
function XUiMultiDimSingleCopyRoleRoom:GetIsCanEnterFight()
    local curTeamMemberCount = 0
    if not self.Team then return end
    for _, charId in ipairs(self.Team.EntitiyIds) do
        if charId > 0 then
            curTeamMemberCount = curTeamMemberCount + 1
        end
    end

    if curTeamMemberCount > MaxCharacterCount then
        local text = XUiHelper.GetText("TeamNeedCount", MaxCharacterCount)
        XUiManager.TipMsg(text)
        return false
    end

    return true
end

function XUiMultiDimSingleCopyRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActive(false)
    rootUi.PanelFirstInfo.gameObject:SetActive(false)
    rootUi.BtnChar2.gameObject:SetActive(false)
    rootUi.BtnChar3.gameObject:SetActive(false)
end

return XUiMultiDimSingleCopyRoleRoom