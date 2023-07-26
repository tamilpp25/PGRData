-- 公会详情界面
local XUiGuildRankingList = XLuaUiManager.Register(XLuaUi, "UiGuildRankingList")
local XUiGridRankItem = require("XUi/XUiGuild/XUiChildItem/XUiGridRankItem")
local TextManager = CS.XTextManager

function XUiGuildRankingList:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self.BtnGuildRankYouku.CallBack = function() self:OnBtnGuildRankYoukuClick() end
    self.BtnGuildRankShenqing.CallBack = function() self:OnBtnGuildRankShenqingClick() end
    self:InitList()
end

function XUiGuildRankingList:OnStart(guildId)
    self.CurGuild = guildId
    self:OnRefresh()
end

function XUiGuildRankingList:OnEnable()
    if XDataCenter.GuildManager.IsGuildTourist() then
        self.BtnGuildRankShenqing.gameObject:SetActiveEx(true)
    elseif XDataCenter.GuildManager.IsJoinGuild() then
        self.BtnGuildRankShenqing.gameObject:SetActiveEx(false)
    else
        self.BtnGuildRankShenqing.gameObject:SetActiveEx(true)
    end
    self.BtnGuildRankYouku.gameObject:SetActiveEx(false)
    -- XEventManager.AddEventListener(XEventId.EVENT_GUILD_NOTICE, self.UpdateGuildInfo, self)
end

function XUiGuildRankingList:OnDisable()
    -- XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_NOTICE, self.UpdateGuildInfo, self)
end

function XUiGuildRankingList:UpdateGuildInfo()
    -- XDataCenter.GuildManager.GetGuildDetails(0, function()
    --     XLuaUiManager.Open("UiGuildMain")
    -- end)
end

function XUiGuildRankingList:SetVistorCount()
    local cur = self.GuildInfo.GuildTouristCount
    local total = self.GuildInfo.GuildTouristMaxCount
    local str = CS.XTextManager.GetText("GuildVistorModeDes", cur,total)
    self.BtnGuildRankYouku:SetNameByGroup(0, str)
end

function XUiGuildRankingList:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.MemberRankList)
    self.DynamicTable:SetProxy(XUiGridRankItem)
    self.DynamicTable:SetDelegate(self)
end

-- 更新数据
function XUiGuildRankingList:OnRefresh()
    self.GuildInfo = XDataCenter.GuildManager.GetVistorGuildDetailsById(self.CurGuild)
    local path = XGuildConfig.GetGuildHeadPortraitIconById(self.GuildInfo.GuildIconId)
    self.RImgGuildIcon:SetRawImage(path)
    self.TxtGuildName.text = self.GuildInfo.GuildName
    self.TxtGuildLevel.text = self.GuildInfo.GuildLevel
    self.TxtGuildLeaderName.text = self.GuildInfo.GuildLeaderName
    self.TxtContributionNumber.text = self.GuildInfo.GuildContributeIn7Days
    self.TxtNoticeText.text = self.GuildInfo.GuildDeclaration
    self.TxtID.text = string.format("%08d",self.CurGuild)
    --人数
    self.TxtGuildNumber.text = CS.XTextManager.GetText("GuildPersonCountDes", self.GuildInfo.GuildMemberCount,self.GuildInfo.GuildMemberMaxCount)
    self:SetVistorCount()
    self:OnRefreshList()
end

function XUiGuildRankingList:GetRankName(rankLevel)
    if not self.GuildInfo or not self.GuildInfo.DecodeRankNames then return "" end
    local rankName = self.GuildInfo.DecodeRankNames[rankLevel]
    if rankName == nil or rankName == "" then
        local rankTemplate = XGuildConfig.GetGuildPositionById(rankLevel)
        if rankTemplate then
            return rankTemplate.Name
        end
        return ""
    else
        return rankName
    end
end

-- 更新列表
function XUiGuildRankingList:OnRefreshList()
    local data = XDataCenter.GuildManager.GetVistorMemberList(self.CurGuild) or {}
    self.ListData = {}
    if next(data) then
        for _,v in pairs(data) do
            table.insert(self.ListData, v)
        end
        self:SortMemberList()
        self.DynamicTable:SetDataSource(self.ListData)
        self.DynamicTable:ReloadDataASync()
    else
        XDataCenter.GuildManager.GetVistorGuildMembers(self.CurGuild,function()
            data = XDataCenter.GuildManager.GetVistorMemberList(self.CurGuild) or {}
            for _,v in pairs(data) do
                table.insert(self.ListData, v)
            end
            self:SortMemberList()
            self.DynamicTable:SetDataSource(self.ListData)
            self.DynamicTable:ReloadDataASync()
        end)
    end
end

function XUiGuildRankingList:SortMemberList()
    table.sort(self.ListData, function(memberA, memberB)
        if memberA.RankLevel == memberB.RankLevel then
            if memberA.OnlineFlag == memberB.OnlineFlag then
                if memberA.ContributeIn7Days == memberB.ContributeIn7Days then
                    return memberA.Level > memberB.Level
                end
                return memberA.ContributeIn7Days > memberB.ContributeIn7Days
            end
            return memberA.OnlineFlag > memberB.OnlineFlag
        end
        return memberA.RankLevel < memberB.RankLevel
    end)
end

function XUiGuildRankingList:OnBtnBackClick()
    self:Close()
end

function XUiGuildRankingList:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildRankingList:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", TextManager.GetText("GuildDetailsDes") or "")
end

function XUiGuildRankingList:OnBtnGuildRankYoukuClick()
    if XDataCenter.GuildManager.IsGuildTourist() then
        XUiManager.TipText("GuildNowVistorModeTips")
        return
    end
    local curguildId = self.CurGuild
    if XDataCenter.GuildManager.IsFullGuildVistor(curguildId) then
        local text = TextManager.GetText("GuildFullVistorGuildDes")
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end


    XDataCenter.GuildManager.GuildTouristRequest(self.CurGuild,function ()
        XLuaUiManager.Open("UiGuildVistor")
        self:Close()
    end)
end

function XUiGuildRankingList:OnBtnGuildRankShenqingClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
        return
    end

    local guidId = self.CurGuild
    if XDataCenter.GuildManager.IsFullGuild(guidId) then
        local text = TextManager.GetText("GuildFullVistorGuildDes")
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    XDataCenter.GuildManager.ApplyToJoinGuildRequest(guidId,function()
        self:Close()
        XUiManager.TipText("GuildApplyRequestSuccess")
    end)
end

function XUiGuildRankingList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        if not data then
            return
        end
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnMemberItemClick(index)
    end
end

function XUiGuildRankingList:OnMemberItemClick(index)
    local data = self.ListData[index]
    if not data then return end

    if data.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(data.Id)
    end
end