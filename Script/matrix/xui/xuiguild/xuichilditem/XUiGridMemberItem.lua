local XUiPlayerLevel = require("XUi/XUiCommon/XUiPlayerLevel")
local XUiGridMemberItem = XClass(nil, "XUiGridMemberItem")

function XUiGridMemberItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.CanSet = false

    self.BtnDismiss.gameObject:SetActiveEx(false)
    self.BtnDis.CallBack = function() self:OnBtnDismissClick() end
    self.BtnKickOut.CallBack = function() self:OnBtnKickOut() end
    self.BtnChangePosition.CallBack = function() self:OnBtnChangePosition() end
    self.BtnSet.CallBack = function() self:OnBtnSet() end
end

function XUiGridMemberItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridMemberItem:SetMemberInfo(memberInfo, selectIndex)
    self.MemberInfo = memberInfo
    self.IsSetPanel = memberInfo.IsSetPanel
    self.Index = memberInfo.Index
    self:UpdateGuildInfo()
    local setBtnStatus = (selectIndex and self.Index == selectIndex)
    if self.CanSet then
        self.BtnSet:SetButtonState(setBtnStatus and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    if self.IsSetPanel then
        -- self.PanelMemberInfo.gameObject:SetActiveEx(true)
        self.PanelMemberSet.gameObject:SetActiveEx(true)
    else
        -- self.PanelMemberInfo.gameObject:SetActiveEx(true)
        self.PanelMemberSet.gameObject:SetActiveEx(false)
    end
    
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(memberInfo.Id, memberInfo.Name)
    XUiPlayerLevel.UpdateLevel(memberInfo.Level, self.TextLv, CS.XTextManager.GetText("GuildMemberLevel", memberInfo.Level))
    local jobName = XDataCenter.GuildManager.GetRankNameByLevel(memberInfo.RankLevel)
    self.TxtJob.text = jobName
    self.TxtContribution.text = memberInfo.ContributeAct or 0
    self.TxtHistoryContribution.text = memberInfo.ContributeHistory or 0
    if memberInfo.OnlineFlag == 1 then
        self.TxtLastLogin.text = CS.XTextManager.GetText("GuildMemberOnline")
    else
        self.TxtLastLogin.text = XUiHelper.CalcLatelyLoginTime(memberInfo.LastLoginTime)
    end
    self:UpdateDissmissState(self.MemberInfo)
    XUiPlayerHead.InitPortrait(memberInfo.HeadPortraitId, memberInfo.HeadFrameId, self.Head)
    local isPlayer = memberInfo.Id == XPlayer.Id

    self.LayoutNode:SetDirty()
end

function XUiGridMemberItem:UpdateDissmissState(memberInfo)
    if not memberInfo then return end

    local hasImpeach = XDataCenter.GuildManager.HasImpeachLeader()
    local canImpeach = XDataCenter.GuildManager.CanImpeachLeader()
    local isLeaderMyself = XDataCenter.GuildManager.IsGuildLeader()
    local memberIsLeader = memberInfo.RankLevel == XGuildConfig.GuildRankLevel.Leader
    local showDis = canImpeach and not hasImpeach and not isLeaderMyself and memberIsLeader
    self.BtnDis.gameObject:SetActiveEx(showDis)
    self.PanelJob.gameObject:SetActiveEx(not showDis)
end

function XUiGridMemberItem:UpdateMemberJobInfo(memberInfo)
    self.TxtJob.text = XDataCenter.GuildManager.GetRankNameByLevel(memberInfo.RankLevel)
end

function XUiGridMemberItem:OnBtnDismissClick()
    if self:CheckKickOut() then return end
    self.DissmissCallBack = function()
        XDataCenter.GuildManager.GuildImpeachLeader(function()
            XDataCenter.GuildManager.SetImpeachLeader()
            self:UpdateDissmissState(self.MemberInfo)
        end)
    end
    XLuaUiManager.Open("UiGuildAsset", self.DissmissCallBack)
end

function XUiGridMemberItem:UpdateGuildInfo()
    -- 管理级别大于该成员则设置按钮可用：更换职位、踢出公会
    self:ResetGuildBtns()
    if not self.MemberInfo then return end
    local targetRankLevel = self.MemberInfo.RankLevel
    local isAdministor = XDataCenter.GuildManager.IsGuildAdminister()
    local myRankLevel = XDataCenter.GuildManager.GetCurRankLevel()
    local myGuildId = XDataCenter.GuildManager.GetGuildId()
    if isAdministor then
        self.BtnSet.gameObject:SetActiveEx(true)
        if targetRankLevel ~= nil and targetRankLevel > 0  and myRankLevel < targetRankLevel then
            self.CanSet = true
            self.BtnKickOut.gameObject:SetActiveEx(true)
            self.BtnChangePosition.gameObject:SetActiveEx(true)
            self.BtnSet:SetButtonState(CS.UiButtonState.Normal)
        else
            self.CanSet = false
            self.BtnSet:SetButtonState(CS.UiButtonState.Disable)
        end
    end
end

function XUiGridMemberItem:ResetGuildBtns()
    self.BtnSet.gameObject:SetActiveEx(false)
    self.BtnKickOut.gameObject:SetActiveEx(false)
    self.BtnChangePosition.gameObject:SetActiveEx(false)
end


function XUiGridMemberItem:OnBtnKickOut()
    -- 中途被踢出公会
    if self:CheckKickOut() then return end
    -- 职位变更
    if self:HasModifyGuildAccess() then return end

    local title = CS.XTextManager.GetText("GuildDialogKickMemberTitle")
    local content = CS.XTextManager.GetText("GuildIsKickMember")

    --判断工会战是否开启 如果开启 置换踢出提示
    if XDataCenter.GuildWarManager.CheckActivityIsInTime() then
        content = CS.XTextManager.GetText("GuildIsKickMemberInGuildWarTime")
    end
    
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        XDataCenter.GuildManager.GuildKickMember(self.MemberInfo.Id, function()
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickMemberSuccess"))
        end)
    end)
end

function XUiGridMemberItem:OnBtnChangePosition()
    -- 中途被踢出公会
    if self:CheckKickOut() then return end
    -- 职位变更
    if self:HasModifyGuildAccess() then return end
    -- 是否有更换职位的权利
    local memberList = XDataCenter.GuildManager.GetMemberList()
    local memberInfo = memberList[self.MemberInfo.Id]
    if memberInfo then
        RunAsyn(function()
            XLuaUiManager.Open("UiGuildChangePosition", XGuildConfig.TipsType.ChangePosition, memberInfo)
            local signalCode, targetMemberInfo = XLuaUiManager.AwaitSignal("UiGuildChangePosition", "Close", self)
            if signalCode ~= XSignalCode.SUCCESS then return end
            self.MemberInfo = targetMemberInfo
            local jobName = XDataCenter.GuildManager.GetRankNameByLevel(self.MemberInfo.RankLevel)
            self.TxtJob.text = jobName
        end)
        
    end
end

function XUiGridMemberItem:OnBtnSet()
    if not self.CanSet then return end
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_MEMBER_SET ,self.Index)
end

function XUiGridMemberItem:CheckKickOut()
    -- 中途被踢出公会
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return true
    end
    return false
end

function XUiGridMemberItem:HasModifyGuildAccess()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return true
    end
    return false
end

return XUiGridMemberItem