--肉鸽2.0道具详情弹窗
local XUiBiancaTheatreTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreTips")

function XUiBiancaTheatreTips:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnOk, self.Close)
end

-- data 可以是 XItemData / XEquipData / XCharacterData / XFashionData
-- itemType：XBiancaTheatreConfigs.XEventStepItemType
-- customData：自定义数据，存在时无视data和itemType
function XUiBiancaTheatreTips:OnStart(data, itemType, customData)
    if customData then
        self:ShowCustomData(customData)
        return
    end

    self.Data = data
    if not data then
        XLog.Error("XUiBiancaTheatreTips:Refresh错误: 参数data不能为空")
        return
    end

    if not itemType then
        itemType = (type(data) ~= "number" and data.TheatreItemId) and XBiancaTheatreConfigs.XEventStepItemType.InnerItem or XBiancaTheatreConfigs.XEventStepItemType.OutSideItem
    end

    local itemId, count
    if type(data) == "number" then
        itemId = data
    else
        itemId = data.TheatreItemId or data.TemplateId or data.Id
    end

    if itemType == XBiancaTheatreConfigs.XEventStepItemType.InnerItem then
        --肉鸽2.0道具
        local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
        count = adventureManager and adventureManager:GetTheatreItemCount(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.ItemBox or
        itemType == XBiancaTheatreConfigs.XEventStepItemType.Ticket or
        itemType == XBiancaTheatreConfigs.XEventStepItemType.DecayTicket then
        --道具箱、招募券拥有数量
        count = 0
    else
        --通用物品
        count = XGoodsCommonManager.GetGoodsCurrentCount(itemId)
    end

    -- 名称
    self.TxtName.text = XBiancaTheatreConfigs.GetEventStepItemName(itemId, itemType)
    -- 数量
    self.TxtCount.text = count
    -- 图标
    local icon = XBiancaTheatreConfigs.GetEventStepItemIcon(itemId, itemType)
    self.RImgIcon:SetRawImage(icon)
    -- 世界观描述
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.DecayTicket then
        self.TxtWorldDesc.gameObject:SetActiveEx(false)
    end
    self.TxtWorldDesc.text = XBiancaTheatreConfigs.GetEventStepItemWorldDesc(itemId, itemType)
    -- 描述
    self.TxtDescription.text = XBiancaTheatreConfigs.GetEventStepItemDesc(itemId, itemType)
end

function XUiBiancaTheatreTips:ShowCustomData(customData)
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

return XUiBiancaTheatreTips