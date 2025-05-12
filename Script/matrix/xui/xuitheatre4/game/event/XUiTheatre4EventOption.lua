local XUiTheatre4EventOptionGrid = require("XUi/XUiTheatre4/Game/Event/XUiTheatre4EventOptionGrid")
---@class XUiTheatre4EventOption : XUiNode
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4Event
local XUiTheatre4EventOption = XClass(XUiNode, "XUiTheatre4EventOption")

function XUiTheatre4EventOption:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
    self.BtnOptionParent.gameObject:SetActiveEx(false)
    self.BtnOption.gameObject:SetActiveEx(false)
    ---@type XUiTheatre4EventOptionGrid[]
    self.BtnOptionList = {}
    self.CurSelectOptionId = 0
    
    self.BtnSpecialOption = self.BtnSpecialOption or XUiHelper.TryGetComponent(self.Transform, "ListOption/BtnOption/BtnSpecialOption", "RectTransform")
end
 
function XUiTheatre4EventOption:Refresh(eventId)
    self.EventId = eventId
    -- 描述
    self.TxtContent.text = self._Control:GetEventDesc(eventId)
    -- 确认按钮文本
    local confirmContent = self._Control:GetEventConfirmContent(eventId)
    self.BtnSure:SetNameByGroup(0, confirmContent)
    -- 选项列表
    local optionIds = self._Control:GetEventOptionIds(eventId)
    if XTool.IsTableEmpty(optionIds) then
        return
    end
    local btnTab = {}
    for index, optionId in ipairs(optionIds) do
        local grid = self.BtnOptionList[index]
        if not grid then
            local ui = self.BtnOption
            local optionType = self._Control:GetEventOptionType(optionId)
            if optionType == XEnumConst.Theatre4.EventOptionType.DialogueSpecial then
                ui = self.BtnSpecialOption
            end
            local go = XUiHelper.Instantiate(ui, self.ListOption)
            grid = XUiTheatre4EventOptionGrid.New(go, self)
            self.BtnOptionList[index] = grid
        end
        grid:Open()
        grid:Refresh(optionId)
        btnTab[index] = grid.BtnOption
    end
    for i = #optionIds + 1, #self.BtnOptionList do
        self.BtnOptionList[i]:Close()
    end
    self.BtnOptionGroup:Init(btnTab, function(index) self:OnOptionClick(index) end)
    self.CurSelectOptionId = 0
    self:RefreshBtn()
    self:RefreshSelectState()
end

function XUiTheatre4EventOption:RefreshBtn()
    local isSelect = XTool.IsNumberValid(self.CurSelectOptionId)
    self.BtnSure:SetDisable(not isSelect)
end

function XUiTheatre4EventOption:OnOptionClick(index)
    local optionId = self.BtnOptionList[index]:GetOptionId()
    -- 选中的不变
    if self.CurSelectOptionId == optionId then
        return
    end
    -- 检查条件 和 检查道具
    if not self:CheckConditionEnough(optionId) or not self:CheckItemEnough(optionId) then
        self:RefreshSelectState()
        return
    end
    self.CurSelectOptionId = optionId
    self:RefreshBtn()
end

-- 刷新选择状态
function XUiTheatre4EventOption:RefreshSelectState()
    for _, grid in ipairs(self.BtnOptionList) do
        local btn = grid.BtnOption
        if grid:GetOptionId() == self.CurSelectOptionId then
            btn:SetButtonState(CS.UiButtonState.Select)
        else
            btn:SetButtonState(CS.UiButtonState.Normal)
        end
    end
end

-- 检查条件是否满足
function XUiTheatre4EventOption:CheckConditionEnough(optionId)
    local optionConditionId = self._Control:GetEventOptionCondition(optionId)
    local isCondition, desc = self._Control:CheckEventOptionCondition(optionConditionId)
    if not isCondition then
        self._Control:ShowRightTipPopup(desc)
        return false
    end
    return true
end

-- 检查道具是否满足
function XUiTheatre4EventOption:CheckItemEnough(optionId)
    local optionType = self._Control:GetEventOptionType(optionId)
    if optionType == XEnumConst.Theatre4.EventOptionType.CostItem or optionType == XEnumConst.Theatre4.EventOptionType.CheckItem then
        return self:CheckItemTypeEnough(optionId)
    elseif optionType == XEnumConst.Theatre4.EventOptionType.CheckStageScore then
        return self:CheckStageScoreEnough(optionId)
    end
    return true
end

function XUiTheatre4EventOption:CheckItemTypeEnough(optionId)
    local itemType = self._Control:GetEventOptionItemType(optionId)
    if not XTool.IsNumberValid(itemType) then
        return false
    end
    local itemId = self._Control:GetEventOptionItemId(optionId)
    local itemCount = self._Control:GetEventOptionItemCount(optionId)
    return self._Control.AssetSubControl:CheckAssetEnough(itemType, itemId, itemCount)
end

function XUiTheatre4EventOption:CheckStageScoreEnough(optionId)
    local stageScore = self.Parent:GetStageScore()
    local optionStageScoreMin = self._Control:GetEventOptionStageScoreMin(optionId)
    local optionStageScoreMax = self._Control:GetEventOptionStageScoreMax(optionId)
    if stageScore < optionStageScoreMin or stageScore > optionStageScoreMax then
        self._Control:ShowRightTipPopup(self._Control:GetClientConfig("EventOptionStageScoreNotEnough"))
        return false
    end
    return true
end

function XUiTheatre4EventOption:OnBtnSureClick()
    -- 没有选择时提示
    if not XTool.IsNumberValid(self.CurSelectOptionId) then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4EventOptionNoSelect"))
        return
    end
    -- 检查条件
    if not self:CheckConditionEnough(self.CurSelectOptionId) then
        return
    end
    -- 检查道具
    if not self:CheckItemEnough(self.CurSelectOptionId) then
        return
    end
    -- 处理事件
    self.Parent:HandleEvent(self.CurSelectOptionId)
end

return XUiTheatre4EventOption
