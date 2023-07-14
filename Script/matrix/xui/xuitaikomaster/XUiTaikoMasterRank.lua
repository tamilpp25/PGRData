local XUiTaikoMasterRank = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterRank")
local MAX_RANK_COUNT = 100 --最多显示的排名数

function XUiTaikoMasterRank:Ctor()
    self._SelectedSongId = false
    self._RankArray = false
    self._RankDynamicTable = false
    self.BtnMyRank = false
    self.BtnMyHead = false
    self._FlowTextArray = {}
end

function XUiTaikoMasterRank:OnAwake()
    self._RankDynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self._RankDynamicTable:SetProxy(require("XUi/XUiTaikoMaster/XUiTaikoMasterRankGrid"), self)
    self._RankDynamicTable:SetDelegate(self)
    self:RegisterButtonClick()
end

function XUiTaikoMasterRank:OnStart()
    self.GridRank.gameObject:SetActiveEx(false)
    local panelAsset = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    local item = XDataCenter.ItemManager.ItemId.Coin
    XDataCenter.ItemManager.AddCountUpdateListener(
        item,
        function()
            panelAsset:Refresh({item})
        end,
        panelAsset
    )
    panelAsset:Refresh({item})

    self:InitBtnTag()
    self:SetAutoCloseInfo(
        XDataCenter.TaikoMasterManager.GetActivityEndTime(),
        function(isClose)
            if isClose then
                XDataCenter.TaikoMasterManager.HandleActivityEnd()
            end
        end
    )
end

function XUiTaikoMasterRank:OnEnable()
    XUiTaikoMasterRank.Super.OnEnable(self)
    XEventManager.AddEventListener(XEventId.EVENT_TAIKO_MASTER_RANK_UPDATE, self.OnRankDataUpdated, self)
end

function XUiTaikoMasterRank:OnDisable()
    XUiTaikoMasterRank.Super.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TAIKO_MASTER_RANK_UPDATE, self.OnRankDataUpdated, self)
end

function XUiTaikoMasterRank:OnDestroy()
    self:StopAllFlowText()
    self._FlowTextArray = {}
end

function XUiTaikoMasterRank:StopAllFlowText()
    for i = 1, #self._FlowTextArray do
        for j, flowText in ipairs(self._FlowTextArray[i]) do
            flowText:Stop()
        end
    end
end

function XUiTaikoMasterRank:OnRankDataUpdated(songId)
    if self._SelectedSongId == songId then
        self:RefreshRank()
        self:RefreshMyRank()
    end
end

function XUiTaikoMasterRank:GetFirstSongId()
    return self:GetTabDataProvider()[1]
end

function XUiTaikoMasterRank:GetTabDataProvider()
    return XDataCenter.TaikoMasterManager.GetRankSongArray()
end

function XUiTaikoMasterRank:MakeTextFlow(childButton)
    local mask = XUiHelper.TryGetComponent(childButton, "TxtMask", "RectTransform")
    local text = XUiHelper.TryGetComponent(childButton, "TxtMask/Txt", "Text")
    local XUiTaikoMasterFlowText = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")
    local flowText = XUiTaikoMasterFlowText.New(text, mask)
    return flowText
end

function XUiTaikoMasterRank:MakeBtnTextFlow(uiButton)
    local flowText1 = self:MakeTextFlow(uiButton.NormalObj.transform)
    local flowText2 = self:MakeTextFlow(uiButton.PressObj.transform)
    local flowText3 = self:MakeTextFlow(uiButton.SelectObj.transform)
    self._FlowTextArray[#self._FlowTextArray + 1] = {flowText1, flowText2, flowText3}
end

function XUiTaikoMasterRank:InitBtnTag()
    local songArray = self:GetTabDataProvider()
    local btnTabList = {self.BtnTab01}
    for i = 1, #songArray do
        local btnTag = btnTabList[i] or CS.UnityEngine.Object.Instantiate(self.BtnTab01, self.BtnTab01.transform.parent)
        local uiButton = XUiHelper.TryGetComponent(btnTag.transform, "", "XUiButton")
        local songId = songArray[i]
        local songName = XDataCenter.TaikoMasterManager.GetSongName(songId)
        uiButton:SetNameByGroup(0, songName)
        btnTabList[i] = uiButton
        self:MakeBtnTextFlow(uiButton)
    end
    self.PanelTask:Init(
        btnTabList,
        function(index)
            self:StopAllFlowText()
            local songId = songArray[index]
            self:SetSongSelected(songId)
            local flowTextArray = self._FlowTextArray[index]
            if flowTextArray then
                for j, flowText in ipairs(flowTextArray) do
                    flowText:Play()
                end
            end
        end
    )
    self.PanelTask:SelectIndex(1, true)
end

function XUiTaikoMasterRank:RefreshRank()
    local rankDataProvider = XDataCenter.TaikoMasterManager.GetRankList(self._SelectedSongId)
    self._RankArray = rankDataProvider
    self._RankDynamicTable:SetDataSource(rankDataProvider)
    local isEmpty = #rankDataProvider <= 0
    self.PanelNoRank.gameObject:SetActiveEx(isEmpty)
    self.PanelRankingList.gameObject:SetActiveEx(not isEmpty)
    if not self:SetMyRankSelected() then
        self:SetRankSelected(1)
    end
end

function XUiTaikoMasterRank:SetMyRankSelected()
    local myRankIndex = false
    if myRankIndex then
        self:SetRankSelected(myRankIndex)
        return true
    end
    return false
end

function XUiTaikoMasterRank:SetRankSelected(rankIndex)
    self._RankDynamicTable:ReloadDataSync(rankIndex)
end

function XUiTaikoMasterRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self._RankArray[index], self._SelectedSongId)
    end
end

function XUiTaikoMasterRank:RefreshMyRank()
    local songId = self._SelectedSongId
    self.TextMyName.text = XPlayer.Name
    local myRank = XDataCenter.TaikoMasterManager.GetMyRanking(songId)
    local rankText = myRank
    -- 没进入排行
    if myRank <= 0 then
        rankText = XUiHelper.GetText("SCRankEmptyText")
    elseif myRank > MAX_RANK_COUNT then
        local rankPlayerAmount = XDataCenter.TaikoMasterManager.GetRankPlayerAmount(songId)
        local percent = math.floor((myRank / rankPlayerAmount) * 100)
        percent = math.min(math.max(percent, 1), 99)
        rankText = string.format("%d%%", percent)
    end
    self.TextMyRankPercent.text = rankText
    self.TextMyScore.text =
        XUiHelper.GetText("TaikoMasterScore", XDataCenter.TaikoMasterManager.GetMyScoreBySong(songId))
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TextMyCombo.text =
        XUiHelper.GetText("TaikoMasterCombo", XDataCenter.TaikoMasterManager.GetMyComboUnderMaxScore(songId))
    self.TextMyAccuracy.text =
        XUiHelper.GetText("TaikoMasterAccuracy", XDataCenter.TaikoMasterManager.GetMyAccuracyUnderMaxScore(songId))
end

function XUiTaikoMasterRank:SetSongSelected(songId)
    if songId == self._SelectedSongId then
        return
    end
    self._SelectedSongId = songId
    self:RefreshRank()
    self:RefreshMyRank()
    XDataCenter.TaikoMasterManager.RequestRankData(songId)
end

function XUiTaikoMasterRank:RegisterButtonClick()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    -- self.BtnMyRank.CallBack = function()
    --     self:OnBtnMyRankClicked()
    -- end
    -- self.BtnMyHead.CallBack = function()
    --     self:OnBtnMyHeadClicked()
    -- end
end

function XUiTaikoMasterRank:OnBtnMyHeadClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.CurrentMyRankInfo.PlayerId)
end

function XUiTaikoMasterRank:OnBtnMyRankClicked()
    self._RankDynamicTable:ReloadDataSync(1)
end

return XUiTaikoMasterRank
