--================
--解锁特权弹窗
--================
local XUiSTFunctionUnlock = XLuaUiManager.Register(XLuaUi, "UiSuperTowerUnlockTips")

function XUiSTFunctionUnlock:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiSTFunctionUnlock:OnStart(funcList, closeCallback)
    self.CloseCb = closeCallback
    self:ShowFuncList(funcList)
end

function XUiSTFunctionUnlock:ShowFuncList(funcList)
    self.GridUnlockIcon.gameObject:SetActiveEx(false)
    local gridScript = require("XUi/XUiSuperTower/Function/XUiSTFunctionIcon")
    for _, func in pairs(funcList) do
        local gridGo = CS.UnityEngine.Object.Instantiate(self.GridUnlockIcon.gameObject, self.PanelUnlockInfo)
        local grid = gridScript.New(gridGo, func)
        grid:Show()
    end
end

function XUiSTFunctionUnlock:OnDisable()
    self:OnClose()
end

function XUiSTFunctionUnlock:OnDestroy()
    self:OnClose()
end

function XUiSTFunctionUnlock:OnClose()
    if self.CloseCb then
        local cb = self.CloseCb
        self.CloseCb = nil
        cb()
    end
end