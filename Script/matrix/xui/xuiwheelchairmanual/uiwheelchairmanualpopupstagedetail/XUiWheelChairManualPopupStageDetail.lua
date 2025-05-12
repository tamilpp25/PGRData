---@class XUiWheelChairManualPopupStageDetail: XLuaUi
---@field _Control XWheelchairManualControl
local XUiWheelChairManualPopupStageDetail = XLuaUiManager.Register(XLuaUi, 'UiWheelChairManualPopupStageDetail')

function XUiWheelChairManualPopupStageDetail:OnAwake()
    self.BtnCancel.CallBack = handler(self, self.Close)
    self.BtnStart.CallBack = handler(self, self.OnBeginFightClickEvent)
end

function XUiWheelChairManualPopupStageDetail:OnStart(stageId)
    self._StageId = stageId
    self.TxtTitle.text = XMVCA.XFuben:GetStageName(self._StageId, true)
    self.TxtTips.text = XMVCA.XFuben:GetStageDescription(self._StageId, true)
    
    ---@type XTableStage
    local stageCfg = XMVCA.XFuben:GetStageCfg(self._StageId)

    if stageCfg then
        XUiHelper.RefreshCustomizedList(self.Head.transform.parent, self.Head, stageCfg.RobotId and #stageCfg.RobotId or 0, function(index, go)
            local icon = XRobotManager.GetRobotSmallHeadIcon(stageCfg.RobotId[index])
            local uiObj = go:GetComponent("UiObject")
            uiObj:GetObject("StandIcon"):SetSprite(icon)
            uiObj.gameObject:SetActiveEx(true)
        end)
    else
        self.Head.gameObject:SetActiveEx(false)
    end
end


function XUiWheelChairManualPopupStageDetail:OnBeginFightClickEvent()
    local stageCfg = XMVCA.XFuben:GetStageCfg(self._StageId)
    local team = XDataCenter.TeamManager.GetXTeamByStageId(self._StageId)
    if #stageCfg.RobotId > 0 then
        local entityIds = {}
        for _, robotId in pairs(stageCfg.RobotId) do
            table.insert(entityIds, robotId)
        end
        team:UpdateEntityIds(entityIds)
        team:AutoSelectGeneralSkill(XMVCA.XFuben:GetGeneralSkillIds(self._StageId))
        XMVCA.XFuben:EnterFightByStageId(self._StageId, team:GetId())
    end

    self:Close()

end

return XUiWheelChairManualPopupStageDetail