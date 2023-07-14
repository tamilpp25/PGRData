local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiPanelBabelTowerRoom = require("XUi/XUiFubenBabelTower/Room/XUiPanelBabelTowerRoom")
local XUiBabelTowerBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiBabelTowerBattleRoleRoom")

function XUiBabelTowerBattleRoleRoom:Ctor(team, stageId)
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

--######################## AOP ########################
function XUiBabelTowerBattleRoleRoom:AOPOnStartBefore(rootUi)
    self.RootUi = rootUi
end

function XUiBabelTowerBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    rootUi.BtnEnterFight:SetNameByGroup(0, CSXTextManagerGetText("BabelTowerNewRoomBtnName"))
end

return XUiBabelTowerBattleRoleRoom