local XUiGridArenaTeamSingle = XClass(nil, "XUiGridArenaTeamSingle")

function XUiGridArenaTeamSingle:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.ArenaLevel = XUiHelper.TryGetComponent(self.Transform, "ArenaLevel", nil).gameObject
end

function XUiGridArenaTeamSingle:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridArenaTeamSingle:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridArenaTeamSingle:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridArenaTeamSingle:AutoAddListener()
    self:RegisterClickEvent(self.BtnInvite, self.OnBtnInviteClick)
    self:RegisterClickEvent(self.BtnHead, self.OnBtnHeadClick)
    self:RegisterClickEvent(self.BtnInviteDis, self.OnBtnInviteDisClick)
end

function XUiGridArenaTeamSingle:OnBtnHeadClick()
    if not self.Data or not self.Data.Info or self.Data.Info.Id == XPlayer.Id then
        return
    end

    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.Info.Id)
end

function XUiGridArenaTeamSingle:OnBtnInviteDisClick()
    -- if not self.Data then
    --     return
    -- end
    -- local text = ""
    -- if self.Data.ChallengeId > 0 then
    --     text = CS.XTextManager.GetText("ArenaTeamLevelError")
    -- else
    --     text = CS.XTextManager.GetText("ArenaTeamChallengeError")
    -- end
    -- XUiManager.TipError(text)
end

function XUiGridArenaTeamSingle:OnBtnInviteClick()
    if not self.Data then
        return
    end

    if self.Data.Invite == 1 then
        return
    end

    local teamId = XDataCenter.ArenaManager.GetTeamId()
    if teamId <= 0 then
        XUiManager.TipError(CS.XTextManager.GetText("ArenaTeamCanNotInvite"))
        return
    end

    if not XDataCenter.ArenaManager.CheckSelfIsCaptain() then
        XUiManager.TipError(CS.XTextManager.GetText("ArenaTeamIsNotCaptain"))
        return
    end

    XDataCenter.ArenaManager.RequestInvitePlayer(self.Data.Info.Id, function()
        self.Data.ChallengeId = XDataCenter.ArenaManager.GetCurChallengeId()
        self:Refresh()
    end)
end

function XUiGridArenaTeamSingle:ResetData(data, rootUi)
    self.Data = data
    self.RootUi = rootUi
    self:Refresh()
end

function XUiGridArenaTeamSingle:Refresh()
    if not self.Data then
        return
    end

    self.TxtNickname.text = XDataCenter.SocialManager.GetPlayerRemark(self.Data.Info.Id, self.Data.Info.Name)
    self.TxtPlayerLevel.text = self.Data.Info.Level

    local isOnline = self.Data.Info.Online == 1
    self.TxtOnline.gameObject:SetActiveEx(isOnline)
    self.TxtOffline.gameObject:SetActiveEx(not isOnline)

    local isInvited = self.Data.Invite == 1
    self.TxtInvited.gameObject:SetActiveEx(isInvited)
    self.TxtNotInvited.gameObject:SetActiveEx(not isInvited)
    if self.BtnInviteDis and not XTool.UObjIsNil(self.BtnInviteDis) then
        self.BtnInviteDis.gameObject:SetActiveEx(false)
    end
    
    XUiPLayerHead.InitPortrait(self.Data.Info.CurrHeadPortraitId, self.Data.Info.CurrHeadFrameId, self.Head)
    
    if self.Data.ArenaLevel then
        self.ArenaLevel:SetActiveEx(true)
        local isSameId = self.Data.ChallengeId == XDataCenter.ArenaManager.GetCurChallengeId()
        if self.BtnInviteDis and not XTool.UObjIsNil(self.BtnInviteDis) and (not isInvited) then
            self.BtnInviteDis.gameObject:SetActiveEx(not isSameId)
        end

        if not isSameId and self.TxtInviteDis then
            self.TxtNotInvited.gameObject:SetActiveEx(isSameId)
            if self.Data.ChallengeId > 0 then
                self.TxtInviteDis.text = CS.XTextManager.GetText("ArenaTeamLevelError")
            else
                self.TxtInviteDis.text = CS.XTextManager.GetText("ArenaTeamChallengeError")
            end
        end

        self.RImgArenaLevel.gameObject:SetActiveEx(true)
        local arenaCfg = XArenaConfigs.GetArenaLevelCfgByLevel(self.Data.ArenaLevel)
        self.RImgArenaLevel:SetRawImage(arenaCfg.Icon)
    else
        self.ArenaLevel:SetActiveEx(false)
        self.RImgArenaLevel.gameObject:SetActiveEx(false)
    end
end

return XUiGridArenaTeamSingle