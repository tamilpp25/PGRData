local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiShortStoryBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiShortStoryBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiShortStoryBattleRoomRoleDetail")

---@param team XTeam
function XUiShortStoryBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiShortStoryBattleRoomRoleDetail:GetEntities(characterType)
    local roles = {}
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local haveHideAction = stageCfg.HideAction == 1 and #stageCfg.RobotId > 0
    if haveHideAction then
        roles = self:GetShortStoryRoles(characterType)
    else
        roles = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    end
    return roles
end

function XUiShortStoryBattleRoomRoleDetail:GetShortStoryRoles(characterType)
    local roles = {}
    local entityIds = self.Team:GetEntityIds()
    for _, entityId in pairs(entityIds) do
        local entity = self:GetEntityByEntityId(entityId)
        if entity then
            table.insert(roles, entity)
        end
    end
    return roles
end

function XUiShortStoryBattleRoomRoleDetail:GetEntityByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            entity = XMVCA.XCharacter:GetCharacter(id)
        end
        if entity == nil then
            XLog.Error(string.format("找不到id%s的角色", id))
            return nil
        end
        return entity
    end
    return nil
end

function XUiShortStoryBattleRoomRoleDetail:AOPOnStartAfter(rootUi)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local haveHideAction = stageCfg.HideAction == 1 and #stageCfg.RobotId > 0
    rootUi.BtnFilter.gameObject:SetActiveEx(not XUiManager.IsHideFunc and not haveHideAction)
end

function XUiShortStoryBattleRoomRoleDetail:AOPSetJoinBtnIsActiveAfter(rootUi)
    local canJoin = not self.Team:GetEntityIdIsInTeam(rootUi.CurrentEntityId)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local haveHideAction = stageCfg.HideAction == 1 and #stageCfg.RobotId > 0

    rootUi.BtnJoinTeam.gameObject:SetActiveEx(canJoin and not haveHideAction)
    rootUi.BtnQuitTeam.gameObject:SetActiveEx(not canJoin and not haveHideAction)
    rootUi.BtnLock.gameObject:SetActiveEx(haveHideAction)
end

function XUiShortStoryBattleRoomRoleDetail:AOPRefreshOperationBtnsBefore(rootUi)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local haveHideAction = stageCfg.HideAction == 1 and #stageCfg.RobotId > 0

    local isRobot = self:CheckIsRobot(rootUi.CurrentEntityId)

    rootUi.BtnPartner.gameObject:SetActiveEx(not (haveHideAction and isRobot))
    rootUi.BtnFashion.gameObject:SetActiveEx(not (haveHideAction and isRobot))
    rootUi.BtnConsciousness.gameObject:SetActiveEx(not (haveHideAction and isRobot))
    rootUi.BtnWeapon.gameObject:SetActiveEx(not (haveHideAction and isRobot))

    return haveHideAction and isRobot
end

function XUiShortStoryBattleRoomRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiFubenMainLineChapterDP"]
end

return XUiShortStoryBattleRoomRoleDetail