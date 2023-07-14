local XUiGridBuffDetailItem = XClass(nil, "XUiGridBuffDetailItem")

function XUiGridBuffDetailItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end


function XUiGridBuffDetailItem:SetBuffInfo(buff)
    self.BuffData = buff
    local buffTemplate = XFubenRogueLikeConfig.GetBuffConfigById(self.BuffData.BuffId)

    self.TxtName.text = buffTemplate.Name
    self.TxtDetails.text = buffTemplate.Description
    self.RImgBuffIcon:SetRawImage(buffTemplate.Icon)
    if self.ImgDebuffKuang then
        self.ImgDebuffKuang.gameObject:SetActiveEx(self.BuffData.BuffType == XFubenRogueLikeConfig.BuffType.NegativeBuff)
    end
    if self.ImgNew then
        self.ImgNew.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.IsBuffNew(self.BuffData.BuffId))
    end
    self:SetSelected(self.BuffData.IsSelect)
end

function XUiGridBuffDetailItem:SetSelected(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end


return XUiGridBuffDetailItem