---@class XGridTheatre3OptionCost
---@field Icon UnityEngine.UI.RawImage
---@field ImgBg UnityEngine.UI.Image
---@field Text UnityEngine.UI.Text

---@class XGridTheatre3EventOption : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3EventOption = XClass(XUiNode, "XGridTheatre3EventOption")

function XGridTheatre3EventOption:OnStart(selectCb)
    self._SelectCB = selectCb
    ---@type XUiComponent.XUiButton
    self._BtnOption = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    ---@type XGridTheatre3OptionCost[]
    self._OptionCostList = {}
    self:AddBtnListener()
end

function XGridTheatre3EventOption:Refresh(optionId, index)
    self._OptionIndex = index
    if not self._BtnOption then
        return
    end
    local optionCfg = self._Control:GetEventOptionCfgById(optionId)
    local iconUrl = optionCfg.OptionIcon
    
    --选项名称
    if not string.IsNilOrEmpty(optionCfg.OptionDesc) then
        self._BtnOption:SetNameByGroup(0, optionCfg.OptionDesc)
    end
    --选项描述
    if not string.IsNilOrEmpty(optionCfg.OptionDownDesc) then
        self._BtnOption:SetNameByGroup(1, optionCfg.OptionDownDesc)
    end
    if not self.PanelItem then
        return
    end
    --选项道具相关
    if XTool.IsTableEmpty(optionCfg.OptionItemId) then
        self.PanelItem.gameObject:SetActiveEx(false)
    else
        self.PanelItem.gameObject:SetActiveEx(true)
        for i, itemId in ipairs(optionCfg.OptionItemId) do
            if not self._OptionCostList[i] then
                local go = i == 1 and self.PanelIcon or XUiHelper.Instantiate(self.PanelIcon, self.PanelItem)
                self._OptionCostList[i] = XTool.InitUiObjectByUi({}, go)
            end
            -- 消耗文本
            if optionCfg.OptionType == XEnumConst.THEATRE3.EventStepOptionType.CostItem then
                if XTool.IsNumberValid(optionCfg.OptionItemCount[i]) then
                    self._OptionCostList[i].Text.text = "-" .. optionCfg.OptionItemCount[i]
                end
            elseif optionCfg.OptionType == XEnumConst.THEATRE3.EventStepOptionType.CheckItem then
                if XTool.IsNumberValid(optionCfg.OptionItemCount[i]) then
                    self._OptionCostList[i].Text.text = optionCfg.OptionItemCount[i]
                end
            end
            --选项背景
            if not string.IsNilOrEmpty(iconUrl) then
                self._OptionCostList[i].ImgBg:SetSprite(iconUrl)
            end
            --选项图标
            local itemIcon = self._Control:GetEventStepItemIcon(itemId, optionCfg.OptionItemType)
            self._OptionCostList[i].Icon:SetRawImage(itemIcon)
        end
    end
    --选项特效
    if self.Effect and XTool.IsNumberValid(optionCfg.QuantumEffectShowType) then
        local effectUrl = self._Control:GetClientConfig("QuantumEffectShowType", optionCfg.QuantumEffectShowType)
        if not string.IsNilOrEmpty(effectUrl) then
            self.Effect:LoadUiEffect(effectUrl)
        end
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
    self._Control:RegisterClickEvent(self, self._BtnOption, self.OnBtnOptionClick)
end

function XGridTheatre3EventOption:OnBtnOptionClick()
    if self._SelectCB then
        self._SelectCB(self._OptionIndex)
    end
end
--endregion

return XGridTheatre3EventOption