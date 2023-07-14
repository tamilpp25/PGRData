XUiGridServer = XClass(nil, "XUiGridServer")

local CSUiButtonStateSelect = CS.UiButtonState.Select
local CSUiButtonStateNormal = CS.UiButtonState.Normal

function XUiGridServer:Ctor(ui, server, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SelectCb = cb
    self:InitAutoScript()
    self:InitServerName(server.Name)
    self:UpdateServer(server)
end

function XUiGridServer:InitServerName(name)
    self.BtnServer:SetName(name)
end

function XUiGridServer:UpdateServer(server)
    self.Server = server
    self:UpdateServerSelect()
end

function XUiGridServer:UpdateServerSelect()
    if self.Server.Id == XServerManager.Id then
        self.BtnServer:SetButtonState(CSUiButtonStateSelect)
    else
        self.BtnServer:SetButtonState(CSUiButtonStateNormal)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridServer:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridServer:AutoInitUi()
    self.BtnServer = self.Transform:Find("BtnServer"):GetComponent("XUiButton")
end

function XUiGridServer:GetAutoKey(uiNode,eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiGridServer:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridServer:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key],eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridServer:AutoAddListener()
    self.AutoCreateListeners = {}
    self.BtnServer.CallBack = function()
        self:OnBtnServerClick()
    end
end
-- auto

function XUiGridServer:OnBtnServerClick()
    if self.SelectCb then
        self.SelectCb(self.Server.Id)
    end
end