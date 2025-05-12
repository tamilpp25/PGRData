local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiPanelBabelTowerRoom = require("XUi/XUiFubenBabelTower/Room/XUiPanelBabelTowerRoom")
---@class XUiBabelTowerBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiBabelTowerBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiBabelTowerBattleRoleRoom")

---@param team XTeam
function XUiBabelTowerBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiBabelTowerBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiFubenBabelTower/Room/XUiBabelTowerBattleRoomRoleDetail")
end

function XUiBabelTowerBattleRoleRoom:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelBabel"),
        proxy = XUiPanelBabelTowerRoom,
        proxyArgs = { "StageId", "Team" }
    }
end

function XUiBabelTowerBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    self.RootUi:Close()
end

-- return : bool 是否开启自动关闭检查, number 自动关闭的时间戳(秒), function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiBabelTowerBattleRoleRoom:GetAutoCloseInfo()
    local activityType = XDataCenter.FubenBabelTowerManager.GetActivityTypeByStageId(self.StageId)
    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(activityType)
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(activityType)
        end
    end
end

-- 过滤预设队伍实体Id
-- teamData : 旧系统的队伍数据
-- 注意：不能直接使用XTool.Clone克隆teamData数据，会出现无线套娃的现象 
-- 主要原因是teamData里有PartnerPrefab，PartnerPrefab里又有teamData
function XUiBabelTowerBattleRoleRoom:FilterPresetTeamEntitiyIds(teamData)
    -- 根据巴别塔锁角色机制处理
    local tempTeamData = {}
    local entitiyIds = {}
    local isTip = false
    for pos, characterId in ipairs(teamData.TeamData) do
        local isLock = XDataCenter.FubenBabelTowerManager.IsCharacterLockByStageId(characterId, self.StageId, self.Team:GetId())
        entitiyIds[pos] = not isLock and characterId or 0
        if isLock then
            isTip = true
        end
    end
    tempTeamData.TeamData = entitiyIds
    tempTeamData.CaptainPos = teamData.CaptainPos
    tempTeamData.FirstFightPos = teamData.FirstFightPos
    tempTeamData.TeamName = teamData.TeamName
    if isTip then
        XUiManager.TipText("BabelTowerPresetTeamEntitiyIdLockTip")
    end
    return tempTeamData
end

--######################## AOP ########################
function XUiBabelTowerBattleRoleRoom:AOPOnStartBefore(rootUi)
    self.RootUi = rootUi
end

function XUiBabelTowerBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnEnterFight:SetNameByGroup(0, CSXTextManagerGetText("BabelTowerNewRoomBtnName"))
end

-- 检查是否开启效应选择
function XUiBabelTowerBattleRoleRoom:CheckIsEnableGeneralSkillSelection()
    return false
end

-- 检查是否开启自选动画
function XUiBabelTowerBattleRoleRoom:CheckShowAnimationSet()
    return false
end

return XUiBabelTowerBattleRoleRoom