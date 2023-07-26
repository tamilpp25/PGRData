local XUiGridBuffInfoItem = XClass(nil, "XUiGridBuffInfoItem")

function XUiGridBuffInfoItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridBuffInfoItem:SetBuffInfo(buffData)
    local buffId = buffData.Id
    local buffConfig = XFubenRogueLikeConfig.GetBuffConfigById(buffId)
    if self.RImgBuffIcon then
        self.RImgBuffIcon:SetRawImage(buffConfig.Icon)
    end
    if self.TxtName then
        self.TxtName.text = buffConfig.Name
    end
    if self.TxtDetails then
        self.TxtDetails.text = buffConfig.Description
    end
end

function XUiGridBuffInfoItem:SetBuffInfoById(buffId)
    local buffData = {}
    buffData.Id = buffId
    self:SetBuffInfo(buffData)
end


return XUiGridBuffInfoItem