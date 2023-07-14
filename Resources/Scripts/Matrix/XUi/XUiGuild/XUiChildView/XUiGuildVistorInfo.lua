local XUiGuildVistorInfo = XClass(nil, "XUiGuildVistorInfo")

function XUiGuildVistorInfo:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self:Init()
end

function XUiGuildVistorInfo:OnEnable()
    self.GameObject:SetActiveEx(true)
    self:OnRefresh()
end

function XUiGuildVistorInfo:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildVistorInfo:Init()
    self.BtnRanking:SetNameByGroup(0,CS.XTextManager.GetText("GuidVistorRankBtnDes"))
    self.BtnApplay:SetNameByGroup(0,CS.XTextManager.GetText("GuidVistorApplyBtnDes"))
    -- self.BtnChannel:SetNameByGroup(0,CS.XTextManager.GetText("GuidVistorChannelBtnDes"))
    self.BtnExit:SetNameByGroup(0,CS.XTextManager.GetText("GuidVistorExitBtnDes"))
    self.IconCoin1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildCoin))
    self.IconCoin2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
    self:InitFun()
end

function XUiGuildVistorInfo:InitFun()
    self.BtnExit.CallBack = function() self:OnBtnExitClick() end
    self.BtnRanking.CallBack = function() self:OnBtnRankingClick() end
    -- self.BtnChannel.CallBack = function() self:OnBtnChannelClick() end
    self.BtnApplay.CallBack = function() self:OnBtnApplayClick() end
    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
    XDataCenter.ItemManager.AddCountUpdateListener(XGuildConfig.GuildCoin, function()
        self.TxtCoin1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    end, self.TxtCoin1)
end

function XUiGuildVistorInfo:OnBtnAddClick()
    XLuaUiManager.Open("UiBuyAsset", XGuildConfig.GuildContributeCoin, function()
    end)
end

function XUiGuildVistorInfo:OnBtnExitClick()
    XDataCenter.GuildManager.GuildQuitTouristRequest(function()
        XDataCenter.GuildManager.QuitVistorClean()
        -- self.UiRoot:Close()
        XLuaUiManager.RunMain()
    end)
end

function XUiGuildVistorInfo:OnBtnRankingClick()
    XDataCenter.GuildManager.GuildListRankRequest(function()
        XLuaUiManager.Open("UiGuildRankingListSwitch")
    end)
end

--申请加入公会
function XUiGuildVistorInfo:OnBtnApplayClick()
    XDataCenter.GuildManager.ApplyToJoinGuildRequest(self.CurguildId,function()
        XUiManager.TipText("GuildApplyRequestSuccess")
    end)
end

function XUiGuildVistorInfo:OnBtnChannelClick()

end

-- 更新数据
function XUiGuildVistorInfo:OnRefresh()
    self.CurguildId = XDataCenter.GuildManager.GetGuildId()
    self:SetData()
end

function XUiGuildVistorInfo:SetData()
    local info = XDataCenter.GuildManager.GetVistorGuildDetailsById(self.CurguildId)
    if info then
        local path = XGuildConfig.GetGuildHeadPortraitIconById(info.GuildIconId)
        self.ImgGuildIcon:SetRawImage(path)
        self.TxtGuildName.text = info.GuildName or ""
        self.TxtLeader.text = info.GuildLeaderName or ""
        self.TxtMemberCount.text = CS.XTextManager.GetText("GuildRankYoukuDes", info.GuildMemberCount,info.GuildMemberMaxCount)
        self.TextLvNum.text = info.GuildLevel or ""
        self.TxtCoin1.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
        self.TxtCoin2.text = info.GuildContributeIn7Days or ""
        --公告
        self.TextInfo.text = info.GuildDeclaration or ""
    end
end

return XUiGuildVistorInfo