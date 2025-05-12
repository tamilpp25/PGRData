local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildRecommendation = XLuaUiManager.Register(XLuaUi, "UiGuildRecommendation")
local XUiGridRecommendationItem = require("XUi/XUiGuild/XUiChildItem/XUiGridRecommendationItem")
local RefreshTime = 1000
local Dropdown = CS.UnityEngine.UI.Dropdown
local GuildAllLevels
local GuildLevelConfig = {}
local ShowGuildRecommendHelp = "ShowGuildRecommendHelp"
local NowTime = XTime.GetServerNowTimestamp

function XUiGuildRecommendation:OnAwake()
    self.CurRecordIds = {}
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    GuildAllLevels = CS.XTextManager.GetText("GuildAllLevels")
    self:InitList()
    self:InitFun()
end

function XUiGuildRecommendation:OnDestroy()
    XDataCenter.GuildManager.ResetGuildRecommendDatas()
end

function XUiGuildRecommendation:InitFun()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnRanking.CallBack = function() self:OnBtnRankingClick() end
    self.BtnRefresh.CallBack = function() self:OnBtnRefreshClick() end
    self.BtnSearchOffice.CallBack = function() self:OnBtnSearchOfficeClick() end
    self.BtnEstablish.CallBack = function() self:OnBtnEstablishClick() end
    self.BtnEstablish:SetDisable(XTool.IsNumberValid(XDataCenter.GuildManager.CheckBuildGuild()))
    self.BtnNews.CallBack = function() self:OnBtnNewsClick() end
    self.BtnApply.CallBack = function() self:OnBtnApplyClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildRecommendHelp")
    local optionsDataList = Dropdown.OptionDataList()
    local optionDataContribute = Dropdown.OptionData()
    GuildLevelConfig[0] = XGuildConfig.GuildSortType.SortByContribute
    optionDataContribute.text = CS.XTextManager.GetText("GuildSortByContribute")
    optionsDataList.options:Add(optionDataContribute)

    local optionLevel = Dropdown.OptionData()
    GuildLevelConfig[1] = XGuildConfig.GuildSortType.SortByLevel
    optionLevel.text = CS.XTextManager.GetText("GuildSortByLevel")
    optionsDataList.options:Add(optionLevel)
    self.DrdSort:AddOptions(optionsDataList.options)
    self.DrdSort.onValueChanged:AddListener(function(index)
        if self.CurIndex == index then
            return
        end
        self.CurIndex = index
        self:RefreshSelectedPanel(index)
    end)
    self.CurIndex = 0
    self.RefreshTimerCb = function() self:RefreshTimerFun() end
    self:OnRefresh()

    self:AddRedPointEvent(self.RedNews, self.OnCheckGuildRecruitList, self, { XRedPointConditions.Types.CONDITION_GUILD_NEWS })
end

function XUiGuildRecommendation:OnCheckGuildRecruitList(count)
    self.RedNews.gameObject:SetActiveEx(count >= 0)
end

function XUiGuildRecommendation:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridRecommendationItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiGuildRecommendation:OnStart()
    self.CooldownTimeStamp = XDataCenter.GuildManager.GetGuildJoinCdEnd()
    self:UpdateCoolDownTimer()
    self.FirstRefresh = true
    --首次进入展示帮助
    if not XSaveTool.GetData(ShowGuildRecommendHelp) then
        -- 引导状态下不需要显示
        if not XDataCenter.GuideManager.CheckIsInGuide() then
            XSaveTool.SaveData(ShowGuildRecommendHelp, true)
            XUiManager.ShowHelpTip("GuildRecommendHelp")
        end
    end
end

function XUiGuildRecommendation:OnEnable()
    self.CoolDownTimeScheduleId = XScheduleManager.ScheduleForever(function()
        self:UpdateCoolDownTimer()
    end, 1000)
end

function XUiGuildRecommendation:OnDisable()
    self:UnScheduleCoolDownTime()
    self.CurRecordIds = {}
    XDataCenter.GuildManager.RecordGuildRecommend(-1)
end

function XUiGuildRecommendation:OnBtnBackClick()
    self:Close()
end

function XUiGuildRecommendation:OnBtnApplyClick()
    -- 如果已经加入公会
    if XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildAlreadyInGuild"))
        return
    end

    if self.RemainTime > 0 then
        XUiManager.TipCode(XCode.GuildApplyInCd)
        return
    end

    for _, item in pairs(self.DynamicTable:GetGrids())do
        if item and item.ItemData then
            XDataCenter.GuildManager.ApplyToJoinGuildRequest(item.ItemData.GuildId, function() 
                item:SetApplyTag(true) 
            end)
        end
    end

    XUiManager.TipText("GuildApplyRequestSuccess")
end

function XUiGuildRecommendation:RecordSeleId(id)
    if id then
        self.CurRecordIds[id] = id
    end
end

function XUiGuildRecommendation:RemoveRecordSeleId(id)
    if id and self.CurRecordIds[id] then
        self.CurRecordIds[id] = nil
    end
end
function XUiGuildRecommendation:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildRecommendation:OnBtnRankingClick()
    XDataCenter.GuildManager.GuildListRankRequest(XGuildConfig.GuildSortType.SortByContribute, function()
        XLuaUiManager.Open("UiGuildRankingListSwitch")
    end)
end

function XUiGuildRecommendation:OnBtnRefreshClick()
    if self.FirstRefresh then
        XDataCenter.GuildManager.ResetPreRequestRecommendTime()
        self.FirstRefresh = false
    end
    if not XDataCenter.GuildManager.IsNeedRequestRecommendData() then 
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildRecommendInCd"))
        return 
    end

    self.CurPage = self.CurPage + 1
    local data = XDataCenter.GuildManager.GetGuildRecommendDatas(self.CurPage)
    if not data or not next(data) then
        self.CurPage = 1
        data = XDataCenter.GuildManager.GetGuildRecommendDatas(self.CurPage)
    end
    self.ListData = data
    self.RawListData = self.ListData
    self.CurDataLen = #self.ListData
    self:RefreshItems(self.CurIndex)

end

function XUiGuildRecommendation:RefreshTimerFun()
    self.IsDelayIng = false
    XScheduleManager.UnSchedule(self.RefreshTimer)
end

function XUiGuildRecommendation:OnBtnSearchOfficeClick()
    if self.CurRefreshIndex == self.CurIndex then
        if self.IsDelayIng then
            return
        end
    end

    self.RefreshTimer = XScheduleManager.ScheduleOnce(self.RefreshTimerCb,RefreshTime)
    self.IsDelayIng = true
    local str = self.InputField.text
    local id = tonumber(str)
    if str == "" or string.Utf8Len(str) ~= 8 or (not id) then
        XUiManager.TipText("GuildRecommErrorTipsDes",XUiManager.UiTipType.Wrong)
        return
    end
    self.CurRefreshIndex = self.CurIndex
    XDataCenter.GuildManager.GuildFind(id, function()
        local datas = XDataCenter.GuildManager.GetGuildFindDatas(id)
        if #datas <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildSearchGuildNotFound"))
        end
        self.ListData = datas
        self.DynamicTable:SetDataSource(datas)
        self.DynamicTable:ReloadDataASync(1)
    end)
end

--===========================================================================
--v1.28 公会创建优化：是否开启创建功能判定
--===========================================================================
function XUiGuildRecommendation:OnBtnEstablishClick()
    local conditionId = XDataCenter.GuildManager.CheckBuildGuild()
    if XTool.IsNumberValid(conditionId) then
        XUiManager.TipError(XConditionManager.GetConditionDescById(conditionId))
    else
        XLuaUiManager.Open("UiGuildBuild")
    end
end

function XUiGuildRecommendation:OnBtnNewsClick()
    XDataCenter.GuildManager.ResetGuildRecruit()
    XDataCenter.GuildManager.GuildListRecruitRequest(function()
        XLuaUiManager.Open("UiGuildNews")
    end)
end

function XUiGuildRecommendation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        if not data then
            return
        end
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClickStatus()
        local data = self.ListData[index]
        XDataCenter.GuildManager.GetVistorGuildDetailsReq(data.GuildId,function ()
            XLuaUiManager.Open("UiGuildRankingList",data.GuildId)
        end)
    end
end

function XUiGuildRecommendation:RefreshSelectedPanel(index)
    self:RefreshItems(index)
end
function XUiGuildRecommendation:RefreshItems(index)
    local type = GuildLevelConfig[index]
    self:FiltrateListData(type)
end

function XUiGuildRecommendation:FiltrateListData(type)

    if type == XGuildConfig.GuildSortType.SortByContribute then
        table.sort(self.RawListData, function(raw1, raw2)
            if raw1.ContributeIn7Days == raw2.ContributeIn7Days then
                if raw1.Level == raw2.Level then
                    return raw1.Id < raw2.Id
                end
                return raw1.Level > raw2.Level
            end
            return raw1.ContributeIn7Days > raw2.ContributeIn7Days
        end)
    end

    if type == XGuildConfig.GuildSortType.SortByLevel then
        table.sort(self.RawListData, function(raw1, raw2)
            if raw1.Level == raw2.Level then
                if raw1.ContributeIn7Days == raw2.ContributeIn7Days then
                    return raw1.Id < raw2.Id
                end
                return raw1.ContributeIn7Days > raw2.ContributeIn7Days
            end
            return raw1.Level > raw2.Level
        end)
    end

    self.ListData = self.RawListData
    self.DynamicTable:Clear()
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync()
end

-- 更新数据
function XUiGuildRecommendation:OnRefresh()
    self.CurPage = 1
    self.ListData = XDataCenter.GuildManager.GetGuildRecommendDatas(self.CurPage)
    self.RawListData = self.ListData
    self.CurDataLen = #self.ListData
    self:RefreshSelectedPanel(self.CurIndex or 0)
end

--更新冷却时间
function XUiGuildRecommendation:UpdateCoolDownTimer()
    if XTool.UObjIsNil(self.TxtCoolDownTime) then return end
    self.RemainTime = self.CooldownTimeStamp - NowTime()
    if self.RemainTime <= 0 then
        self:UnScheduleCoolDownTime()
    end
    self.PanelTimeCd.gameObject:SetActiveEx(self.RemainTime > 0)
    self.TxtCoolDownTime.text = XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.GUILDCD)
end


function XUiGuildRecommendation:UnScheduleCoolDownTime()
    if self.CoolDownTimeScheduleId then
        XScheduleManager.UnSchedule(self.CoolDownTimeScheduleId)
        self.CoolDownTimeScheduleId = nil
    end
end
