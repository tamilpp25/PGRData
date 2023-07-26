
local XUiGridPhotographPartnerBtn = XClass(nil, "XUiGridPhotographPartnerBtn")

function XUiGridPhotographPartnerBtn:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridPhotographPartnerBtn:Refresh(data, select)
    self.TemplateId = data.TemplateId
    self.Data = data
    local isValid =  XTool.IsNumberValid(self.TemplateId)
    self.Unlock.gameObject:SetActiveEx(isValid and not data.Unlock)
    self.None.gameObject:SetActiveEx(not isValid)
    self.Nor.gameObject:SetActiveEx(isValid)
    self:Select(select)
    if not isValid then return end
    
    self.ImgHead:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    if self.TxtNameEn then
        self.TxtNameEn.gameObject:SetActiveEx(false)
        --self.TxtNameEn.text = XPartnerConfigs.QualityString[data.Quality or 1]
    end
end

function XUiGridPhotographPartnerBtn:Select(select)
    self.Sel.gameObject:SetActiveEx(select)
end

function XUiGridPhotographPartnerBtn:OnClickGrid()
    if not self.Data.Unlock then
        return false
    end
    self:Select(true)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_PARTNER, self.TemplateId)
    return true
end

function XUiGridPhotographPartnerBtn:GetTemplateId()
    return self.TemplateId
end

function XUiGridPhotographPartnerBtn:GetName()
    return self.Data.Name
end

return XUiGridPhotographPartnerBtn