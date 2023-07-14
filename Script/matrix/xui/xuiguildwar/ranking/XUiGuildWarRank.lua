--
local XUiGuildWarRank = XLuaUiManager.Register(XLuaUi, "UiGuildWarRank")
local Tab = require("XUi/XUiGuildWar/Ranking/XUiGuildWarRankTab")
local TabType = {
    First = "BtnFirstHasSnd",
    SecondTop = "BtnSecondTop",
    SecondBottom = "BtnSecondBottom",
    Second = "BtnSecond",
    SecondAll = "BtnSecondAll"
}
local UiButtonState = CS.UiButtonState
function XUiGuildWarRank:OnAwake()
    XTool.InitUiObject(self)
    self:InitTopControl()
    self:InitPanelSpecailTools()
    self:InitRankList()
    self:SetBtnTemplateDisable()
    local endTime = XDataCenter.GuildWarManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.GuildWarManager.OnActivityEndHandler()
            end
        end)
end

function XUiGuildWarRank:SetBtnTemplateDisable()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    self.BtnSecondAll.gameObject:SetActiveEx(false)
end

function XUiGuildWarRank:InitTopControl()
    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControl)
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelp")
end

function XUiGuildWarRank:InitPanelSpecailTools()
    --local actionId = XGuildWarConfig.GetServerConfigValue("ActivityPointItemId")
    --不显示资源栏
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    --[[
    local itemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    }
    self.PanelSpecailTools = XUiHelper.NewPanelActivityAsset(itemIds, self.PanelSpecialTool)]]
end

function XUiGuildWarRank:InitRankList()
    local rankList = require("XUi/XUiGuildWar/Ranking/XUiGuildWarRankingList")
    self.RankList = rankList.New(self.PanelRankList)
end

function XUiGuildWarRank:OnStart(rankingType)
    self:InitComboTab()
    self.TabBtnContent:SelectIndex(rankingType or 1)
    local manager = XDataCenter.GuildWarManager
    local currentRound = manager.GetCurrentRoundId()
    if currentRound > 1 then
        XSaveTool.SaveData("GuildWar" .. manager.GetActivityId() .. manager.GetActvityTimeId() .. XPlayer.Id .. (currentRound - 1), true)
    end
end

function XUiGuildWarRank:InitComboTab()
    self.ComboTabDataList = self:InitComboTabDataList()
    self:CreateComboTab()
end

function XUiGuildWarRank:InitComboTabDataList()
    local dataList = {} -- {[BaseComboId] = {[1] = ComboListIndex…}}
    local typeCfgs = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.RankingType)
    local currentRound = XDataCenter.GuildWarManager.GetCurrentRoundId()
    for _, typeCfg in pairs(typeCfgs) do
        local tabData = {
            TabType = typeCfg.TabType,
            Name = typeCfg.Name,
            TabId = typeCfg.Id,
            FatherTabId = typeCfg.FatherTab,
            RoundId = typeCfg.RoundId or 0,
            RankingTarget = typeCfg.RankingTarget,
            Params = typeCfg.Params,
            IsActive = (not typeCfg.RoundId) or (typeCfg.RoundId == 0) or (currentRound >= typeCfg.RoundId and (not XDataCenter.GuildWarManager.CheckIsSkipRound(typeCfg.RoundId)))
        }
        table.insert(dataList, tabData)
    end
    return dataList
end

function XUiGuildWarRank:CreateComboTab()
    self.TabList = {}
    --self.FirstTabList = {}
    --self.ChildTabList = {}
    self.BtnList = {}
    for i = 1, #self.ComboTabDataList do
        local data = self.ComboTabDataList[i]
        local btnPrefab = XUiHelper.Instantiate(self[data.TabType].gameObject, self.TabBtnContent.transform)
        self.TabList[i] = Tab.New(btnPrefab, self, i, data)
        btnPrefab.gameObject:SetActiveEx(data.TabType == TabType.First)
        self.BtnList[i] = btnPrefab:GetComponent("XUiButton")
        if data.TabType ~= TabType.First then
            self.BtnList[i].SubGroupIndex = data.FatherTabId > 0 and data.FatherTabId
        end
        self.BtnList[i]:SetButtonState(UiButtonState.Normal)
    end
    self.TabBtnContent:Init(self.BtnList, function(index) self.TabList[index]:OnClick() end)
end

function XUiGuildWarRank:RefreshRanking(rankingType, id, rankTarget)
    self.RankList:RefreshList(rankingType, id, rankTarget)
end
--============
--刷新排行榜名
--============
function XUiGuildWarRank:RefreshRankingName(name)
    self.RankList:RefreshName(name)
end

return XUiGuildWarRank