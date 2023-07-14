local XUiGridArenaTeamMember = XClass(nil, "XUiGridArenaTeamMember")

function XUiGridArenaTeamMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridArenaTeamMember:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridArenaTeamMember:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridArenaTeamMember:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridArenaTeamMember:AutoAddListener()
    self:RegisterClickEvent(self.BtnHead, self.OnBtnHeadClick)
end

function XUiGridArenaTeamMember:OnBtnHeadClick()
    if not self.Data or self.Data.Id == XPlayer.Id then
        return
    end

    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.Id)
end

function XUiGridArenaTeamMember:SetData(data, captainId)
    self.Data = data

    if not data then
        self.PanelSomeOne.gameObject:SetActive(false)
        self.PanelNone.gameObject:SetActive(true)
        return
    end

    self.PanelSomeOne.gameObject:SetActive(true)
    self.PanelNone.gameObject:SetActive(false)
    self.TxtNickname.text = XDataCenter.SocialManager.GetPlayerRemark(data.Id, data.Name)
    self.TxtPlayerLevel.text = data.Level
    local isCaptain = data.Id == captainId
    self.ImgCaptain.gameObject:SetActive(isCaptain)
    
    XUiPLayerHead.InitPortrait(data.CurrHeadPortraitId, data.CurrHeadFrameId, self.Head)
end

return XUiGridArenaTeamMember