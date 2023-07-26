---@class XUiPlanetDetailGrid
local XUiPlanetDetailGrid = XClass(nil, "XUiPlanetDetailGrid")

function XUiPlanetDetailGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitUiObj()
end

function XUiPlanetDetailGrid:Update(id, isFloor, isSelect, onClick)
    local icon
    if isFloor then
        icon = XPlanetWorldConfigs.GetFloorMaterialIcon(id)
    else
        icon = XPlanetConfigs.GetReformFloorBuildModeIcon(id)
    end
    if not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
        self.RImgSelectIcon:SetRawImage(icon)
    end
    self:SetSelect(isSelect)
    self.OnClick = onClick
end

function XUiPlanetDetailGrid:SetSelect(isSelect)
    self.PanelSelect.gameObject:SetActive(isSelect)
end

function XUiPlanetDetailGrid:OnBtnClick()
    if self.OnClick then self.OnClick() end
end

function XUiPlanetDetailGrid:InitUiObj()
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "ImgChoiceBg/RImgBuildIcon", "RawImage")
    if not self.RImgIcon then
        self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "ImgBuildBg/RImgBuildIcon", "RawImage")
    end
    self.RImgSelectIcon = XUiHelper.TryGetComponent(self.Transform, "PanelSelect/ImgChoiceBg/RImgChoiceIcon", "RawImage")
    if not self.RImgSelectIcon then
        self.RImgSelectIcon = XUiHelper.TryGetComponent(self.Transform, "PanelSelect/ImgBuildBg/RImgBuildIcon", "RawImage")
    end
    self.PanelSelect = XUiHelper.TryGetComponent(self.Transform, "PanelSelect")
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "BtnClick", "Button")
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

return XUiPlanetDetailGrid