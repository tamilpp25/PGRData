---@class XUiTheatre3Tips : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Tips = XLuaUiManager.Register(XLuaUi, "UiTheatre3Tips")

function XUiTheatre3Tips:OnAwake()
    self:RegisterUiEvents()
end

-- templateId 物品id
-- itemType：XEnumConst.THEATRE3.EventStepItemType
-- customData：自定义数据，存在时无视data和itemType
function XUiTheatre3Tips:OnStart(templateId, itemType, customData, closeCb)
    self.CloseCb = closeCb
    if customData then
        self:ShowCustomData(customData)
        return
    end

    if not XTool.IsNumberValid(templateId) then
        XLog.Error("XUiTheatre3Tips:Refresh错误: 参数templateId不能为空或0")
        return
    end

    self.TemplateId = templateId
    if not itemType then
        itemType = XEnumConst.THEATRE3.EventStepItemType.OutSideItem
    end

    local count
    if itemType == XEnumConst.THEATRE3.EventStepItemType.InnerItem then
        --TODO 肉鸽3.0道具
        count = 0
    elseif itemType == XEnumConst.THEATRE3.EventStepItemType.ItemBox or
            itemType == XEnumConst.THEATRE3.EventStepItemType.EquipBox then
        --道具箱、装备箱拥有数量
        count = 0
    else
        --通用物品
        count = XGoodsCommonManager.GetGoodsCurrentCount(self.TemplateId)
    end

    -- 名称
    self.TxtName.text = self._Control:GetEventStepItemName(self.TemplateId, itemType)
    -- 数量
    self.TxtCount.text = count
    -- 图标
    local icon = self._Control:GetEventStepItemIcon(self.TemplateId, itemType)
    self.RImgIcon:SetRawImage(icon)
    -- 世界观描述
    if itemType == XEnumConst.THEATRE3.EventStepItemType.ItemBox or itemType == XEnumConst.THEATRE3.EventStepItemType.EquipBox then
        self.TxtWorldDesc.gameObject:SetActiveEx(false)
    end
    self.TxtWorldDesc.text = self._Control:GetEventStepItemWorldDesc(self.TemplateId, itemType)
    -- 描述
    self.TxtDescription.text = self._Control:GetEventStepItemDesc(self.TemplateId, itemType)
end

function XUiTheatre3Tips:ShowCustomData(customData)
    -- 名称
    self.TxtName.text = customData.Name
    -- 数量
    self.TxtCount.text = customData.Count
    -- 图标
    self.RImgIcon:SetRawImage(customData.Icon)
    -- 世界观描述
    self.TxtWorldDesc.text = customData.WorldDesc or ""
    -- 描述
    self.TxtDescription.text = customData.Desc or ""
    -- 颜色
    local color = customData.Color
    if color then
        self.TxtName.color = color
    end
end

function XUiTheatre3Tips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOk, self.OnBtnBackClick)
end

function XUiTheatre3Tips:OnBtnBackClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiTheatre3Tips