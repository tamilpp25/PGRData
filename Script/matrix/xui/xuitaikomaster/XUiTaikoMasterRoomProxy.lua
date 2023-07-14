local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiTaikoMasterRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTaikoMasterRoomProxy")

function XUiTaikoMasterRoomProxy:Ctor(team, stageId)
    self.StageId = stageId
end

function XUiTaikoMasterRoomProxy:GetRoleDetailProxy()
    return require("XUi/XUiTaikoMaster/XUiTaikoMasterRoomDetailProxy")
end

function XUiTaikoMasterRoomProxy:AOPOnStartAfter(rootUi)
    rootUi.BtnChar2.gameObject:SetActiveEx(false)
    rootUi.BtnChar3.gameObject:SetActiveEx(false)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    rootUi.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    rootUi.PanelTeamLeader.gameObject:SetActiveEx(false)
    rootUi.UiObjPartner1.gameObject:SetActiveEx(false)
    rootUi.PanelSkill.gameObject:SetActiveEx(false)
    
    local uiModelRoot = rootUi.UiModelGo.transform
    uiModelRoot:FindTransform("PanelRoleEffect" .. 2).gameObject:SetActiveEx(false)
    uiModelRoot:FindTransform("PanelRoleEffect" .. 3).gameObject:SetActiveEx(false)
end

function XUiTaikoMasterRoomProxy:AOPOnRefreshPartnersBefore()
    return true
end

function XUiTaikoMasterRoomProxy:CheckStageRobotIsUseCustomProxy(robotIds)
    return true
end

function XUiTaikoMasterRoomProxy:CheckIsCanDrag()
    return false
end

return XUiTaikoMasterRoomProxy