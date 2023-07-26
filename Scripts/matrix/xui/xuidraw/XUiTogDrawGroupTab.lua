local XUiTogDrawGroupTab = XClass(nil, "XUiTogDrawGroupTab")

function XUiTogDrawGroupTab:Ctor(ui, rootUi, info)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Info = info
    self:InitAutoScript()
    self:RefreshView()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiTogDrawGroupTab:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiTogDrawGroupTab:AutoInitUi()
    self.TogDrawGroupTab = self.Transform:GetComponent("Toggle")
    self.TxtTabName = self.Transform:Find("TxtTabName"):GetComponent("Text")
    self.PanelTag = self.Transform:Find("PanelTag")
    self.TxtTagName = self.Transform:Find("PanelTag/TxtTagName"):GetComponent("Text")
end

function XUiTogDrawGroupTab:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiTogDrawGroupTab:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiTogDrawGroupTab:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiTogDrawGroupTab:AutoAddListener()
    self:RegisterClickEvent(self.TogDrawGroupTab, self.OnTogDrawGroupTabClick)
end
-- auto
function XUiTogDrawGroupTab:OnTogDrawGroupTabClick()
    self.RootUi:UpdateCards(self.Info)
end

function XUiTogDrawGroupTab:RefreshView()
    self.TxtTabName.text = self.Info.TxtName
    if (self.Info.TxtTagName) then
        self.PanelTag.gameObject:SetActive(true)
        self.TxtTagName.text = self.Info.TxtTagName
    else
        self.PanelTag.gameObject:SetActive(false)
    end
end

return XUiTogDrawGroupTab