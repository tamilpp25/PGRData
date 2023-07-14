---@class XPanelTheatre3EventDialogue : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Outpost
local XPanelTheatre3EventDialogue = XClass(XUiNode, "XPanelTheatre3EventDialogue")

function XPanelTheatre3EventDialogue:OnStart()
    self:AddBtnListener()
end

---@param eventCfg XTableTheatre3Event
---@param slot XTheatre3NodeSlot
function XPanelTheatre3EventDialogue:Refresh(eventCfg, slot)
    self._EventCfg = eventCfg
    self._NodeSlot = slot
    self.TxtContent.text = eventCfg.EventDesc
    if not string.IsNilOrEmpty(eventCfg.ConfirmContent) then
        self.BtnOK:SetNameByGroup(0, eventCfg.ConfirmContent)
    end
end

function XPanelTheatre3EventDialogue:RefreshOnlyDialogue(content, confirmText)
    self._IsOnlyDialogue = true
    self.TxtContent.text = content
    if not string.IsNilOrEmpty(confirmText) then
        self.BtnOK:SetNameByGroup(0, confirmText)
    end
end

--region Ui - BtnListener
function XPanelTheatre3EventDialogue:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnConfirmClick)
end

function XPanelTheatre3EventDialogue:OnBtnConfirmClick()
    if self._IsOnlyDialogue then
        self.Parent:OnBtnBackClick()
        return
    end
    --EventStep
    local curStepId = self._NodeSlot:GetCurStepId()
    local lastStep = self._Control:GetAdventureLastStep()
    self._Control:RequestAdventureEventNodeNextStep(self._EventCfg.StepId, self._SelectOptionIndex, function(isHaveNext)
        -- 新增下一步
        if lastStep ~= self._Control:GetAdventureLastStep() then
            self._Control:CheckAndOpenAdventureNextStep(true, true)
            return
        end
        if isHaveNext then
            --没有Next EventStep则Next Step
            if curStepId == self._NodeSlot:GetCurStepId() then
                self._Control:CheckAndOpenAdventureNextStep(true, true)
            else
                self._Control:CheckAndOpenAdventureNodeSlot(self._NodeSlot ,true)
            end
        else
            self.Parent:OnBtnBackClick()
        end
    end)
end
--endregion

return XPanelTheatre3EventDialogue