local XUiGridTheatre3Item = require("XUi/XUiTheatre3/Tips/XUiGridTheatre3Item")

---@class XPanelTheatre3EventReward : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3EventReward = XClass(XUiNode, "XPanelTheatre3EventReward")

function XPanelTheatre3EventReward:OnStart()
    ---@type XUiGridTheatre3Item[]
    self._GridRewardList = {}
    self:AddBtnListener()
end

---@param eventCfg XTableTheatre3Event
---@param slot XTheatre3NodeSlot
function XPanelTheatre3EventReward:Refresh(eventCfg, slot)
    self._EventCfg = eventCfg
    self._NodeSlot = slot
    XUiHelper.SetText2LineBreak(self.TxtContent, eventCfg.EventDesc)
    if not string.IsNilOrEmpty(eventCfg.ConfirmContent) then
        self.BtnOK:SetNameByGroup(0, eventCfg.ConfirmContent)
    end
    for i, itemId in ipairs(eventCfg.StepRewardItemId) do
        local grid = self._GridRewardList[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.PanelReward, self.PanelReward.transform.parent)
            grid = XUiGridTheatre3Item.New(go.transform:Find("Grid256New"), self)
            self._GridRewardList[i] = grid
        end
        grid:Open()
        grid:Refresh(itemId, eventCfg.StepRewardItemType, eventCfg.StepRewardItemCount[i])
        grid:RefreshCount(eventCfg.StepRewardItemCount[i])
    end
    self.PanelReward.gameObject:SetActiveEx(false)
end

--region Ui - BtnListener
function XPanelTheatre3EventReward:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnConfirmClick)
end

function XPanelTheatre3EventReward:OnBtnConfirmClick()
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

return XPanelTheatre3EventReward