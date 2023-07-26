--挂机收益功能解锁弹窗
local XUiAreaWarHangUpJs = XLuaUiManager.Register(XLuaUi, "UiAreaWarHangUpJs")

function XUiAreaWarHangUpJs:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiAreaWarHangUpJs:OnStart(closeCb)
    self.CloseCb = closeCb
end

function XUiAreaWarHangUpJs:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end
