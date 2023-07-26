local XUiGridExpeditionFashion = XClass(nil, "XUiGridExpeditionFashion")

function XUiGridExpeditionFashion:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self:SetSelect(false)
end

function XUiGridExpeditionFashion:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridExpeditionFashion:OnBtnClick()
    self.RootUi:OnChildBtnClick(self)
end

function XUiGridExpeditionFashion:Refresh(fashionId, characterId)
    self.FashionId = fashionId
    self.CharacterId = characterId
    
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.RImgIcon:SetRawImage(template.Icon)

    local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
    if status == XDataCenter.FashionManager.FashionStatus.Dressed then
        self.ImgQuality.gameObject:SetActiveEx(true)
        self.RootUi:OnChildBtnClick(self)
    else
        self.ImgQuality.gameObject:SetActiveEx(false)
    end
end

function XUiGridExpeditionFashion:SetSelect(isSelect)
    if self.BgSelect then
        self.BgSelect.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridExpeditionFashion:CheckDressedState()
    local status = XDataCenter.FashionManager.GetFashionStatus(self.FashionId)
    return status == XDataCenter.FashionManager.FashionStatus.Dressed
end

return XUiGridExpeditionFashion