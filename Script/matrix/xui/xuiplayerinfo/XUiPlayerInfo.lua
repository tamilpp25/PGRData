local XUiPlayerInfo = XLuaUiManager.Register(XLuaUi, "UiPlayerInfo")

function XUiPlayerInfo:OnStart(data, chatContent, isOpenFromSetting)
    self.Data = data
    self.ChatContent = chatContent
    self.IsOpenFromSetting = isOpenFromSetting  --是否从设置预览进入
    self.Tab = {
        BaseInfo = 1,
        FightInfo = 2,
        AppearanceInfo = 3,
    }
    --ButtonCallBack
    self.BtnChat.CallBack = function() self:OnBtnChat() end
    self.BtnAddFriend.CallBack = function() self:OnBtnAddFriend() end
    self.BtnReport.CallBack = function() self:OnBtnReport() end
    self.BtnClose.CallBack = function() self:OnBtnClose() end
    self.BtnReplace.CallBack = function() self:OnBtnReplaceClick() end
    self.BtnOut.CallBack = function() self:OnBtnOutClick() end
    self.BtnRequestGuild.CallBack = function() self:OnBtnRequestGuildClick() end
    self.BtnInviteGuild.CallBack = function() self:OnBtnInviteGuildClick() end
    self.BtnBuildMentorships.CallBack = function() self:OnBtnBuildMentorshipsClick() end
    self.BtnDisconnect.CallBack = function() self:OnBtnDisconnectClick() end
    self.BtnGraduation.CallBack = function() self:OnBtnDisconnectClick() end
    self.BtnBlock.CallBack = function() self:OnBtnBlockClick() end

    self.PanelBaseInfo = nil
    self.PanelFightInfo = nil
    self.PanelAppearanceInfo = nil
    self.TabPanels = {}
    --self.TabGroup:Init({ self.BtnBaseInfo, self.BtnFightInfo, self.BtnAppearance }, function(index) self:OnTabGroupClick(index) end)
    --self.TabGroup:SelectIndex(self.Tab.BaseInfo)
    self.BtnBaseInfo:SetDisable(true)
    self.BtnFightInfo:SetDisable(true)
    self.BtnAppearance:SetDisable(true)
    self:UpdateInfo(self.Tab.BaseInfo)
end

function XUiPlayerInfo:OnDestroy()
    if self.PanelBaseInfo then
        self.PanelBaseInfo:Destroy()
    end
end

function XUiPlayerInfo:OnTabGroupClick(index)
    --功能未完成，暂时屏蔽
    if index == self.Tab.FightInfo or index == self.Tab.AppearanceInfo then
        XUiManager.TipText("CommonNotOpen")
        return
    end
    self:UpdateInfo(index)
end

function XUiPlayerInfo:OnBtnChat()
    -- 联机中不给跳转，防止跳出联机房间
    local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if unionFightData and unionFightData.Id then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionCantLeaveRoom"))
        return
    end

    XUiHelper.CloseUiChatServeMain()

    if XLuaUiManager.IsUiShow("UiSocial") then
        XLuaUiManager.CloseWithCallback("UiPlayerInfo", function()
            XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self.Data.Id)
        end)
    else
        XLuaUiManager.Open("UiSocial", function()
            XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self.Data.Id)
        end)
    end
end

function XUiPlayerInfo:OnBtnAddFriend()
    XDataCenter.SocialManager.ApplyFriend(self.Data.Id)
end

function XUiPlayerInfo:OnBtnReport()
    local data = { Id = self.Data.Id, TitleName = self.Data.Name, PlayerLevel = self.Data.Level, PlayerIntroduction = self.Data.Sign }
    XLuaUiManager.Open("UiReport", data, self.ChatContent)
end

function XUiPlayerInfo:OnBtnClose()
    self:Close()
end

function XUiPlayerInfo:UpdateInfo(index)
    if self.Data.Id == XPlayer.Id then
        self.BtnAddFriend.gameObject:SetActiveEx(false)
        self.BtnChat.gameObject:SetActiveEx(false)
        self.BtnReport.gameObject:SetActiveEx(false)
        self.Mask.gameObject:SetActiveEx(false)
        self.BtnBlock.gameObject:SetActiveEx(false)
    elseif XDataCenter.SocialManager.CheckIsFriend(self.Data.Id) then
        self.BtnAddFriend.gameObject:SetActiveEx(false)
        self.BtnChat.gameObject:SetActiveEx(true)
        self.BtnReport.gameObject:SetActiveEx(true)
        self.Mask.gameObject:SetActiveEx(true)
        self.BtnBlock.gameObject:SetActiveEx(true)
    else
        self.BtnAddFriend.gameObject:SetActiveEx(true)
        self.BtnChat.gameObject:SetActiveEx(false)
        self.BtnReport.gameObject:SetActiveEx(true)
        self.Mask.gameObject:SetActiveEx(true)
        self.BtnBlock.gameObject:SetActiveEx(true)
    end

    if index == self.Tab.BaseInfo then
        if not self.PanelBaseInfo then
            local obj = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("PlayerInfoBase"))
            obj.transform:SetParent(self.PanelContent, false)
            self.PanelBaseInfo = XUiPlayerInfoBase.New(obj, self)
            self.TabPanels[index] = self.PanelBaseInfo
            self.TabPanels[index].Type = self.Tab.BaseInfo
        else
            self.PanelBaseInfo:UpdateInfo()
        end
        self:UpdateGuildInfo()
    elseif index == self.Tab.FightInfo then
        if not self.PanelFightInfo then
            local obj = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("PlayerInfoFight"))
            obj.transform:SetParent(self.PanelContent, false)
            self.PanelFightInfo = XUiPlayerInfoFight.New(obj, self)
            self.TabPanels[index] = self.PanelFightInfo
            self.TabPanels[index].Type = self.Tab.FightInfo
        else
            self.PanelFightInfo:UpdateInfo()
        end
    elseif index == self.Tab.AppearanceInfo then
        if not self.PanelAppearanceInfo then
            local obj = CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab("PlayerInfoAppearance"))
            obj.transform:SetParent(self.PanelContent, false)
            self.PanelAppearanceInfo = XUiPlayerInfoAppearance.New(obj, self)
            self.TabPanels[index] = self.PanelAppearanceInfo
            self.TabPanels[index].Type = self.Tab.AppearanceInfo
        else
            self.PanelAppearanceInfo:UpdateInfo()
        end
    end
    self:UpdateMentorInfo()
    self:ActivePanel(index)
end

function XUiPlayerInfo:UpdateGuildInfo()
    -- 如果自己有公会
    --查看一个有公会的玩家
    -- 同一个公会       ：管理级别以上：更换职位、踢出公会
    -- 不同公会         ：都不显示
    --查看一个没有公会的玩家     ：管理级别以上：邀请入会
    -- 如果自己没有公会
    --查看一个有公会的玩家       ：申请入会
    --查看一个没有公会的玩家     ：都不显示
    self:ResetGuildBtns()
    if not self.Data then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild, false, true) then
        self.BtnRequestGuild.gameObject:SetActiveEx(false)
        return
    end
    local targetGuildId = self.Data.GuildDetail and self.Data.GuildDetail.GuildId
    local targetRankLevel = self.Data.GuildDetail and self.Data.GuildDetail.GuildRankLevel

    if self.Data.Id == XPlayer.Id then return end

    if XDataCenter.GuildManager.IsJoinGuild() then
        local isAdministor = XDataCenter.GuildManager.IsGuildAdminister()
        local myRankLevel = XDataCenter.GuildManager.GetCurRankLevel()
        if XDataCenter.GuildManager.CheckMemberOperatePermission(self.Data.Id) then
            self.BtnOut.gameObject:SetActiveEx(true)
            self.BtnReplace.gameObject:SetActiveEx(true)
        else
            if isAdministor then
                self.BtnInviteGuild.gameObject:SetActiveEx(true)
            end
        end
    else
        if targetGuildId ~= nil and targetGuildId > 0 then
            self.BtnRequestGuild.gameObject:SetActiveEx(true)
        end
    end
end

function XUiPlayerInfo:UpdateMentorInfo()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local IsSelf = self.Data.Id == XPlayer.Id
    local IsMyMentorShip = mentorData:IsMyMentorShip(self.Data.Id)
    local IdentityType = self.Data.MentorDetail and self.Data.MentorDetail.MentorType or XMentorSystemConfigs.IdentityType.None
    local IsSameIdentity = IdentityType == mentorData:GetIdentity()
    local IsCanShow = not IsSelf and not IsSameIdentity and IdentityType ~= XMentorSystemConfigs.IdentityType.None
    local IsCanGraduatLevel = self:CheckIsCanGraduatLevel(mentorData)
    self.BtnBuildMentorships.gameObject:SetActiveEx(IsCanShow and not IsMyMentorShip)
    self.BtnDisconnect.gameObject:SetActiveEx((not IsCanGraduatLevel) and IsCanShow and IsMyMentorShip)
    self.BtnGraduation.gameObject:SetActiveEx(IsCanGraduatLevel and IsCanShow and IsMyMentorShip)
end

function XUiPlayerInfo:ResetGuildBtns()
    self.BtnRequestGuild.gameObject:SetActiveEx(false)
    self.BtnInviteGuild.gameObject:SetActiveEx(false)
    self.BtnOut.gameObject:SetActiveEx(false)
    self.BtnReplace.gameObject:SetActiveEx(false)
end

function XUiPlayerInfo:HasModifyGuildAccess()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return true
    end
    return false
end

function XUiPlayerInfo:ChecGuildKickOut()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        return true
    end
    return false
end

function XUiPlayerInfo:OnBtnReplaceClick()
    -- 中途被踢出公会
    if self:ChecGuildKickOut() then return end
    -- 职位变更
    if self:HasModifyGuildAccess() then return end
    -- 是否有更换职位的权利
    local memberList = XDataCenter.GuildManager.GetMemberList()
    local memberInfo = memberList[self.Data.Id]
    if memberInfo then
        XLuaUiManager.Open("UiGuildChangePosition", XGuildConfig.TipsType.ChangePosition, memberInfo)
    end
end

function XUiPlayerInfo:OnBtnOutClick()
    -- 中途被踢出公会
    if self:ChecGuildKickOut() then return end
    -- 职位变更
    if self:HasModifyGuildAccess() then return end

    local title = CS.XTextManager.GetText("GuildDialogTitle")
    local content = CS.XTextManager.GetText("GuildIsKickMember")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        XDataCenter.GuildManager.GuildKickMember(self.Data.Id, function()
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickMemberSuccess"))
            self:Close()
        end)
    end)
end

-- 申请入会
function XUiPlayerInfo:OnBtnRequestGuildClick()
    if not self.Data then return end
    if self.Data.GuildDetail and self.Data.GuildDetail.GuildId and self.Data.GuildDetail.GuildId > 0 then
        XDataCenter.GuildManager.ApplyToJoinGuildRequest(self.Data.GuildDetail.GuildId, function()
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildApplyRequestSuccess"))
            self:Close()
        end)
    end
end

-- 邀请入会
function XUiPlayerInfo:OnBtnInviteGuildClick()
    if not self.Data then return end
    -- 中途被踢出公会
    if self:ChecGuildKickOut() then return end
    -- 职位变更
    if self:HasModifyGuildAccess() then return end

    XDataCenter.GuildManager.GuildRecruit(self.Data.Id, function()
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildSendRequestSuccess"))
        self:Close()
    end, true)
end

-- 缔结师徒关系
function XUiPlayerInfo:OnBtnBuildMentorshipsClick()
    if not self.Data then return end

    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local IsCanGraduatLevel = self:CheckIsCanGraduatLevel(mentorData)
    local hintStr = ""

    if not mentorData:IsCanDoApply(true) then
        return
    else
        if mentorData:IsTeacher() then
            local IsHasTeacher = self.Data.MentorDetail.MentorId and self.Data.MentorDetail.MentorId > 0
            if IsHasTeacher then
                XUiManager.TipMsg(CS.XTextManager.GetText("MentorDoApplyTeachaeMaxHint"))
                return
            end
            if IsCanGraduatLevel then
                XUiManager.TipMsg(CS.XTextManager.GetText("MentorDoApplyLevelOverHint"))
                return
            end
        end
    end

    XDataCenter.MentorSystemManager.ApplyMentorRequest({ self.Data.Id }, function()
        XUiManager.TipText("MentorShipBuildSendHint")
        self:Close()
    end)
end

-- 解除师徒关系
function XUiPlayerInfo:OnBtnDisconnectClick()
    if not self.Data then return end
    local hintStr = ""
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local lastLoginTime = mentorData:GetMenberLastLoginTimeById(self.Data.Id)
    local IsOverTime = XDataCenter.MentorSystemManager.JudgeFailPassTime(lastLoginTime)

    local IsCanGraduatLevel = self:CheckIsCanGraduatLevel(mentorData)
    if IsCanGraduatLevel then
        if IsOverTime then
            hintStr = "MentorDoGraduateFailPassHint"
        else
            hintStr = "MentorDoGraduateHint"
        end
    else
        if IsOverTime then
            hintStr = "MentorDoMentorShipDisconnectFailPassHint"
        else
            hintStr = "MentorDoMentorShipDisconnectHint"
        end
    end
    self:TipDialog(nil, function()
        XDataCenter.MentorSystemManager.TickMentorRequest(self.Data.Id, function()
            XUiManager.TipText("MentorShipDisconnectHint")
            self:Close()
        end)
    end, hintStr)
end

--拉黑
function XUiPlayerInfo:OnBtnBlockClick()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialFriend) then
        XUiManager.TipText("FunctionNotOpen")
        return
    end

    if XDataCenter.SocialManager.GetBlackData(self.Data.Id) then
        XUiManager.TipText("SocialBlackEnterOver")
        return
    end

    local content = CS.XTextManager.GetText("SocialBlackTipsDesc")
    local sureCallback = function()
        local cb = function()
            self:UpdateInfo(self.Tab.BaseInfo)
        end
        XDataCenter.SocialManager.RequestBlackPlayer(self.Data.Id, cb)
    end
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiPlayerInfo:CheckIsCanGraduatLevel(mentorData)
    local IsCanGraduatLevel = false
    if mentorData:IsTeacher() then
        IsCanGraduatLevel = self.Data.Level >= XMentorSystemConfigs.GetMentorSystemData("GraduateLv")
    elseif mentorData:IsStudent() then
        IsCanGraduatLevel = XPlayer.Level >= XMentorSystemConfigs.GetMentorSystemData("GraduateLv")
    end
    return IsCanGraduatLevel
end

function XUiPlayerInfo:SetGameObjActive(obj, active)
    if obj then
        obj.GameObject:SetActiveEx(active)
    end
end

function XUiPlayerInfo:ActivePanel(index)
    for _, v in pairs(self.TabPanels) do
        if v.Type == index then
            v.GameObject:SetActiveEx(true)
        else
            v.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPlayerInfo:TipDialog(cancelCb, confirmCb, TextKey)
    XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText(TextKey),
    XUiManager.DialogType.Normal, cancelCb, confirmCb)
end