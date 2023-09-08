---@class XGridTheatre3EventOption : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3EventOption = XClass(XUiNode, "XGridTheatre3EventOption")

function XGridTheatre3EventOption:OnStart(selectCb)
    self._SelectCB = selectCb
    ---@type XUiComponent.XUiButton
    self._BtnOption = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    self:SetItemActive(false)
    self:AddBtnListener()
end

function XGridTheatre3EventOption:Refresh(optionId, index)
    self._OptionIndex = index
    if not self._BtnOption then
        return
    end
    local optionCfg = self._Control:GetEventOptionCfgById(optionId)
    local iconUrl = optionCfg.OptionIcon
    local itemId = optionCfg.OptionItemId[1]
    local itemIcon = self._Control:GetEventStepItemIcon(itemId, optionCfg.OptionItemType)
    local costCount = optionCfg.OptionItemCount[1]
    local iconCount = self._BtnOption.ImageList.Count / 2
    
    --选项名称
    if not string.IsNilOrEmpty(optionCfg.OptionDesc) then
        self._BtnOption:SetNameByGroup(0, optionCfg.OptionDesc)
    end
    --选项描述
    if not string.IsNilOrEmpty(optionCfg.OptionDownDesc) then
        self._BtnOption:SetNameByGroup(1, optionCfg.OptionDownDesc)
    end
    --选项道具消耗文本
    for i = 0, self._BtnOption.TxtGroupList[2].TxtList.Count - 1 do
        self._BtnOption.TxtGroupList[2].TxtList[i].gameObject:SetActiveEx(XTool.IsNumberValid(costCount))
    end
    if optionCfg.OptionType == XEnumConst.THEATRE3.EventStepOptionType.CostItem then
        if XTool.IsNumberValid(costCount) then
            self._BtnOption:SetNameByGroup(2, "-" .. costCount)
        end
    elseif optionCfg.OptionType == XEnumConst.THEATRE3.EventStepOptionType.CheckItem then
        if XTool.IsNumberValid(costCount) then
            self._BtnOption:SetNameByGroup(2, costCount)
        end
    end
    --选项图标
    for i = 0, self._BtnOption.ImageList.Count - 1 do
        self._BtnOption.ImageList[i].gameObject:SetActiveEx(i < iconCount)
        if i < iconCount then
            self._BtnOption.ImageList[i]:SetSprite(iconUrl)
        end
    end
    --道具图标
    if not string.IsNilOrEmpty(itemIcon) then
        self._BtnOption:SetRawImage(itemIcon)
    end
    self:SetItemActive(XTool.IsNumberValid(itemId))
end

function XGridTheatre3EventOption:SetItemActive(active)
    if not self._BtnOption then
        return
    end
    for i = 0, self._BtnOption.ImageList.Count - 1 do
        self._BtnOption.ImageList[i].gameObject:SetActiveEx(XTool.IsNumberValid(active))
    end
    for i = 0, self._BtnOption.RawImageList.Count - 1 do
        self._BtnOption.RawImageList[i].gameObject:SetActiveEx(XTool.IsNumberValid(active))
    end
end

function XGridTheatre3EventOption:SetOptionSelect(isSelect)
    if not self._BtnOption then
        return
    end
    if isSelect then
        self._BtnOption:SetButtonState(CS.UiButtonState.Select)
    else
        self._BtnOption:SetButtonState(CS.UiButtonState.Normal)
    end
end

--region Ui - BtnListener
function XGridTheatre3EventOption:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self._BtnOption, self.OnBtnOptionClick)
end

function XGridTheatre3EventOption:OnBtnOptionClick()
    if self._SelectCB then
        self._SelectCB(self._OptionIndex)
    end
end
--endregion

return XGridTheatre3EventOption