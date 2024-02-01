---@class XUiGridTheatre3Item : XUiNode
---@field _Control XTheatre3Control
local XUiGridTheatre3Item = XClass(XUiNode, "XUiGridTheatre3Item")

function XUiGridTheatre3Item:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridTheatre3Item:Refresh(itemId, itemType, itemCount)
    if not XTool.IsNumberValid(itemId) then
        return
    end
    self.ItemId = itemId
    self.ItemType = itemType

    local itemIcon = self._Control:GetEventStepItemIcon(itemId, itemType)
    local qualityPath = self._Control:GetEventStepItemQualityIcon(itemId, itemType)
    -- 道具图标
    if self.RImgIcon and itemIcon then
        self.RImgIcon:SetRawImage(itemIcon)
    end
    -- 道具品质
    if self.ImgQuality then
        if qualityPath then
            self.ImgQuality:SetSprite(qualityPath)
        end
        self.ImgQuality.gameObject:SetActiveEx(qualityPath and true or false)
    end
    -- 道具数量
    if self.TxtCount then
        local count = itemCount or 1
        self.TxtCount.text = "x" .. count
    end
    if self.TxtName then
        self.TxtName.text = self._Control:GetEventStepItemName(itemId, itemType)
    end
end

function XUiGridTheatre3Item:RefreshCount(itemCount)
    -- 道具数量
    if self.TxtCount then
        local count = itemCount or 1
        if count == 1 then
            self.TxtCount.gameObject:SetActiveEx(false)
        else
            self.TxtCount.gameObject:SetActiveEx(true)
            self.TxtCount.text = "x" .. count
        end
    end
end

function XUiGridTheatre3Item:OnBtnClick()
    self._Control:OpenAdventureTips(self.ItemId, self.ItemType)
end

return XUiGridTheatre3Item