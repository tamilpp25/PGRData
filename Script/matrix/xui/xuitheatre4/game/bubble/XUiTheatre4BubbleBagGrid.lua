local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiTheatre4BubbleBagGrid : XUiNode
---@field _Control XTheatre4Control
---@field TxtDetail XUiComponent.XUiRichTextCustomRender
local XUiTheatre4BubbleBagGrid = XClass(XUiNode, "XUiTheatre4BubbleBagGrid")

function XUiTheatre4BubbleBagGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

---@param itemData { UId:number, ItemId:number }
function XUiTheatre4BubbleBagGrid:Refresh(itemData)
    self.UId = itemData.UId
    self.ItemId = itemData.ItemId
    self.ItemType = XEnumConst.Theatre4.AssetType.Item
    -- 描述
    self.TxtDetail.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(self.ItemId)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    local effectDesc = self._Control.EffectSubControl:GetItemEffectDesc(self.UId, self.ItemId, true) or ""
    self.TxtDetail.text = self._Control.AssetSubControl:GetAssetDesc(self.ItemType, self.ItemId) .. effectDesc
    self:UpdateItem()
end

function XUiTheatre4BubbleBagGrid:UpdateItem()
    if not self.PanelGridProp then
        ---@type XUiGridTheatre4Prop
        self.PanelGridProp = XUiGridTheatre4Prop.New(self.GridProp, self)
    end
    self.PanelGridProp:Open()
    self.PanelGridProp:Refresh({ UId = self.UId, Id = self.ItemId, Type = self.ItemType })
    self.PanelGridProp:HideQuality()
end

function XUiTheatre4BubbleBagGrid:OnBtnClick()
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    -- 打开背包界面
    XLuaUiManager.Open("UiTheatre4Bag", self.UId)
end

return XUiTheatre4BubbleBagGrid
