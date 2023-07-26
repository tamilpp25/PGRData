--######################## XUiBabelTowerRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiBabelTowerRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiBabelTowerRoleGrid")

function XUiBabelTowerRoleGrid:SetData(entity, team, stageId)
    self.Super.SetData(self, entity)
    local isLock = XDataCenter.FubenBabelTowerManager.IsCharacterLockByStageId(entity:GetId(),stageId, team:GetId())
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end

--######################## XUiBabelTowerBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiBabelTowerBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiBabelTowerBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy,"XUiBabelTowerBattleRoomRoleDetail")

-- team : XTeam
function XUiBabelTowerBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
end

-- 获取左边角色格子代理，默认为XUiBattleRoomRoleGrid
-- 如果只是做一些简单的显示，比如等级读取自定义，可以直接使用AOPOnDynamicTableEventAfter接口去处理也可以
-- return : 继承自XUiBattleRoomRoleGrid的类
function XUiBabelTowerBattleRoomRoleDetail:GetGridProxy()
    return XUiBabelTowerRoleGrid
end

-- return : bool 是否开启自动关闭检查, number 自动关闭的时间戳(秒), function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiBabelTowerBattleRoomRoleDetail:GetAutoCloseInfo()
    local activityType = XDataCenter.FubenBabelTowerManager.GetActivityTypeByStageId(self.StageId)
    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(activityType)
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(activityType)
        end
    end
end

function XUiBabelTowerBattleRoomRoleDetail:GetEntities(characterType)
    local roles = XDataCenter.CharacterManager.GetOwnCharacterList(characterType)
    local babelTowerStageCfg = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(self.StageId)
    local robotIds = babelTowerStageCfg.RobotIds or {}
    -- 添加机器人
    if not XTool.IsTableEmpty(robotIds) then
        for _, robotId in pairs(robotIds) do
            local type = self:GetCharacterType(robotId)
            --if type == characterType then
            local entity = XRobotManager.GetRobotById(robotId)
            if entity then
                table.insert(roles, entity)
            end
            --end
        end
    end
    return roles
end

--######################## AOP ########################

function XUiBabelTowerBattleRoomRoleDetail:AOPSetJoinBtnIsActiveAfter(rootUi)
    local isInTeam = rootUi.Team:GetEntityIdIsInTeam(rootUi.CurrentEntityId)
    local oldMemberId = rootUi.Team:GetEntityIdByTeamPos(rootUi.Pos)
    local isJoin = not (XTool.IsNumberValid(oldMemberId) and isInTeam and oldMemberId == rootUi.CurrentEntityId)
    local isLock = XDataCenter.FubenBabelTowerManager.IsCharacterLockByStageId(rootUi.CurrentEntityId, rootUi.StageId, rootUi.Team:GetId())

    rootUi.BtnLock.gameObject:SetActiveEx(isLock)
    rootUi.BtnJoinTeam.gameObject:SetActiveEx(isJoin and not isLock)
    rootUi.BtnQuitTeam.gameObject:SetActiveEx(not isJoin and not isLock)
end

function XUiBabelTowerBattleRoomRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiBabelTowerBase"]
end

return XUiBabelTowerBattleRoomRoleDetail