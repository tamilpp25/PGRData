local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiGridTheatre4BagPropCard : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4BagPropCard = XClass(XUiNode, "XUiGridTheatre4BagPropCard")

function XUiGridTheatre4BagPropCard:OnStart()
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.TxtNone.gameObject:SetActiveEx(false)
    self.TxtStory.gameObject:SetActiveEx(false)
    self.TxtCondition.gameObject:SetActiveEx(false)
    self.TxtNow.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
    self.BtnClick.gameObject:SetActiveEx(false)
end

---@param propData { UId:number, Id:number, Type:number, Count:number }
function XUiGridTheatre4BagPropCard:Refresh(propData)
    if not propData then
        return
    end
    self.UId = propData.UId
    self.ItemId = propData.Id
    self.ItemType = propData.Type
    self.ItemCount = propData.Count or 0
    self:RefreshProp()
    self:RefreshPropInfo()
end

function XUiGridTheatre4BagPropCard:RefreshProp()
    if not self.PanelGridProp then
        ---@type XUiGridTheatre4Prop
        self.PanelGridProp = XUiGridTheatre4Prop.New(self.GridProp, self)
    end
    self.PanelGridProp:Open()
    self.PanelGridProp:Refresh({ UId = self.UId, Id = self.ItemId, Type = self.ItemType, Count = self.ItemCount })
end

function XUiGridTheatre4BagPropCard:RefreshPropInfo()
    -- 名称
    self.TxtName.text = self._Control.AssetSubControl:GetAssetName(self.ItemType, self.ItemId)
    -- 描述
    self.TxtDetail.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(self.ItemId)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    self.TxtDetail.text = self._Control.AssetSubControl:GetAssetDesc(self.ItemType, self.ItemId)
end

return XUiGridTheatre4BagPropCard
