local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiChildPanelReformHiddenModel = require("XUi/XUiFubenShortStory/BattleRole/XUiChildPanelReformHiddenModel")
local XUiShortStoryBattleRoomRoleDetail = require("XUi/XUiFubenShortStory/BattleRole/XUiShortStoryBattleRoomRoleDetail")
---@class XUiShortStoryBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiShortStoryBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiShortStoryBattleRoleRoom")

---@param team XTeam
function XUiShortStoryBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
    -- 默认打开为false
    XDataCenter.FubenManager.SetIsHideAction(false)
end

function XUiShortStoryBattleRoleRoom:CheckStageRobotIsUseCustomProxy(robotIds)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if stageCfg.HideAction == 1 then
        return true
    end
    return #robotIds <= 0
end

-- 关卡若是配置了固定机器人且非隐藏关卡为不可编辑
function XUiShortStoryBattleRoleRoom:CheckIsCanEditorTeam(stageId, showTip)
    if showTip == nil then
        showTip = true
    end
    local isHideAction = XDataCenter.FubenManager.GetIsHideAction()
    if #XDataCenter.FubenManager.GetStageCfg(stageId).RobotId > 0 and not isHideAction then
        if showTip then
            XUiManager.TipError(XUiHelper.GetText("NewRoomSingleCannotSetRobot"))
        end
        return false
    end
    return true
end

function XUiShortStoryBattleRoleRoom:CheckIsCanDrag(stageId)
    local isHideAction = XDataCenter.FubenManager.GetIsHideAction()
    if #XDataCenter.FubenManager.GetStageCfg(stageId).RobotId > 0 and isHideAction then
        return false
    end
    return true
end

function XUiShortStoryBattleRoleRoom:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelReformHiddenModel"),
        proxy = XUiChildPanelReformHiddenModel,
        proxyArgs = { "StageId", "Team", self.RootUi },
    }
end

function XUiShortStoryBattleRoleRoom:GetRoleDetailProxy()
    return XUiShortStoryBattleRoomRoleDetail
end

function XUiShortStoryBattleRoleRoom:AOPOnStartBefore(rootUi)
    self.RootUi = rootUi
end

function XUiShortStoryBattleRoleRoom:AOPOnEnableAfter(rootUi)
    -- OnEnable 时由于AOPRefreshRoleInfosAfter 在 RefreshRoleDetalInfo 前刷新导致被覆盖掉。 在OnEnable结算后再调用一次AOPRefreshRoleInfosAfter 方法
    self:AOPRefreshRoleInfosAfter(rootUi)
end

function XUiShortStoryBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if stageCfg.HideAction == 1 and #stageCfg.RobotId > 0 then
        return true
    end
    return false
end

function XUiShortStoryBattleRoleRoom:AOPRefreshRoleInfosAfter(rootUi)
    local isShow
    local entityId
    local characterViewModel
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local isHideAction = XDataCenter.FubenManager.GetIsHideAction()
    for pos = 1, 3 do
        entityId = self.Team:GetEntityIdByTeamPos(pos)
        isShow = not XEntityHelper.GetIsRobot(entityId)
        rootUi["CharacterInfo" .. pos].gameObject:SetActiveEx(isShow)
        if isShow then
            characterViewModel = self:GetCharacterViewModelByEntityId(entityId)
            if characterViewModel then
                local ability = self:GetRoleAbility(entityId)
                rootUi["TxtFight" .. pos].text = ability
                if isHideAction then
                    local isEnoughAbility = ability >= stageCfg.Ability
                    rootUi["TxtFight" .. pos].color = isEnoughAbility and XUiHelper.Hexcolor2Color("0F70BC") or XUiHelper.Hexcolor2Color("E12928")
                end
            else
                rootUi["CharacterInfo" .. pos].gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiShortStoryBattleRoleRoom