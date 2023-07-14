XUiGridDailyBanner = XClass(nil, "XUiGridDailyBanner")

function XUiGridDailyBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridDailyBanner:UpdateGrid(chapter)
    self.RImgIcon:SetRawImage(chapter.Icon)
    self.TxtName.text = chapter.Title
    self.TxtRemainCount.text = ""
    self.TxtSimpleDesc.text = chapter.Describe

    local tmpText, IsAllDay = XDataCenter.FubenDailyManager.GetOpenDayString(chapter)

    if IsAllDay then
        self.TxtRemainCount.text = tmpText
    else
        self.TxtRemainCount.text = CS.XTextManager.GetText("FubenDailyOpenRemark", tmpText)
    end

    local IsConditionLock = XDataCenter.FubenDailyManager.GetConditionData(chapter.Id).IsLock
    local IsDayLock = XDataCenter.FubenDailyManager.IsDayLock(chapter.Id)
    local IsEventOpen = XDataCenter.FubenDailyManager.GetEventOpen(chapter.Id).IsOpen
    local EventText = XDataCenter.FubenDailyManager.GetEventOpen(chapter.Id).Text

    if IsConditionLock then
        self.PanelLock.gameObject:SetActive(true)
        self.ImgEvent.gameObject:SetActive(false)
        self.TxtLock.text = CS.XTextManager.GetText("NotUnlock")
    else
        if IsEventOpen then
            self.PanelLock.gameObject:SetActive(false)
            self.ImgEvent.gameObject:SetActive(true)
            self.TxtEvent.text = EventText
        else
            if IsDayLock then
                self.PanelLock.gameObject:SetActive(true)
            else
                self.PanelLock.gameObject:SetActive(false)
            end
            self.TxtLock.text = CS.XTextManager.GetText("NotUnlock")
            self.ImgEvent.gameObject:SetActive(false)
        end
    end

    local shopId = XDailyDungeonConfigs.GetFubenDailyShopId(chapter.Id)
    self.PanelShopTag.gameObject:SetActiveEx(shopId > 0 and self.PanelLock.gameObject.activeSelf == false)
    if shopId > 0 then
        local shopName = XShopManager.GetShopTypeDataById(XShopManager.ShopType.FubenDaily).Desc
        self.TxtPanelShopTag.text = shopName
    end
end

return XUiGridDailyBanner