local XUiMultiDimTeamRanking = XLuaUiManager.Register(XLuaUi, "UiMultiDimTeamRanking")
local XUiPanelMultiDimRank = require("XUi/XUiMultiDim/XUiPanelMultiDimRank")
local XUiPanelMultiDimRankReward = require("XUi/XUiMultiDim/XUiPanelMultiDimRankReward")
local XUiPanelMultiDimRankList = require("XUi/XUiMultiDim/XUiPanelMultiDimRankList")

local RANK_PANEL_NAME = {
    [1] = "MultiDimTeamSingleRank",
    [2] = "MultiDimTeamMultiRank",
}

local BTN_INDEX = {
    First = 1,
    Second = 2,
}

local RANK_MODEL_INDEX ={
    [1] = "SINGLE_RANK",
    [2] = "TEAM_RANK",
}

function XUiMultiDimTeamRanking:OnAwake()
    self:RegisterUiEvents()
    self:InitHideView()
end

function XUiMultiDimTeamRanking:OnStart()
    local itemId = XDataCenter.MultiDimManager.GetActivityItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)

    self:InitView()
    self:InitLeftTabBtn()

    self.MySingleRank = XUiPanelMultiDimRank.New(self.PanelMyBossRank, self)
    self.MyManyRank = XUiPanelMultiDimRank.New(self.PanelManyPeople, self)
    self:HideMyRankPanel()
    
    self.RankReward = XUiPanelMultiDimRankReward.New(self.PanelRankReward, self)
    
    self.TeamRankList = XUiPanelMultiDimRankList.New(self.PanelTeamRankList, self)
    self.SingleRankList = XUiPanelMultiDimRankList.New(self.PanelSingleRankList, self)
    self:HideRankListPanel()

    -- 开启自动关闭检查
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MultiDimManager.HandleActivityEndTime()
        end
    end)
end

function XUiMultiDimTeamRanking:OnEnable()
    self.Super.OnEnable(self)
    local defaultIndex = self:GetDefaultSingleThemeRankIndex()
    self.BtnContent:SelectIndex(defaultIndex)
end

function XUiMultiDimTeamRanking:RefreshRankInfo()
    -- 显示排行信息
    self:SetRankInfo()
    -- 显示我的排行信息
    self:RefreshMyRankInfo()
end

function XUiMultiDimTeamRanking:SetRankInfo()
    self:HideRankListPanel()
    local rankListPanel = self:GetRankListPanel()
    rankListPanel:SetActivePanel(true)
    rankListPanel:Refresh(self.RankType, self.ThemeId)
end

function XUiMultiDimTeamRanking:RefreshMyRankInfo()
    self:HideMyRankPanel()
    local myRankPanel = self:GetMyRankPanel()
    local rankInfo = XDataCenter.MultiDimManager.GetMyRankInfo(self.RankType, self.ThemeId)
    if rankInfo and rankInfo.Rank > 0 then
        myRankPanel:SetActivePanel(true)
        myRankPanel:Refresh(self.RankType, rankInfo)
    end
end

function XUiMultiDimTeamRanking:HideMyRankPanel()
    self.MySingleRank:SetActivePanel(false)
    self.MyManyRank:SetActivePanel(false)
end

function XUiMultiDimTeamRanking:HideRankListPanel()
    self.SingleRankList:SetActivePanel(false)
    self.TeamRankList:SetActivePanel(false)
end

function XUiMultiDimTeamRanking:GetMyRankPanel()
    if self.RankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK then
        return self.MySingleRank
    else
        return self.MyManyRank
    end
end

function XUiMultiDimTeamRanking:GetRankListPanel()
    if self.RankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK then
        return self.SingleRankList
    else
        return self.TeamRankList
    end
end

function XUiMultiDimTeamRanking:RefreshRankView()
    local isSingleRank = self.RankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK
    -- 排行奖励按钮
    if self.BtnRankReward then
        self.BtnRankReward.gameObject:SetActiveEx(isSingleRank)
    end
    -- 更新提示
    self.Refresh.gameObject:SetActiveEx(isSingleRank)
    self.RefreshTips.gameObject:SetActiveEx(not isSingleRank)
    -- Top
    local topName = isSingleRank and "SingleRankTopNun" or "MultiRankTopNun"
    self.TopTxt.text = XMultiDimConfig.GetMultiDimConfigValue(topName)
end

function XUiMultiDimTeamRanking:InitView()
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    -- 结束时间
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM/dd HH:mm")
    self.TxtCurTime.text = CSXTextManagerGetText("MultiDimTeamSettleRankTip", endTimeStr)
end

function XUiMultiDimTeamRanking:InitHideView()
    self.GridBossRank.gameObject:SetActiveEx(false)  -- 个人排行
    self.ManyPeople.gameObject:SetActiveEx(false) -- 多人排行
    
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    
    self.TxtIos.gameObject:SetActiveEx(false)
end

function XUiMultiDimTeamRanking:InitLeftTabBtn()
    self.BtnTabList = {}
    self.RankBtnIndexDic = {}
    local btnIndex = 0
    
    --一级标题
    for i = 1, #RANK_MODEL_INDEX do
        local rankType = XMultiDimConfig.RANK_MODEL[RANK_MODEL_INDEX[i]]
        local btnModel = self:GetCertainBtnModel(BTN_INDEX.First, true)
        local firstGo = XUiHelper.Instantiate(btnModel, self.BtnContent.transform)
        local firstBtn = firstGo:GetComponent("XUiButton")
        firstBtn.gameObject:SetActiveEx(true)
        local rankName = CSXTextManagerGetText(RANK_PANEL_NAME[rankType])
        firstBtn:SetNameByGroup(0, rankName)
        table.insert(self.BtnTabList, firstBtn)
        btnIndex = btnIndex + 1

        --二级标题
        local firstIndex = btnIndex
        local themeIds = XDataCenter.MultiDimManager.GetThemeAllId()
        for index, themeId in pairs(themeIds) do
            local tmpBtnModel = self:GetCertainBtnModel(BTN_INDEX.Second, nil, index, #themeIds)
            local secondGo = XUiHelper.Instantiate(tmpBtnModel, self.BtnContent.transform)
            local secondBtn = secondGo:GetComponent("XUiButton")
            secondBtn.gameObject:SetActiveEx(true)
            -- 主题名称
            local themeName = XDataCenter.MultiDimManager.GetThemeNameById(themeId)
            secondBtn:SetNameByGroup(0, themeName)
            secondBtn.SubGroupIndex = firstIndex
            table.insert(self.BtnTabList, secondBtn)
            btnIndex = btnIndex + 1

            local indexInfo = {
                RankType = rankType,
                ThemeId = themeId
            }
            self.RankBtnIndexDic[btnIndex] = indexInfo
        end
    end

    self.BtnContent:Init(self.BtnTabList, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiMultiDimTeamRanking:OnClickTabCallBack(tabIndex)
    if self.CurrentTabIndex and self.CurrentTabIndex == tabIndex then
        return
    end

    self.CurrentTabIndex = tabIndex
    local rankBtnIndexInfo = self.RankBtnIndexDic[tabIndex]
    self.RankType = rankBtnIndexInfo.RankType
    self.ThemeId = rankBtnIndexInfo.ThemeId
    -- 刷新排行界面信息
    self:RefreshRankView()
    -- 获取排行信息
    XDataCenter.MultiDimManager.MultiDimOpenRankRequest(self.RankType, self.ThemeId, function()
        self:RefreshRankInfo()
    end)
    -- 播放动画
    self:PlayAnimation("QieHuan")
end

function XUiMultiDimTeamRanking:GetCertainBtnModel(index, hasChild, pos, totalNum)
    if index == BTN_INDEX.First then
        if hasChild then
            return self.BtnFirstHasSnd
        else
            return self.BtnFirst
        end
    elseif index == BTN_INDEX.Second then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end

function XUiMultiDimTeamRanking:GetDefaultSingleThemeRankIndex()
    -- 默认选中上一次挑战过的主题（多人or单人均计算在内）。无记录时，首次打开定位至首个
    local tempThemeId = XDataCenter.MultiDimManager.GetDefaultActivityThemeId()
    -- 默认打开个人排行榜
    local singleIndex = 1
    if XTool.IsNumberValid(tempThemeId) then
        for index, info in pairs(self.RankBtnIndexDic) do
            if info.RankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK and info.ThemeId == tempThemeId then
                singleIndex = index
            end
        end
    end
    return singleIndex
end

function XUiMultiDimTeamRanking:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRankReward, self.OnBtnRankRewardClick)
    self:BindHelpBtn(self.BtnHelp, "MultiDimMain")
end

function XUiMultiDimTeamRanking:OnBtnBackClick()
    self:Close()
end

function XUiMultiDimTeamRanking:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
-- 排行奖励
function XUiMultiDimTeamRanking:OnBtnRankRewardClick()
    local rankInfo = XDataCenter.MultiDimManager.GetMyRankInfo(self.RankType, self.ThemeId)
    if not rankInfo then
        self.RankReward:Refresh(self.ThemeId, 0, 0)
    else
        self.RankReward:Refresh(self.ThemeId, rankInfo.Rank, rankInfo.MemberCount)
    end
end

return XUiMultiDimTeamRanking