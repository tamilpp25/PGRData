-- 公会排行榜界面
local XUiGuildRankingListSwitch = XLuaUiManager.Register(XLuaUi, "UiGuildRankingListSwitch")
local XUiGridRankingListSwitchItem = require("XUi/XUiGuild/XUiChildItem/XUiGridRankingListSwitchItem")
local TextManager = CS.XTextManager
local Dropdown = CS.UnityEngine.UI.Dropdown
local GuildSortConfig = {}
local LastReqTime = {}

function XUiGuildRankingListSwitch:OnAwake()
    self:InitEvent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local optionsDataList = Dropdown.OptionDataList()

    local optionContribute = Dropdown.OptionData()
    optionsDataList.options:Add(optionContribute)
    optionContribute.text = CS.XTextManager.GetText("GuildSortByContribute")
    
    local optionLevel = Dropdown.OptionData()
    optionsDataList.options:Add(optionLevel)
    optionLevel.text = CS.XTextManager.GetText("GuildSortByLevel")

    self.DrdSort:AddOptions(optionsDataList.options)

    GuildSortConfig[0] = XGuildConfig.GuildSortType.SortByContribute
    GuildSortConfig[1] = XGuildConfig.GuildSortType.SortByLevel
    LastReqTime[XGuildConfig.GuildSortType.SortByContribute] = 0
    LastReqTime[XGuildConfig.GuildSortType.SortByLevel] = 0

    self.CurSortIndex = 0
    self:InitList()
end

function XUiGuildRankingListSwitch:InitEvent()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildRecommendHelp")
    -- 右侧公会的查看详情按钮
    self.BtnGuildRankYouku.CallBack = function() self:OnBtnGuildRankYoukuClick() end
    self.BtnGuildRankShenqing.CallBack = function() self:OnBtnGuildRankShenqingClick() end

    self.DrdSort.onValueChanged:AddListener(function(index)
        if self.CurSortIndex == index then
            return
        end
        self.CurSortIndex = index
        self:RefreshSelectedPanel(self.CurSortIndex)
    end)
end

function XUiGuildRankingListSwitch:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.MemberRankList)
    self.DynamicTable:SetProxy(XUiGridRankingListSwitchItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiGuildRankingListSwitch:OnStart()    
    XDataCenter.GuildManager.GuildListRankRequest(XGuildConfig.GuildSortType.SortByContribute, function()
        XDataCenter.GuildManager.SaveMyGuildCurRank(XGuildConfig.GuildSortType.SortByContribute)
        self:OnRefreshList()
    end)

    if not XDataCenter.GuildManager.IsJoinGuild() or XDataCenter.GuildManager.IsGuildTourist() then
        self.BtnGuildRankShenqing.gameObject:SetActiveEx(true)
    else
        self.BtnGuildRankShenqing.gameObject:SetActiveEx(false)
    end
end

function XUiGuildRankingListSwitch:OnRefreshBaseData(guildId, rank, iconId)
    self.CurGuildId = guildId
    local data = XDataCenter.GuildManager.GetVistorGuildDetailsById(guildId)
    if data then
        -- 保持两边头像相同（采用排行榜数据）
        data.GuildIconId = iconId or data.GuildIconId
        self:OnSetRefreshInfo(data, rank)
    else
        XDataCenter.GuildManager.GetVistorGuildDetailsReq(guildId, function()
            local guildData = XDataCenter.GuildManager.GetVistorGuildDetailsById(guildId)
            -- 保持两边头像相同（采用排行榜数据）
            if guildData and guildData.GuildIconId then
                 guildData.GuildIconId = iconId or guildData.GuildIconId
             end
            self:OnSetRefreshInfo(guildData, rank)
        end)
    end
end

function XUiGuildRankingListSwitch:OnSetRefreshInfo(data, rank)
    if self.ListData and #self.ListData > 0 then
        for i = 1, #self.ListData do
            local data = self.ListData[i]
            data.IsSelect = rank == i
            local grid = self.DynamicTable:GetGridByIndex(i)
            if grid then
                grid:SetSelect(data.IsSelect)
                -- XLog.Warning("OnSetRefreshInfo", rank, i, data)
            end
        end
    end

    if data then
        --公会名字
        self.TxtGuildlName.text = data.GuildName
        --公会等级
        self.TxtGuildLevel.text = data.GuildLevel
        --会长名字
        self.TxtLeaderName.text = data.GuildLeaderName
        --公告
        self.TxtNoticeText.text = data.GuildDeclaration
        --公会头像
        local path = XGuildConfig.GetGuildHeadPortraitIconById(data.GuildIconId)
        self.ImgIcon:SetRawImage(path)
    end
end

function XUiGuildRankingListSwitch:UpdateMyGuildView()
    -- 右侧默认展示第一名信息
    local info = self.ListData[1]
    if info and info.GuildId then
        self:OnRefreshBaseData(info.GuildId, 1)
    end
    -- 底部
    local type = GuildSortConfig[self.CurSortIndex]
    local isJoinGuild = XDataCenter.GuildManager.IsJoinGuild()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    self.PanelMyRank.gameObject:SetActiveEx(isJoinGuild)
    if isJoinGuild then
        local curCount = XDataCenter.GuildManager.GetMemberCount()
        local maxCount = XDataCenter.GuildManager.GetMemberMaxCount()
        self.TxtRenShu.text = CS.XTextManager.GetText("GuildPersonCountDes", curCount, maxCount)
        self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
        --贡献
        if type == XGuildConfig.GuildSortType.SortByContribute then
            self.TxtSevenDayScore.text = XDataCenter.GuildManager.GetGuildContributeIn7Days()
        else
            self.TxtSevenDayScore.text = XDataCenter.GuildManager.GetGuildLevel()
        end
        local scoreFromList = nil
        for index, guildData in pairs(self.ListData) do
            if guildData.GuildId == guildId then
                scoreFromList = guildData.Score
            end
        end
        -- 如果服务端有则优先用服务端的(分数)
        if scoreFromList then
            self.TxtSevenDayScore.text = scoreFromList
        end
        -- 排行
        local rank = XDataCenter.GuildManager.GetMyGuildRank(type)
        if rank >= 1 then
            self.TxtRankNormal.text = math.modf(rank)
            self.TxtRankNormal.gameObject:SetActiveEx(true)
            self.TxtNotRankNormal.gameObject:SetActiveEx(false)
        elseif rank > 0 and rank < 1 then
            local rankNum = rank * 100
            self.TxtRankNormal.text = string.format("%0.2f%%",rankNum )
            self.TxtRankNormal.gameObject:SetActiveEx(true)
            self.TxtNotRankNormal.gameObject:SetActiveEx(false)
        else
            self.TxtRankNormal.gameObject:SetActiveEx(false)
            self.TxtNotRankNormal.gameObject:SetActiveEx(true)
        end

        -- 获取上次打开时的排行，与今日对比，决定是否显示以及显示百分比还是名次
        local lastRank = XDataCenter.GuildManager.GetMyGuildLastRank(type) or 0
        --XLog.Warning("type:"..type.."  lastRank:"..lastRank.."  rank:"..rank)
        if lastRank >= 1 and rank >= 1 then
            local deltaRank = lastRank - rank
            if deltaRank <= 0 then
                self.PanelUp.gameObject:SetActiveEx(false)
            else
                self.PanelUp.gameObject:SetActiveEx(true)
                self.TxtUp.text = deltaRank
                self.TxtUp.text = string.format("%d",deltaRank )
            end
        elseif rank > 0 and rank < 1 and lastRank > 0 and lastRank < 1 then
            local deltaRank = lastRank - rank
            if deltaRank <= 0 then
                self.PanelUp.gameObject:SetActiveEx(false)
            else
                self.PanelUp.gameObject:SetActiveEx(true)
                self.TxtUp.text = string.format("%.2f%%",deltaRank * 100 )
            end
        else 
            self.PanelUp.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGuildRankingListSwitch:OnClickItemRefreshInfo(data, rank)
    if data and data.GuildId then
        self:OnRefreshBaseData(data.GuildId, rank, data.IconId)
    end
end

function XUiGuildRankingListSwitch:RefreshSelectedPanel(index)
    -- 重新请求，超时的时候
    local type = GuildSortConfig[index]
    local lastReqTime = LastReqTime[type]
    local now = XTime.GetServerNowTimestamp()
    if now - lastReqTime > XGuildConfig.GuildRequestRankTime then
        -- 重新请求
        XDataCenter.GuildManager.GuildListRankRequest(type, function()
            self.ListData = XDataCenter.GuildManager.GetListRankDatas(type) or {}
            self:CheckNoneRank()
            self.DynamicTable:SetDataSource(self.ListData)
            self.DynamicTable:ReloadDataASync()
            XDataCenter.GuildManager.SaveMyGuildCurRank(type)
            self:UpdateMyGuildView()
        end)
    else
        self.ListData = XDataCenter.GuildManager.GetListRankDatas(type) or {}
        self:CheckNoneRank()
        self.DynamicTable:SetDataSource(self.ListData)
        self.DynamicTable:ReloadDataASync()
        self:UpdateMyGuildView()
    end
    self.TxtMyTitleScore.text = XGuildConfig.GuildSortName[type]
end

-- 更新列表
function XUiGuildRankingListSwitch:OnRefreshList()
    local type = GuildSortConfig[self.CurSortIndex]
    self.ListData = XDataCenter.GuildManager.GetListRankDatas(type) or {}
    self.TxtMyTitleScore.text = XGuildConfig.GuildSortName[type]
    for k, v in pairs(self.ListData) do
        v.IsSelect = false
    end
    self:CheckNoneRank()
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync()
    self:UpdateMyGuildView()
    if not next(self.ListData) then
        self.GuildInformation.gameObject:SetActiveEx(false)
    else
        self.GuildInformation.gameObject:SetActiveEx(true)
    end
end

function XUiGuildRankingListSwitch:CheckNoneRank()
    local isEmpty = #self.ListData <= 0
    if self.ImgEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    end
    if self.NotEmpty then
        self.NotEmpty.gameObject:SetActiveEx(not isEmpty)
    end
end

function XUiGuildRankingListSwitch:OnBtnBackClick()
    self:Close()
end

function XUiGuildRankingListSwitch:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildRankingListSwitch:OnBtnGuildRankYoukuClick()
    XDataCenter.GuildManager.GetVistorGuildDetailsReq(self.CurGuildId, function()
        XLuaUiManager.Open("UiGuildRankingList", self.CurGuildId)
        self:Close()
    end)
end

function XUiGuildRankingListSwitch:OnBtnGuildRankShenqingClick()
    local guidId = self.CurGuildId
    if XDataCenter.GuildManager.IsFullGuild(guidId) then
        local text = TextManager.GetText("GuildFullVistorGuildDes")
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    XDataCenter.GuildManager.ApplyToJoinGuildRequest(guidId, function()
        XUiManager.TipText("GuildApplyRequestSuccess")
    end)
end

function XUiGuildRankingListSwitch:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        if not data then return end
        grid:OnRefresh(data, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        if not data then return end
        self:OnClickItemRefreshInfo(data, index)
    end
end