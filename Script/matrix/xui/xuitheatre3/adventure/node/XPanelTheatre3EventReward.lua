---@class XGridTheatre3EventReward
---@field Image UnityEngine.UI.Image
---@field ImageRed UnityEngine.UI.Image
---@field Grid256New UnityEngine.UI.Text

local XUiGridTheatre3Item = require("XUi/XUiTheatre3/Tips/XUiGridTheatre3Item")

---@class XPanelTheatre3EventReward : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Outpost
local XPanelTheatre3EventReward = XClass(XUiNode, "XPanelTheatre3EventReward")

function XPanelTheatre3EventReward:OnStart()
    ---@type XUiGridTheatre3Item[]
    self._GridRewardList = {}
    ---@type XGridTheatre3EventReward[]
    self._GridRewardObj = {}
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
        if not self._GridRewardList[i] then
            local go = XUiHelper.Instantiate(self.PanelReward, self.PanelReward.transform.parent)
            self._GridRewardObj[i] = XTool.InitUiObjectByUi({}, go)
            self._GridRewardList[i] = XUiGridTheatre3Item.New(go.transform:Find("Grid256New"), self)
        end
        if self._GridRewardObj[i].Image and eventCfg.StepRewardItemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
            local bgType = self._Control:GetItemBgTypeById(itemId)
            self._GridRewardObj[i].Image.gameObject:SetActiveEx(bgType ~= XEnumConst.THEATRE3.QuantumType.QuantumB)
            self._GridRewardObj[i].ImageRed.gameObject:SetActiveEx(bgType == XEnumConst.THEATRE3.QuantumType.QuantumB)
        end
        self._GridRewardList[i]:Open()
        self._GridRewardList[i]:Refresh(itemId, eventCfg.StepRewardItemType, eventCfg.StepRewardItemCount[i])
        self._GridRewardList[i]:RefreshCount(eventCfg.StepRewardItemCount[i])
    end
    self.PanelReward.gameObject:SetActiveEx(false)
end

---@param type 
---@param rewardId 
function XPanelTheatre3EventReward:RefreshOnlyDialogue(content, confirmText, type, rewardId)
    self._IsOnlyDialogue = true
    XUiHelper.SetText2LineBreak(self.TxtContent, content)
    if not string.IsNilOrEmpty(confirmText) then
        self.BtnOK:SetNameByGroup(0, confirmText)
    end

    if not XTool.IsNumberValid(rewardId) then
        self.PanelReward.gameObject:SetActiveEx(false)
        return
    end
    
    if not self._ShopRewardGrid then
        local go = XUiHelper.Instantiate(self.PanelReward, self.PanelReward.transform.parent)
        ---@type XUiGridTheatre3Item
        self._ShopRewardGrid = XUiGridTheatre3Item.New(go.transform:Find("Grid256New"), self)
    end
    self._ShopRewardGrid:Open()
    self._ShopRewardGrid:Refresh(rewardId, type)
    self._ShopRewardGrid:RefreshCount()
    self.PanelReward.gameObject:SetActiveEx(false)
end

--region Ui - BtnListener
function XPanelTheatre3EventReward:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnOK, self.OnBtnConfirmClick)
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