---@class XUiPlanetDetailRoleGrid
local XUiPlanetDetailRoleGrid = XClass(nil, "XUiPlanetDetailRoleGrid")

function XUiPlanetDetailRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self._OnClick)
    self._ClickFunc = false
    self._Role = false
end

function XUiPlanetDetailRoleGrid:_OnClick()
    if self._ClickFunc then
        self._ClickFunc(self._Entity)
    end
end

function XUiPlanetDetailRoleGrid:RegisterClick(func)
    self._ClickFunc = func
end

---@param role XPlanetRoleBase
function XUiPlanetDetailRoleGrid:Update(role)
    self._Role = role
    self.GridRole:SetRawImage(role:GetIcon())
end

function XUiPlanetDetailRoleGrid:UpdateSelected(roleSelected)
    if self._Role == roleSelected then
        self.GridRole:SetButtonState(CS.UiButtonState.Select)
    else
        self.GridRole:SetButtonState(CS.UiButtonState.Normal)
    end
end

---@param entity XPlanetRunningExploreEntity
function XUiPlanetDetailRoleGrid:UpdateCaptain(entity)
    self.PanelTag.gameObject:SetActiveEx(self._Role:GetUid() == entity.Id)
end

function XUiPlanetDetailRoleGrid:GetRole()
    return self._Role
end

return XUiPlanetDetailRoleGrid