---@class XUiTheatre4PopupItemDetail : XLuaUi
---@field private _Control XTheatre4Control
---@field TxtDescription XUiComponent.XUiRichTextCustomRender
local XUiTheatre4PopupItemDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupItemDetail")

function XUiTheatre4PopupItemDetail:OnAwake()
    self:RegisterUiEvents()
end

---@deprecated templateId 物品id
---@deprecated customData：自定义数据，存在时无视templateId和itemType
function XUiTheatre4PopupItemDetail:OnStart(templateId, itemType, customData, closeCb)
    self.CloseCb = closeCb
    if customData then
        self:ShowCustomData(customData)
        return
    end
    self.TemplateId = templateId
    self.ItemType = itemType
    if XTool.IsNumberValid(itemType) then
        self:ShowAssetData(templateId, itemType)
    else
        if not XTool.IsNumberValid(templateId) then
            XLog.Error("参数templateId不能为空或0")
            return
        end
        self:ShowItemData(templateId)
    end
end

function XUiTheatre4PopupItemDetail:ShowAssetData(templateId, itemType)
    -- 名称
    self.TxtName.text = self._Control.AssetSubControl:GetAssetName(itemType, templateId)
    -- 数量
    self.TxtCount.text = self._Control.AssetSubControl:GetAssetCount(itemType, templateId)
    -- 图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(itemType, templateId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 世界观描述
    local worldDesc = self._Control.AssetSubControl:GetAssetWorldDesc(itemType, templateId)
    self.TxtWorldDesc.text = XUiHelper.ConvertLineBreakSymbol(worldDesc)
    -- 描述
    local desc = self._Control.AssetSubControl:GetAssetDesc(itemType, templateId)
    self.TxtDescription.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(templateId)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    self.TxtDescription.text = XUiHelper.ConvertLineBreakSymbol(desc)
end

function XUiTheatre4PopupItemDetail:ShowItemData(templateId)
    -- 名称
    self.TxtName.text = XEntityHelper.GetItemName(templateId)
    -- 数量
    self.TxtCount.text = XGoodsCommonManager.GetGoodsCurrentCount(templateId)
    -- 图标
    local icon = XEntityHelper.GetItemIcon(templateId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 世界观描述
    local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(templateId)
    self.TxtWorldDesc.text = XUiHelper.ConvertLineBreakSymbol(worldDesc)
    -- 描述
    local desc = XGoodsCommonManager.GetGoodsDescription(templateId)
    self.TxtDescription.text = XUiHelper.ConvertLineBreakSymbol(desc)
end

function XUiTheatre4PopupItemDetail:ShowCustomData(customData)
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
end

function XUiTheatre4PopupItemDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
end

function XUiTheatre4PopupItemDetail:OnBtnBackClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.CloseCb)
end

return XUiTheatre4PopupItemDetail
