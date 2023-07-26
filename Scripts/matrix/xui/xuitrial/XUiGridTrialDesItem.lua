local XUiGridTrialDesItem = XClass(nil, "XUiGridTrialDesItem")

function XUiGridTrialDesItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

function XUiGridTrialDesItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridTrialDesItem:OnRefresh(data)
    self.TxtNameA.text = data
end
-- auto
-- Automatic generation of code, forbid to edit
function XUiGridTrialDesItem:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridTrialDesItem:AutoInitUi()
    -- self.TxtNameA = self.Transform:Find("TxtName"):GetComponent("Text")
end

function XUiGridTrialDesItem:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTrialDesItem:RegisterClickEvent函数出错, 原因：点击回调函数不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTrialDesItem:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTrialDesItem:AutoAddListener()
end
-- auto

return XUiGridTrialDesItem
