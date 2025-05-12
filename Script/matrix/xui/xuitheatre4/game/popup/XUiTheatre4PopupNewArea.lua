---@class XUiTheatre4PopupNewArea : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4PopupNewArea = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupNewArea")

function XUiTheatre4PopupNewArea:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiTheatre4PopupNewArea:OnStart(mapGroup, mapId, callback)
    self.Callback = callback
    local index = self._Control.MapSubControl:GetIndexByMapGroupAndMaoId(mapGroup, mapId)
    self.TxtAreaName.text = self._Control.MapSubControl:GetMapIndexName(index)
    local desc = self._Control.MapSubControl:GetMapDesc(mapId)
    if not string.IsNilOrEmpty(desc) then
        self.TxtIntro.gameObject:SetActiveEx(true)
        self.TxtIntro.text = desc
    end
end

function XUiTheatre4PopupNewArea:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.Callback)
end

return XUiTheatre4PopupNewArea
