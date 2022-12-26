local handler = handler
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridTRPGItem = XClass(nil, "XUiGridTRPGItem")

function XUiGridTRPGItem:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb

    XTool.InitUiObject(self)

    if self.PanelSite then
        self.PanelSite.gameObject:SetActiveEx(false)
    end

    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    end
end

function XUiGridTRPGItem:Refresh(itemId, itemCount)
    if self.RImgIcon then
        local iconPath = XItemConfigs.GetItemIconById(itemId)
        self.RImgIcon:SetRawImage(iconPath)
    end

    if self.TxtCount then
        local haveCount = itemCount or XDataCenter.ItemManager.GetCount(itemId)
        self.TxtCount.text = haveCount
    end

    if self.TxtCountDes then
        local haveCount = XDataCenter.ItemManager.GetCount(itemId)
        self.TxtCountDes.text = CSXTextManagerGetText("TRPGItemCount", haveCount)--(拥有: {0})
    end

    if self.TxtMax then
        local isMaxCount = XDataCenter.TRPGManager.IsItemMaxCount(itemId)
        self.TxtMax.gameObject:SetActiveEx(isMaxCount)
    end

    if self.ImgQuality then
        local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
        local qualityPath = XArrangeConfigs.GeQualityPath(quality)
        self.RootUi:SetUiSprite(self.ImgQuality, qualityPath)
    end

    if self.TxtName then
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        self.TxtName.text = itemName
    end

    if self.TxtDetails then
        local desc = XDataCenter.ItemManager.GetItemDescription(itemId)
        self.TxtDetails.text = desc
    end

    if self.PanelTag1 then
        if not XTRPGConfigs.CheckItemConfig(itemId) then
            self.PanelTag1.gameObject:SetActiveEx(false)
        else

            local isPrecious = XTRPGConfigs.IsItemPrecious(itemId)
            if not isPrecious then
                if self.ImgTag then
                    local tagIcon = XTRPGConfigs.GetItemTagIcon(itemId)
                    self.RootUi:SetUiSprite(self.ImgTag, tagIcon)
                end
                self.PanelTag1.gameObject:SetActiveEx(true)
            else
                self.PanelTag1.gameObject:SetActiveEx(false)
            end

        end
    end

    if self.PanelTag2 then
        if not XTRPGConfigs.CheckItemConfig(itemId) then
            self.PanelTag2.gameObject:SetActiveEx(false)
        else
            local isPrecious = XTRPGConfigs.IsItemPrecious(itemId)
            self.PanelTag2.gameObject:SetActiveEx(isPrecious)
        end
    end
end

function XUiGridTRPGItem:OnClickBtnClick(itemId)
    if self.ClickCb then
        self.ClickCb()
    end
end

return XUiGridTRPGItem