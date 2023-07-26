---@class XUiPcServer:XLuaUi
local XUiPcServer = XLuaUiManager.Register(XLuaUi, "UiPcServer")

function XUiPcServer:Ctor()
    self._SelectedServer = false
    ---@type XUiPcServerGrid[]
    self._GridArray = {}

    self.TextUserId = false
    self.BtnLogout = false
    self.GridItem1 = false
    self.GridItem2 = false
    self.BtnClose = false
    self.BtnConfirm = false
end

function XUiPcServer:OnStart()
    self:Init()
    self:UpdateUserId()
    self:UpdateServer()
end

function XUiPcServer:Init()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnConfirm)
    self:RegisterClickEvent(self.BtnLogout, self.Logout)

    local XUiPcServerGrid = require("XUi/XUiLogin/XUiPcServerGrid")
    self._GridArray[#self._GridArray + 1] = XUiPcServerGrid.New(self.GridItem1)
    self._GridArray[#self._GridArray + 1] = XUiPcServerGrid.New(self.GridItem2)
end

function XUiPcServer:UpdateServer()
    local serverList = XServerManager.GetServerList(false)
    local selectedServerId = XServerManager.Id
    local selectedServerIndex = 1
    for i = 1, #self._GridArray do
        local serverGrid = self._GridArray[i]
        local server = serverList[i]
        if server then
            if selectedServerId == server.Id then
                selectedServerIndex = i
            end
            serverGrid:Show()
            serverGrid:SetCallback(function(selectedServer)
                self:SetServerSelected(selectedServer)
            end)
            self._GridArray[i]:Update({
                serverName = server.Name,
                server = server,
                isLastLogin = server.Id == XServerManager.LastServerId,
                isRecommend = i == 1,
            })
        else
            self._GridArray[i]:Hide()
        end
    end
    self:SetServerSelected(serverList[selectedServerIndex])
end

function XUiPcServer:SetServerSelected(server)
    self._SelectedServer = server
    for i = 1, #self._GridArray do
        local serverGrid = self._GridArray[i]
        serverGrid:SetSelected(serverGrid:IsSelectedServer(server))
    end
end

function XUiPcServer:Logout()
    XUserManager.Logout(function()
        -- self:UpdateUserId()
    end)
end

function XUiPcServer:UpdateUserId()
    self.TextUserId.text = XUserManager.UserName
end

function XUiPcServer:OnConfirm()
    if self._SelectedServer then
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_LOGIN_PC_SELECT_SERVER, self._SelectedServer)
    end
    self:Close()
end

return XUiPcServer
