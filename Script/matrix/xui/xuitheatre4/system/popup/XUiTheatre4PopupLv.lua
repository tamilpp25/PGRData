---@class XUiTheatre4PopupLv : XLuaUi
---@field BtnClose UnityEngine.UI.Button
---@field TxtOldLv UnityEngine.UI.Text
---@field TxtCurLv UnityEngine.UI.Text
local XUiTheatre4PopupLv = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupLv")

-- region 生命周期

function XUiTheatre4PopupLv:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiTheatre4PopupLv:OnStart(oldLv, newLv)
    self._OldLv = oldLv
    self._NewLv = newLv
end

function XUiTheatre4PopupLv:OnEnable()
    self:_Refresh()
end

-- endregion

-- region 按钮事件

function XUiTheatre4PopupLv:OnBtnCloseClick()
    self:Close()
end

-- endregion

-- region 私有方法
function XUiTheatre4PopupLv:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiTheatre4PopupLv:_Refresh()
    self.TxtOldLv.text = self._OldLv or 0
    self.TxtCurLv.text = self._NewLv or 0
end

-- endregion

return XUiTheatre4PopupLv
