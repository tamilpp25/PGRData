
local XUiGridPhotographFashionBtn = XClass(nil, "XUiGridPhotographFashionBtn")

function XUiGridPhotographFashionBtn:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.Lock = self.Transform:Find("Lock")
end

function XUiGridPhotographFashionBtn:Refresh(fashionId, select)
    self.FashionId = fashionId
    local icon = XDataCenter.FashionManager.GetFashionIcon(fashionId)
    self.ImgHead:SetRawImage(icon)
    self.TxtName.text = XDataCenter.FashionManager.GetFashionName(fashionId)
    self:SetSelect(select)

    local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
    local unlock = status == XDataCenter.FashionManager.FashionStatus.UnLock
            or status == XDataCenter.FashionManager.FashionStatus.Dressed
    self.Lock.gameObject:SetActiveEx(not unlock)
end

function XUiGridPhotographFashionBtn:SetSelect(select)
    self.Sel.gameObject:SetActiveEx(select)
end

function XUiGridPhotographFashionBtn:OnTouched(charId)
    self:SetSelect(true)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_MODEL, charId, self.FashionId)
end

return XUiGridPhotographFashionBtn