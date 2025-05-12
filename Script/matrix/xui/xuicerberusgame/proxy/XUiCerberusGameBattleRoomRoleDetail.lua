local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiCerberusGameBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiCerberusGameBattleRoomRoleDetail")

function XUiCerberusGameBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnStartAfter(rootUi)
    rootUi.BtnGroupCharacterType.gameObject:SetActiveEx(false)
    rootUi.BtnFilter.gameObject:SetActiveEx(false)
end

-- 检测storyPoint的禁用角色
function XUiBattleRoomRoleDetailDefaultProxy:AOPOnBtnJoinTeamClickedBefore(rootUi)

end

-- 禁用角色选中时要禁用按钮
function XUiCerberusGameBattleRoomRoleDetail:AOPSetJoinBtnIsActiveAfter(rootUi)
end

function XUiCerberusGameBattleRoomRoleDetail:AOPOnDynamicTableEventAfter(rootUi, event, index, grid)
end

-- 
function XUiCerberusGameBattleRoomRoleDetail:GetEntities()
    local roleList = {}
    local xConfig = XMVCA.XCerberusGame:CheckIsChallengeStage(self.StageId)
    if xConfig then
        -- 如果是挑战模式
        roleList = XMVCA.XCerberusGame:GetCanSelectRoleListForChallengeMode(self.StageId)
    else
        -- 如果是剧情模式
        roleList = XMVCA.XCerberusGame:GetCanSelectRoleListForStoryMode()
    end

    table.sort(roleList, function (a, b)
        return a.Ability > b.Ability
    end)
    return roleList
end

function XUiCerberusGameBattleRoomRoleDetail:SortEntitiesWithTeam(xTeam, roles)
    return roles
end

return XUiCerberusGameBattleRoomRoleDetail