local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiRpgTowerBattleRoomExpand = require("XUi/XUiRpgTower/Battle/BattleRoom/XUiRpgTowerBattleRoomExpand")
local XUiRpgTowerBattleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiRpgTowerBattleRoom")

function XUiRpgTowerBattleRoom:Ctor()
    self.Manager = XDataCenter.RpgTowerManager
end

function XUiRpgTowerBattleRoom:GetCharacterViewModelByEntityId(id)
    if (not id) or id == 0 then return nil end 
    local role = XRobotManager.GetRobotById(id)
    if not role then return nil end
    return role:GetCharacterViewModel()
end

function XUiRpgTowerBattleRoom:GetRoleAbility(entityId)
    local role = self.Manager.GetTeamMemberByCharacterId(XRobotManager.GetCharacterId(entityId))
    if role == nil then return 0 end
    return role:GetAbility()
end

function XUiRpgTowerBattleRoom:GetCharacterIdByEntityId(entityId)
    return XRobotManager.GetCharacterId(entityId)
end

function XUiRpgTowerBattleRoom:GetPartnerByEntityId(id)
    if (not id) or id == 0 then return nil end
    local role = XRobotManager.GetRobotById(id)
    if not role then return nil end
    return role:GetPartner()
end

function XUiRpgTowerBattleRoom:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("RpgTowerBattleRoleRoom"),
            proxy = XUiRpgTowerBattleRoomExpand,
            proxyArgs = { "Team" }
        }
    end
    return self.ChildPanelData
end

function XUiRpgTowerBattleRoom:GetRoleDetailProxy()
    return require("XUi/XUiRpgTower/Battle/BattleRoom/XUiRpgTowerBattleRoomRoleDetail")
end

function XUiRpgTowerBattleRoom:GetAutoCloseInfo()
    return true, XDataCenter.RpgTowerManager.GetEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
        end
    end
end

--######################## AOP ########################

function XUiRpgTowerBattleRoom:AOPOnStartBefore(rootUi)

end

function XUiRpgTowerBattleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiRpgTowerBattleRoom:AOPOnEnableAfter(rootUi)
    -- 覆盖掉父类，不处理
end

function XUiRpgTowerBattleRoom:AOPRefreshFightControlStateBefore(rootUi)
    if rootUi.FightControl == nil then
        rootUi.FightControl = XUiNewRoomFightControl.New(rootUi.FightControlGo)
    end
    local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(rootUi.StageId)
    rootUi.FightControlResult = rootUi.FightControl:UpdateByTextAndWarningLevel(
        rStage:GetStageWarningType(),
        CS.XTextManager.GetText("RpgTowerWarningControlName"),
        rStage:GetRecommendLevel(),
        CS.XTextManager.GetText("RpgTowerCurNumText", XDataCenter.RpgTowerManager.GetCurrentLevel())
    )
    return true
end

function XUiRpgTowerBattleRoom:AOPOnCharacterClickBefore(rootUi, index)
    RunAsyn(function()
            local oldEntityId = rootUi.Team:GetEntityIdByTeamPos(index)
            XLuaUiManager.Open("UiRpgTowerRoomCharacter"
                , rootUi.Team
                , index)
            local signalCode, newEntityId = XLuaUiManager.AwaitSignal("UiRpgTowerRoomCharacter", "UpdateEntityId", self)
            if signalCode ~= XSignalCode.SUCCESS then return end
            if oldEntityId == newEntityId then return end
            if rootUi.Team:GetEntityIdByTeamPos(index) <= 0 then return end
            -- 播放音效
            local soundType = XEnumConst.Favorability.SoundEventType.MemberJoinTeam
            if rootUi.Team:GetCaptainPos() == index then
                soundType = XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
            end
        XMVCA.XFavorability:PlayCvByType(self:GetCharacterIdByEntityId(newEntityId)
                , soundType)
        end)
    return true
end

function XUiRpgTowerBattleRoom:AOPOnRefreshPartnersBefore(rootUi)
    local uiObjPartner
    for pos = 1, XEntityHelper.TEAM_MAX_ROLE_COUNT do
        uiObjPartner = rootUi["UiObjPartner" .. pos]
        uiObjPartner.gameObject:SetActiveEx(false)
    end
    return true
end

return XUiRpgTowerBattleRoom