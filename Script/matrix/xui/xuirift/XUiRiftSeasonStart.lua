---@class XUiRiftSeasonStart : XLuaUi
local XUiRiftSeasonStart = XLuaUiManager.Register(XLuaUi, "UiRiftSeasonStart")

function XUiRiftSeasonStart:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiRiftSeasonStart:OnStart(callBack)
    self._CallBack = callBack
    self.TxtTitle.text = XUiHelper.GetText("RiftSeasonStart", XDataCenter.RiftManager:GetSeasonName())
end

function XUiRiftSeasonStart:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

function XUiRiftSeasonStart:OnDestroy()

end

return XUiRiftSeasonStart