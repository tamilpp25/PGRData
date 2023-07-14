local XUiLoginNetworkModePanel = XClass(nil, "XUiLoginNetworkModePanel")

function XUiLoginNetworkModePanel:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUiLoginNetworkModePanel:Init()
    self:AutoRegisterListener()
    self:InitBtnGroup()
end

function XUiLoginNetworkModePanel:AutoRegisterListener()
    self.BtnExit.CallBack = function() self:Hide() end
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
end

function XUiLoginNetworkModePanel:InitBtnGroup()
    self.BtnGroup:Init({self.TogMode1, self.TogMode2, self.TogMode3}, function(index)
        self:OnBtnModeClick(index)
    end)
end

function XUiLoginNetworkModePanel:OnBtnModeClick(index)
    if index then
        if index == 1 then
            self.CurNetworkMode = XNetwork.NetworkMode.Auto
        elseif index == 2 then
            self.CurNetworkMode = XNetwork.NetworkMode.Ipv4
        elseif index == 3 then
            self.CurNetworkMode = XNetwork.NetworkMode.Ipv6
        end
    end
end

function XUiLoginNetworkModePanel:Refresh()
    self.CurNetworkMode = XSaveTool.GetData(XNetwork.NetworkModeKey) or XNetwork.NetworkMode.Auto
    if self.CurNetworkMode == XNetwork.NetworkMode.Auto then
        self.BtnGroup:SelectIndex(1, false)
    elseif self.CurNetworkMode == XNetwork.NetworkMode.Ipv4 then
        self.BtnGroup:SelectIndex(2, false)
    elseif self.CurNetworkMode == XNetwork.NetworkMode.Ipv6 then
        self.BtnGroup:SelectIndex(3, false)
    end
end

function XUiLoginNetworkModePanel:OnBtnSaveClick()
    if self.CurNetworkMode then
        XSaveTool.SaveData(XNetwork.NetworkModeKey, self.CurNetworkMode)
        XUiManager.TipMsg("Changing Network Mode Succeed.")
        self:Hide()
    end
end

function XUiLoginNetworkModePanel:Show()
    self:Refresh()
    self.GameObject:SetActiveEx(true)
end

function XUiLoginNetworkModePanel:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiLoginNetworkModePanel