local XGridTheatre3EventOption = require("XUi/XUiTheatre3/Adventure/Node/XGridTheatre3EventOption")

---@class XPanelTheatre3EventOptions : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Outpost
local XPanelTheatre3EventOptions = XClass(XUiNode, "XPanelTheatre3EventOptions")

function XPanelTheatre3EventOptions:OnStart()
    ---@type XGridTheatre3EventOption[]
    self._OptionObjList = {}
    self:AddBtnListener()
end

function XPanelTheatre3EventOptions:OnEnable()

end

function XPanelTheatre3EventOptions:OnDisable()

end

---@param eventCfg XTableTheatre3Event
---@param slot XTheatre3NodeSlot
function XPanelTheatre3EventOptions:Refresh(eventCfg, slot)
    self._SelectOptionIndex = 0
    ---@type XTableTheatre3Event
    self._EventCfg = eventCfg
    self._NodeSlot = slot
    XUiHelper.SetText2LineBreak(self.TxtDesc, self._EventCfg.EventDesc)
    self.BtnOK:SetNameByGroup(0, self._EventCfg.ConfirmContent)
    self:_RefreshOption()
    self:_RefreshOptionSelect()
end

function XPanelTheatre3EventOptions:_RefreshOption()
    local optionGroupId = self._EventCfg.OptionGroupId
    self._OptionIdList = self._Control:GetEventOptionIdListByGroup(optionGroupId)
    if XTool.IsTableEmpty(self._OptionIdList) then
        return
    end
    for i, optionId in ipairs(self._OptionIdList) do
        local optionCfg = self._Control:GetEventOptionCfgById(optionId)
        local isShow = not XTool.IsNumberValid(optionCfg.OptionShowCondition) or XConditionManager.CheckCondition(optionCfg.OptionShowCondition)
        if not self._OptionObjList[i] then
            local go = i == 1 and self.BtnOption or XUiHelper.Instantiate(self.BtnOption.gameObject, self.BtnOption.transform.parent)
            local grid = XGridTheatre3EventOption.New(go, self, handler(self, self.SelectOption))
            self._OptionObjList[i] = grid
        end
        if isShow then
            self._OptionObjList[i]:Open()
            self._OptionObjList[i]:Refresh(optionId, i)
        else
            self._OptionObjList[i]:Close()
        end
    end
end

--region Ui - SelectOption
function XPanelTheatre3EventOptions:_RefreshOptionSelect()
    for i, optionObj in ipairs(self._OptionObjList) do
        optionObj:SetOptionSelect(i == self._SelectOptionIndex)
    end
end

function XPanelTheatre3EventOptions:SelectOption(optionIndex)
    if not (self._SelectOptionIndex == optionIndex) then
        self._SelectOptionIndex = optionIndex
    end
    self:_RefreshOptionSelect()
end
--endregion

--region Ui - BtnListener
function XPanelTheatre3EventOptions:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnConfirmClick)
end

function XPanelTheatre3EventOptions:OnBtnConfirmClick()
    if self._IsSelect then
        return
    end
    if not XTool.IsNumberValid(self._SelectOptionIndex) then
        XUiManager.TipErrorWithKey("Theatre3AdventureOptionSelectTip")
        return
    end
    local lastStep = self._Control:GetAdventureLastStep()
    self._Control:RequestAdventureEventNodeNextStep(self._EventCfg.StepId, self._SelectOptionIndex, function(isHaveNext)
        -- 新增下一步
        if lastStep ~= self._Control:GetAdventureLastStep() then
            self._Control:CheckAndOpenAdventureNextStep(true, true)
            return
        end
        if isHaveNext then
            self._Control:CheckAndOpenAdventureNodeSlot(self._NodeSlot ,true)
        else
            self.Parent:OnBtnBackClick()
        end
    end)
end
--endregion

return XPanelTheatre3EventOptions