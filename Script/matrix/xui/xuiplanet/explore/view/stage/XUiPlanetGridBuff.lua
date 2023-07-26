---@class XUiPlanetGridBuff
local XUiPlanetGridBuff = XClass(nil, "XUiPlanetGridBuff")

function XUiPlanetGridBuff:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitUiObj()
end

---@param buff XPlanetBuff
function XUiPlanetGridBuff:Update(buff)
    if not string.IsNilOrEmpty(buff:GetIcon()) then
        self.RImgBuffIcon:SetRawImage(buff:GetIcon())
    end
    self.TxtBuffName.text = buff:GetName()
    self.TxtBuffAmount.text = "x" .. buff:GetAmount()
    self.TxtBuffDesc.text = buff:GetDesc()
    
    self:SetBuffActive(false)
end

function XUiPlanetGridBuff:SetBuffActive(active)
    if self.PanelActivateTag then
        self.PanelActivateTag.gameObject:SetActiveEx(active)
    end
end

function XUiPlanetGridBuff:InitUiObj()
    --Buff
    if not self.RImgBuffIcon then
        self.RImgBuffIcon = XUiHelper.TryGetComponent(self.Transform, "ImgBuffIconBg/RImgBuffIcon", "RawImage")
    end
    if not self.TxtBuffName then
        self.TxtBuffName = XUiHelper.TryGetComponent(self.Transform, "TxtBuffName", "Text")
    end
    if not self.TxtBuffAmount then
        self.TxtBuffAmount = XUiHelper.TryGetComponent(self.Transform, "TxtBuffName/TxtBuff2", "Text")
    end
    if not self.TxtBuffDesc then
        self.TxtBuffDesc = XUiHelper.TryGetComponent(self.Transform, "TxtTitle", "Text")
    end
    -- Debuff
    if not self.RImgBuffIcon then
        self.RImgBuffIcon = XUiHelper.TryGetComponent(self.Transform, "ImgDebuffIconBg/RImgBuffIcon", "RawImage")
    end
    if not self.TxtBuffName then
        self.TxtBuffName = XUiHelper.TryGetComponent(self.Transform, "TxtDebuffName", "Text")
    end
    if not self.TxtBuffAmount then
        self.TxtBuffAmount = XUiHelper.TryGetComponent(self.Transform, "TxtBuff2", "Text")
    end
end

return XUiPlanetGridBuff