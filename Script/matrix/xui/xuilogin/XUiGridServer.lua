local XUiGridServer = XClass(nil, "XUiGridServer")

function XUiGridServer:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridServer:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridServer:UpdateServerState()
    if not self.Enable then return end
    local state = self.Server.State
    self.PanelMaintain.gameObject:SetActiveEx(false)
    self.PanelLow.gameObject:SetActiveEx(false)
    self.PanelHigh.gameObject:SetActiveEx(false)

    if state == XServerManager.SERVER_STATE.MAINTAIN then
        self.PanelMaintain.gameObject:SetActiveEx(true)
    elseif state == XServerManager.SERVER_STATE.LOW then
        self.PanelLow.gameObject:SetActiveEx(true)
    else
        self.PanelHigh.gameObject:SetActiveEx(true)
        if state == XServerManager.SERVER_STATE.CHECK then
            self.TxtHigh.text = CS.XTextManager.GetText("ServerChecking")
        elseif state == XServerManager.SERVER_STATE.FAIL then
            self.TxtHigh.text = CS.XTextManager.GetText("ServerFail")
        elseif state == XServerManager.SERVER_STATE.HIGH then
            self.TxtHigh.text = CS.XTextManager.GetText("ServerHigh")
        end
    end
end

function XUiGridServer:Refresh(server)
    self.Server = server
    local name = server.Name
    if server.LastTime ~= nil and server.LastTime > 0 then
        local timeStr = XUiHelper.CalcLatelyLoginTime(server.LastTime, os.time())
        name = string.format("%s - （%s）", name, timeStr)
    end

    self.TxtNameMaintain.text = name
    self.TxtNameLow.text = name
    self.TxtNameHigh.text = name

    self:UpdateServerSelect()
    self.Enable = true
end

function XUiGridServer:UpdateServerSelect()
    self.ImgSelect.gameObject:SetActiveEx(self.Server.Id == XServerManager.Id)
end

function XUiGridServer:OnRecycle()
    self.Enable = false
end

return XUiGridServer