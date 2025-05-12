---@class XUiTheatre3LvTips : XLuaUi BP等级提升
local XUiTheatre3LvTips = XLuaUiManager.Register(XLuaUi, "UiTheatre3LvTips")

function XUiTheatre3LvTips:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiTheatre3LvTips:OnStart(param, callBack)
    self.TxtOldLv.text = param.old
    self.TxtCurLv.text = param.now
    self._CallBack = callBack
end

function XUiTheatre3LvTips:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

return XUiTheatre3LvTips