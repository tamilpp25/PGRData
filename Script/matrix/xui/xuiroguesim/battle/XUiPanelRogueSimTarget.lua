---@class XUiPanelRogueSimTarget : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimTarget = XClass(XUiNode, "XUiPanelRogueSimTarget")

function XUiPanelRogueSimTarget:OnStart()
    self.BtnHide = self.Transform:FindTransform("BtnHide")
    self.StageId = self._Control:GetCurStageId()
    self:RegisterUiEvents()
end

function XUiPanelRogueSimTarget:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP,
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
        XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID,
        XEventId.EVENT_ROGUE_SIM_STATISTICS_CHANGE,
        XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE,
    }
end

function XUiPanelRogueSimTarget:OnNotify(event, ...)
    self:Refresh()
end

function XUiPanelRogueSimTarget:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnBgClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHide, self.OnBtnHideClick)
end

function XUiPanelRogueSimTarget:OnBtnBgClick()
    self.Parent:OpenTargetDetail()
end

function XUiPanelRogueSimTarget:OnBtnHideClick()
    if self.IsHide then
        self.IsHide = false
        self.Parent:PlayAnimation("TargetEnable")
    else
        self.IsHide = true
        self.Parent:PlayAnimation("TargetDisable")
    end
end

function XUiPanelRogueSimTarget:Refresh()
    self.Star1.gameObject:SetActiveEx(false)
    self.Star2.gameObject:SetActiveEx(false)
    self.Star3.gameObject:SetActiveEx(false)

    local isRefreshDetail = false
    local conditionIds = self._Control:GetRogueSimStageStarConditions(self.StageId)
    local descs = self._Control:GetRogueSimStageStarDescs(self.StageId)
    for i, conditionId in ipairs(conditionIds) do
        local isPass, desc, curValue, targetValue = self._Control.ConditionSubControl:CheckCondition(conditionId) -- 当局内是否通过
        self["Star"..i].gameObject:SetActiveEx(true)
        self["StarYes"..i].gameObject:SetActiveEx(isPass)
        self["StarNo"..i].gameObject:SetActiveEx(not isPass)
        if not isPass and not isRefreshDetail then
            isRefreshDetail = true
            self.TextTargetDesc.text = descs[i]
            local isShowSchedule = curValue and targetValue
            self.TextCurNum.gameObject:SetActiveEx(isShowSchedule)
            if isShowSchedule then
                self.TextCurNum.text = tostring(curValue)
                self.TextTargetNum.text = "/"..tostring(targetValue)
            end
        end
    end

    if not isRefreshDetail then
        self.TextTargetDesc.text = self._Control:GetClientConfig("AllTargetCompleteTips")
        self.TextCurNum.gameObject:SetActiveEx(false)
    end
end

return XUiPanelRogueSimTarget
