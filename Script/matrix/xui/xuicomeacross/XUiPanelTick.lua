local XUiPanelTick = XClass(nil, "XUiPanelTick")

function XUiPanelTick:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
    self.ImgRight.gameObject:SetActive(false)
    self.ImgWrong.gameObject:SetActive(false)
end

function XUiPanelTick:SetResult(result)
    self.ImgRight.gameObject:SetActive(result == 1)
    self.ImgWrong.gameObject:SetActive(result == 0)
end

function XUiPanelTick:Reset()
    self.ImgRight.gameObject:SetActive(false)
    self.ImgWrong.gameObject:SetActive(false)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelTick:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelTick:AutoInitUi()
    self.ImgRight = self.Transform:Find("ImgRight"):GetComponent("Image")
    self.ImgWrong = self.Transform:Find("ImgWrong"):GetComponent("Image")
end

function XUiPanelTick:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelTick:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelTick:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelTick:AutoAddListener()
end
-- auto

return XUiPanelTick
