
local XUiSuperSmashBrosRanking = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosRanking")

function XUiSuperSmashBrosRanking:Ctor()
    self._Career = false
    -- 应策划要求，只显示前4个，且合并3和5
    self._AllCareer = {1, 2, 3, 4}--XMVCA.XCharacter:GetAllCharacterCareerIds()
    self._AllCareerName = {
        XMVCA.XCharacter:GetCareerName(self._AllCareer[1]),
        XMVCA.XCharacter:GetCareerName(self._AllCareer[2]),
        XUiHelper.ReadTextWithNewLine("SuperSmashCareer"),
        XMVCA.XCharacter:GetCareerName(self._AllCareer[4])
    }
end

function XUiSuperSmashBrosRanking:OnStart()
    self:InitBaseBtns() --注册基础按钮
    self:InitPanels() --初始化各子面板
    self:SetActivityTimeLimit() --设置活动关闭时处理
end

function XUiSuperSmashBrosRanking:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
    self.BtnRecord.CallBack = handler(self, self.OnClickBtnRecord)

    local buttonGroup = { self.TabCore }
    local allCareer = self._AllCareer
    local firstCareer = allCareer[1]
    if firstCareer then
        self._Career = firstCareer
    end
    for i = 1, #allCareer - 1 do
        local btn = CS.UnityEngine.Object.Instantiate(self.TabCore, self.TabCore.transform.parent)
        buttonGroup[#buttonGroup + 1] = XUiHelper.TryGetComponent(btn.transform, "", "XUiButton") 
    end
    for i = 1, #allCareer do
        local btn = buttonGroup[i]
        local career = allCareer[i]
        local icon = XUiHelper.GetClientConfig("SuperSmashCareerIcon" .. career, XUiHelper.ClientConfigType.String)
        local name = self._AllCareerName[i]
        btn:SetSprite(icon)
        btn:SetNameByGroup(0, name)
    end
    self.PanelTabCore:Init(buttonGroup, function(groupIndex) self:SetCareer(groupIndex) end)
    self.PanelTabCore:SelectIndex(1)
end
--==============
--主界面按钮
--==============
function XUiSuperSmashBrosRanking:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosRanking:OnClickBtnBack()
    self:Close()
end

function XUiSuperSmashBrosRanking:OnClickBtnRecord()
    XLuaUiManager.Open("UiSuperSmashBrosClearTime")
end

function XUiSuperSmashBrosRanking:InitPanels()
    self:InitDTablePlayerRank()
    self:InitMyRankPanel()
    self.TxtAndroid.gameObject:SetActive(false) --排行榜没有分安卓苹果，这里先隐藏
end

function XUiSuperSmashBrosRanking:InitDTablePlayerRank()
    local script = require("XUi/XUiSuperSmashBros/Ranking/XUiSSBRankingDTable")
    self.RankingList = script.New(self.PlayerRankList, self.PlayerRank, self.PanelNoRank)
end

function XUiSuperSmashBrosRanking:InitMyRankPanel()
    local script = require("XUi/XUiSuperSmashBros/Ranking/XUiSSBRankingGrid")
    self.MyRank = script.New(self.PanelMyRank)
end

function XUiSuperSmashBrosRanking:OnEnable()
    XUiSuperSmashBrosRanking.Super.OnEnable(self)
    self:RefreshRank()
end

--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosRanking:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
            end
        end)
end

function XUiSuperSmashBrosRanking:RefreshRank()
    if not self._Career then
        return
    end
    XDataCenter.SuperSmashBrosManager.GetRankingList(self._Career, function(rankingList)
        rankingList = {}
        self.RankingList:Refresh(rankingList)
        local myData = false
        local index = 0
        for i = 1, #rankingList do
            local data = rankingList[i]
            if data.PlayerId == XPlayer.Id then
                myData = data
                index = i
            end
        end
        if not myData then
            myData = {}
            ---@type XSmashBMode
            local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)
            myData.WinCount = mode:GetWinCount(self._Career)
            myData.SpendTime = mode:GetBestTime(self._Career)
        end
        self.MyRank:Refresh(true, myData, index, self._Career)
    end)
end

function XUiSuperSmashBrosRanking:SetCareer(career)
    if self._Career == career then
        return
    end
    self._Career = career
    self:RefreshRank()
end 