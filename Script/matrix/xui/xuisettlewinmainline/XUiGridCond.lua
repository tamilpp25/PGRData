local XUiGridCond = XClass(nil, "XUiGridCond")

function XUiGridCond:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridCond:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridCond:AutoInitUi()
    self.TxtFail = self.Transform:Find("TxtFail"):GetComponent("Text")
    self.TxtSuccess = self.Transform:Find("TxtSuccess"):GetComponent("Text")
    self.TxtDesc = self.Transform:Find("TxtDesc"):GetComponent("Text")
end

function XUiGridCond:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridCond:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridCond:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridCond:AutoAddListener()
end
-- auto
function XUiGridCond:Refresh(desc, active)
    self.TxtDesc.text = desc
    self.TxtSuccess.gameObject:SetActive(active)
    self.TxtFail.gameObject:SetActive(not active)
end

return XUiGridCond