local XUiGuildMainInfo = XClass(nil, "XUiGuildMainInfo")

function XUiGuildMainInfo:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildMainInfo:UpdateMainInfo()
    self.TxtMemberCount.text = string.format("%s/%s", tostring(XDataCenter.GuildManager.GetMemberCount()), tostring(XDataCenter.GuildManager.GetMemberMaxCount()))
    self.TextLvNum.text = XDataCenter.GuildManager.GetGuildLevel()
end

function XUiGuildMainInfo:OnEnable()
    self.GameObject:SetActiveEx(true)
    self.GuildId = XDataCenter.GuildManager.GetGuildId()

    self.ImgGuildIcon:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
    self.TxtLeader.text = XDataCenter.GuildManager.GetGuildLeaderName()
    self.TxtMemberCount.text = string.format("%s/%s", tostring(XDataCenter.GuildManager.GetMemberCount()), tostring(XDataCenter.GuildManager.GetMemberMaxCount()))
    self.TextLvNum.text = XDataCenter.GuildManager.GetGuildLevel()
    self.TextInfo.text = XDataCenter.GuildManager.GetGuildDeclaration()

    self.IconCoin1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildCoin))
    self.IconCoin2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    self.TxtCoin1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    self.TxtCoin2.text = XDataCenter.GuildManager.GetGuildContributeLeft()

    self.BtnWords.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildAdminister())
end

function XUiGuildMainInfo:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildMainInfo:OnViewDestroy()

end

function XUiGuildMainInfo:InitChildView()
    XDataCenter.ItemManager.AddCountUpdateListener(XGuildConfig.GuildCoin, function()
        self.TxtCoin1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    end, self.TxtCoin1)

    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
    self.BtnDynamic.CallBack = function() self:OnBtnDynamicClick() end
    self.BtnRanking.CallBack = function() self:OnBtnRankingClick() end
    self.BtnWords.CallBack = function() self:OnBtnWordsClick() end
end

function XUiGuildMainInfo:RefreshGuildContribute()
    self.TxtCoin2.text = XDataCenter.GuildManager.GetGuildContributeLeft()
end


function XUiGuildMainInfo:OnBtnAddClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end

    XLuaUiManager.Open("UiBuyAsset", XGuildConfig.GuildContributeCoin, function()
    end)
end

function XUiGuildMainInfo:OnBtnDynamicClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end

    XLuaUiManager.Open("UiGuildLog")
end

function XUiGuildMainInfo:OnBtnRankingClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end

    XDataCenter.GuildManager.GuildListRankRequest(function()
        XLuaUiManager.Open("UiGuildRankingListSwitch")
    end)
end

function XUiGuildMainInfo:OnBtnWordsClick()
    -- 中途被踢出公会
    if self:ChecKickOut() then
        return
    end
    -- 职位变更
    if self:HasModifyAccess() then
        return
    end

    XLuaUiManager.Open("UiGuildInformation", XGuildConfig.InformationType.Announcement, function()
        self.TextInfo.text = XDataCenter.GuildManager.GetGuildDeclaration()    
    end)
end

function XUiGuildMainInfo:HasModifyAccess()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
        return true
    end
    return false
end

function XUiGuildMainInfo:ChecKickOut()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return true
    end
    return false
end

return XUiGuildMainInfo