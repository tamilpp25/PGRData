---@class XUiBigWorldBackpackDetail : XUiNode
---@field TxtItem UnityEngine.UI.Text
---@field TxtNumber UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
---@field TxtExp UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field PanelConsume UnityEngine.RectTransform
---@field ItemObtain UnityEngine.RectTransform
---@field PanelAdd UnityEngine.RectTransform
---@field TxtSelect UnityEngine.UI.InputField
---@field BtnAddSelect XUiComponent.XUiButton
---@field BtnMinusSelect XUiComponent.XUiButton
---@field BtnMax XUiComponent.XUiButton
---@field BtnConfirm XUiComponent.XUiButton
---@field _Control XBigWorldBackpackControl
---@field Parent XUiBigWorldBackpack
local XUiBigWorldBackpackDetail = XClass(XUiNode, "XUiBigWorldBackpackDetail")

-- region 生命周期

function XUiBigWorldBackpackDetail:OnStart()
    self._ItemId = 0
    self._UseCount = 0
    self._MaxCount = 0
    self:_RegisterButtonClicks()
end

function XUiBigWorldBackpackDetail:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldBackpackDetail:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
    self.PanelConsume.gameObject:SetActiveEx(false)
end

function XUiBigWorldBackpackDetail:OnDestroy()

end

-- endregion

-- region 按钮事件

function XUiBigWorldBackpackDetail:OnBtnAddSelectClick()
    if self._UseCount < self._MaxCount then
        self._UseCount = self._UseCount + 1
        self.TxtSelect.text = self._UseCount
    end
end

function XUiBigWorldBackpackDetail:OnBtnMinusSelectClick()
    if self._UseCount > 0 then
        self._UseCount = self._UseCount - 1
        self.TxtSelect.text = self._UseCount
    end
end

function XUiBigWorldBackpackDetail:OnBtnMaxClick()
    self.TxtSelect.text = self._MaxCount
end

function XUiBigWorldBackpackDetail:OnBtnConfirmClick()
    if XTool.IsNumberValid(self._UseCount) then
        XMVCA.XBigWorldService:UseItem(self._ItemId, nil, self._UseCount, function(rewardGoodsList)
            XMVCA.XBigWorldUI:OpenBigWorldObtain(rewardGoodsList, nil, function()
                self.Parent:RefreshType()
            end)
        end)
    end
end

function XUiBigWorldBackpackDetail:OnTxtSelectChanged(value)
    value = tonumber(value)

    if value > self._MaxCount then
        value = self._MaxCount
        self.TxtSelect.text = value
    end
    if value < 1 then
        value = 1
        self.TxtSelect.text = value
    end

    self._UseCount = value
end

-- endregion

function XUiBigWorldBackpackDetail:Refresh(itemParams, goodsParams, isQuest)
    local itemId = itemParams.TemplateId
    local worldDesc = goodsParams.WorldDesc
    local desc = goodsParams.Description
    local count = itemParams.Count or 0

    if isQuest then
        count = XMVCA.XBigWorldService:GetQuestItemCount(itemId)
    end

    self._ItemId = itemId
    self._MaxCount = count
    self.TxtSelect.text = self._MaxCount > 0 and 0 or 1
    self.TxtItem.text = goodsParams.Name
    self.TxtNumber.text = "x" .. self._MaxCount

    if string.IsNilOrEmpty(desc) then
        self.TxtDetail.gameObject:SetActiveEx(false)
    else
        self.TxtDetail.text = desc
        self.TxtDetail.gameObject:SetActiveEx(true)
    end
    if string.IsNilOrEmpty(desc) then
        self.ItemObtain.gameObject:SetActiveEx(false)
    else
        self.TxtExp.text = worldDesc
        self.ItemObtain.gameObject:SetActiveEx(true)
    end
    if itemParams.IsUseBigIcon then
        self.RImgIcon:SetRawImage(goodsParams.BigIcon)
    else
        self.RImgIcon:SetRawImage(goodsParams.Icon)
    end

    if not isQuest then
        self:_RefreshConsume()
    else
        self.PanelConsume.gameObject:SetActiveEx(false)
    end
end

-- region 私有方法

function XUiBigWorldBackpackDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterCommonClickEvent(self, self.BtnAddSelect, self.OnBtnAddSelectClick, true)
    XUiHelper.RegisterCommonClickEvent(self, self.BtnMinusSelect, self.OnBtnMinusSelectClick, true)
    XUiHelper.RegisterCommonClickEvent(self, self.BtnMax, self.OnBtnMaxClick, true)
    XUiHelper.RegisterCommonClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick, true)
    self.TxtSelect.onValueChanged:AddListener(Handler(self, self.OnTxtSelectChanged))
end

function XUiBigWorldBackpackDetail:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldBackpackDetail:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldBackpackDetail:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldBackpackDetail:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldBackpackDetail:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldBackpackDetail:_RefreshConsume()
    if self._Control:CheckItemCanUse(self._ItemId) then
        self.PanelConsume.gameObject:SetActiveEx(true)
        self.PanelAdd.gameObject:SetActiveEx(self._MaxCount > 1)
    else
        self.PanelConsume.gameObject:SetActiveEx(false)
    end
end

-- endregion

return XUiBigWorldBackpackDetail
