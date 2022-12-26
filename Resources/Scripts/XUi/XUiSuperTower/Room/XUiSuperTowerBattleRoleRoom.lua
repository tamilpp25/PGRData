local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiSuperTowerBattleRoomExpand = require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoomExpand")
local XUiSuperTowerBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiSuperTowerBattleRoleRoom")

function XUiSuperTowerBattleRoleRoom:Ctor()
    self.SuperTowerRoleManager = XDataCenter.SuperTowerManager.GetRoleManager()
end

function XUiSuperTowerBattleRoleRoom:GetCharacterViewModelByEntityId(id)
    local role = self.SuperTowerRoleManager:GetRole(id)
    if not role then return nil end
    return role:GetCharacterViewModel()
end

function XUiSuperTowerBattleRoleRoom:GetRoleAbility(entityId)
    local role = self.SuperTowerRoleManager:GetRole(entityId)
    if role == nil then return 0 end
    return role:GetAbility()
end

function XUiSuperTowerBattleRoleRoom:GetPartnerByEntityId(id)
    local role = self.SuperTowerRoleManager:GetRole(id)
    if not role then return nil end
    return role:GetPartner()
end

function XUiSuperTowerBattleRoleRoom:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("UiSuperTowerBattleRoleRoom"),
            proxy = XUiSuperTowerBattleRoomExpand,
            proxyArgs = { "Team", "StageId" }
        }
    end
    return self.ChildPanelData
end

function XUiSuperTowerBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoomRoleDetail")
end

-- team : XTeam
-- stageId : number
function XUiSuperTowerBattleRoleRoom:EnterFight(team, stageId)
    if XDataCenter.SuperTowerManager.GetStageTypeByStageId(stageId) == XDataCenter.SuperTowerManager.StageType.LllimitedTower then
        XDataCenter.SuperTowerManager.EnterFight(stageId)
    else
        XDataCenter.SuperTowerManager.GetStageManager():ResetTempProgress()
        XDataCenter.SuperTowerManager.GetTeamManager():SetTargetFightTeam({team}, stageId, function()
                XDataCenter.SuperTowerManager.EnterFight(stageId)
            end)
    end
end

function XUiSuperTowerBattleRoleRoom:GetAutoCloseInfo()
    return true, XDataCenter.SuperTowerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.SuperTowerManager.HandleActivityEndTime()
        end
    end
end

--######################## AOP ########################

function XUiSuperTowerBattleRoleRoom:AOPOnStartBefore(rootUi)
    -- 清理插件槽数据
    local extra = rootUi.Team:GetExtraData()
    if extra then extra:Clear() end
    -- 显示黑背景
    rootUi.DarkBottom.gameObject:SetActiveEx(true)
    rootUi.ImgSkillLine.gameObject:SetActiveEx(false)
end

function XUiSuperTowerBattleRoleRoom:AOPOnStartAfter(rootUi)
    
end

return XUiSuperTowerBattleRoleRoom