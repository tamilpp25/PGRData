local XUiBtnTab = require("XUi/XUiBase/XUiBtnTab")
-- 家具套装筛选节点
local XUiGridOption = XClass(nil, "XUiGridOption")

function XUiGridOption:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AddBtnsListeners()
end

function XUiGridOption:AddBtnsListeners()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnOption, self.OnBtnOptionClick)
end

function XUiGridOption:RegisterListener(uiNode, eventName, func)
    if not uiNode then return end
    local key = eventName .. uiNode:GetHashCode()
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiBtnTab:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridOption:OnBtnOptionClick()
    if self.SuitId then
        self.RootUi:SwitchSuitFilter(self.SuitId)
    end
end

function XUiGridOption:Init(cfg, rootUi)
    self.RootUi = rootUi

    self:UpdateOption(cfg)

    self.ImgBackGround.gameObject:SetActive(self.RootUi:GetCurrentSuitId() == self.SuitId)
end

function XUiGridOption:UpdateOption(cfg)
    self.SuitId = cfg.Id
    self.TxtOption.text = cfg.SuitName
    self.ImgIcon:SetRawImage(cfg.SuitIcon)
    self.TxtCount.text = self.RootUi:CalcFurnitureNumsBySuitId(self.SuitId)
end

return XUiGridOption