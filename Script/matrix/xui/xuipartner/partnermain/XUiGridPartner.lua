local XUiGridPartner = XClass(nil, "XUiGridPartner")

function XUiGridPartner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridPartner:SetButtonCallBack()
    self.BtnCharacter.CallBack = function()
        self:OnBtnSelectClick()
    end
end

function XUiGridPartner:OnBtnSelectClick()
    self.Base:SelectPartner(self.Data)
    
    local grids = self.Base.CurDynamicTable:GetGrids()
    for _,grid in pairs(grids) do
        grid:ShowSelect(false)
    end

    self:ShowSelect(true)
end

function XUiGridPartner:UpdateGrid(data, uiType, base)
    self.Data = data
    self.UiType = uiType
    self.Base = base
    
    if data then
        local lastPartner = self.Base:GetLastPartner(uiType)
        local selectPartnerId = lastPartner and lastPartner:GetId() or self.Base.DefaultSelectPartnerId
        local IsSelect = self.Data:GetId() == selectPartnerId
        if IsSelect then
            self:OnBtnSelectClick()
        else
            self:ShowSelect(IsSelect)
        end
        self:ShowInfo(uiType)
    end

end

function XUiGridPartner:ShowSelect(IsShow)
    self.PanelSelected.gameObject:SetActiveEx(IsShow)
end

function XUiGridPartner:OnCheckRedPoint(count)
    self.BtnCharacter:ShowReddot(count >= 0)
end

function XUiGridPartner:ShowInfo(uiType)
    self.ImgCanCompose.gameObject:SetActiveEx(false)
    self.ImgIsCarry.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    
    if uiType == XPartnerConfigs.MainUiState.Overview then
        self:ShowOverviewInfo()
    elseif uiType == XPartnerConfigs.MainUiState.Compose then
        self:ShowComposeInfo()
    end
    
    self.PanelLevel.gameObject:SetActiveEx(uiType == XPartnerConfigs.MainUiState.Overview)
    self.TxtCount.gameObject:SetActiveEx(uiType == XPartnerConfigs.MainUiState.Overview and self.Data:GetStackCount() > 1)
    self.PanelFragment.gameObject:SetActiveEx(uiType == XPartnerConfigs.MainUiState.Compose)
    self.ImgBreakthrough.gameObject:SetActiveEx(uiType == XPartnerConfigs.MainUiState.Overview)
end

function XUiGridPartner:ShowRed(IsShow)
    self.BtnCharacter:ShowReddot(IsShow)
end

--------------------------------总览界面用-------------------------------------------

function XUiGridPartner:ShowOverviewInfo()
    self.RImgHeadIcon:SetRawImage(self.Data:GetIcon())
    self.PanelLevel:GetObject("TxtLevel").text = self.Data:GetLevel()
    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(self.Data:GetQuality()))
    self.ImgLock.gameObject:SetActiveEx(self.Data:GetIsLock())
    self.ImgIsCarry.gameObject:SetActiveEx(self.Data:GetIsCarry())
    
    self.TxtCount:GetObject("Text").text = string.format("X%d",self.Data:GetStackCount())
    
    local btImg = self.Data:GetBreakthroughIcon()
    self.ImgBreakthrough:SetSprite(btImg)
    
    local IsShowRed = XDataCenter.PartnerManager.CheckNewSkillRedByPartnerId(self.Data:GetId())
    self:ShowRed(IsShowRed)
end

--------------------------------合成界面用-------------------------------------------

function XUiGridPartner:ShowComposeInfo()
    self.RImgHeadIcon:SetRawImage(self.Data:GetIcon())
    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(self.Data:GetInitQuality()))
    self.PanelFragment:GetObject("TxtCurCount").text = self.Data:GetChipCurCount()
    self.PanelFragment:GetObject("TxtNeedCount").text = self.Data:GetChipNeedCount()
    
    local IsCanCompose = self.Data:GetChipCurCount() >= self.Data:GetChipNeedCount()
    self.ImgCanCompose.gameObject:SetActiveEx(IsCanCompose)
    self.ImgLock.gameObject:SetActiveEx(not IsCanCompose)
    
    local IsShowRed = XDataCenter.PartnerManager.CheckComposeRedByTemplateId(self.Data:GetTemplateId())
    self:ShowRed(IsShowRed)
end

return XUiGridPartner