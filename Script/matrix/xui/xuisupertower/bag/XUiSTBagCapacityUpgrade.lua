--================
--背包扩容弹窗
--================
local XUiSTBagCapacityUpGrade = XLuaUiManager.Register(XLuaUi, "UiSupertowerUpTips")

function XUiSTBagCapacityUpGrade:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiSTBagCapacityUpGrade:OnStart(old, new, closeCallback)
    self.TxtCurLevel.text = new
    self.TxtOldLevel.text = old
    if self.TxtTips then self.TxtTips.text = XUiHelper.GetText("STBagPopText") end
    self.CloseCb = closeCallback
end

function XUiSTBagCapacityUpGrade:OnDisable()
    self:OnClose()
end

function XUiSTBagCapacityUpGrade:OnDestroy()
    self:OnClose()
end

function XUiSTBagCapacityUpGrade:OnClose()
    if self.CloseCb then
        local cb = self.CloseCb
        self.CloseCb = nil
        cb()
    end
end