local XUiWaterMask = XLuaUiManager.Register(XLuaUi, "UiWaterMask")

function XUiWaterMask:OnAwake()
    self:InitUiObjects()
end

function XUiWaterMask:OnStart()
    self.TopId.text = XPlayer.Id
    self.BottomId.text = XPlayer.Id
end