---@class XUiTaikoMasterRank:XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterRank = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterRank")
local MAX_RANK_COUNT = 100 --最多显示的排名数

function XUiTaikoMasterRank:OnStart()
    self._Control:UpdateUiData()
    self._SelectedSongId = false
    ---@type XTaikoMasterRankUiData[]
    self._RankArray = false
    self._RankDynamicTable = false
    self._FlowTextArray = {}
    self:InitRankDynamicTable()
    self:InitBtnTag()
    self:InitPanelAsset()
    self:InitAutoClose()
    self:AddBtnListener()
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

--region Ui - AutoClose
function XUiTaikoMasterRank:InitAutoClose()
    local uiData = self._Control:GetUiData()
    self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(uiData and uiData.TimeId), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end
--endregion

--region Ui - PanelAsset
function XUiTaikoMasterRank:InitPanelAsset()
    if self.PanelSpecialTool then
        self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.Coin }, self.PanelSpecialTool, self)
    end
end
--endregion

--region Ui - RankSongText
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

function XUiTaikoMasterRank:StopAllFlowText()
    for i = 1, #self._FlowTextArray do
        for j, flowText in ipairs(self._FlowTextArray[i]) do
            flowText:Stop()
        end
    end
end
--endregion

--region Ui - Rank
function XUiTaikoMasterRank:InitBtnTag()
    local songArray = self:GetTabDataProvider()
    local btnTabList = {self.BtnTab01}
    for i = 1, #songArray do
        local btnTag = btnTabList[i] or CS.UnityEngine.Object.Instantiate(self.BtnTab01, self.BtnTab01.transform.parent)
        local uiButton = XUiHelper.TryGetComponent(btnTag.transform, "", "XUiButton")
        local uiData = self._Control:GetUiData()
        local songId = songArray[i]
        local songName = uiData.SongUiDataDir[songId].Name
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
    return self._Control:GetUiData().SongIdList
end

function XUiTaikoMasterRank:RefreshRank()
    local uiData = self._Control:GetUiData()
    if uiData.RankDataDir[self._SelectedSongId] then
        self._RankArray = uiData.RankDataDir[self._SelectedSongId].RankPlayerInfoList
    else
        self._RankArray = {}
    end
    self._RankDynamicTable:SetDataSource(self._RankArray)
    local isEmpty = #self._RankArray <= 0
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

function XUiTaikoMasterRank:RefreshMyRank()
    local songId = self._SelectedSongId
    local uiData = self._Control:GetUiData()
    local rankData = uiData.RankDataDir[songId]
    self.TextMyName.text = XPlayer.Name
    local myRank = rankData and rankData.MyRank or 0
    local rankText = myRank
    -- 没进入排行
    if myRank <= 0 then
        rankText = XUiHelper.GetText("SCRankEmptyText")
    elseif myRank > MAX_RANK_COUNT then
        local rankPlayerAmount = rankData.TotalCount
        local percent = math.floor((myRank / rankPlayerAmount) * 100)
        percent = math.min(math.max(percent, 1), 99)
        rankText = string.format("%d%%", percent)
    end

    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TextMyRankPercent.text = rankText
    self.TextMyScore.text = XUiHelper.GetText("TaikoMasterScore", uiData.SongHardPlayDataDir[songId].MyScore)
    self.TextMyCombo.text = XUiHelper.GetText("TaikoMasterCombo", uiData.SongHardPlayDataDir[songId].MyComboUnderMaxScore)
    self.TextMyAccuracy.text = XUiHelper.GetText("TaikoMasterAccuracy", uiData.SongHardPlayDataDir[songId].MyAccuracyUnderMaxScore)
end

function XUiTaikoMasterRank:SetSongSelected(songId)
    if songId == self._SelectedSongId then
        return
    end
    self._SelectedSongId = songId
    self._Control:RequestRankData(songId, function()
        self:RefreshRank()
        self:RefreshMyRank()
    end)
end

function XUiTaikoMasterRank:InitRankDynamicTable()
    self._RankDynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self._RankDynamicTable:SetProxy(require("XUi/XUiTaikoMaster/XUiTaikoMasterRankGrid"), self)
    self._RankDynamicTable:SetDelegate(self)
    self.GridRank.gameObject:SetActiveEx(false)
end

---@param grid XUiTaikoMasterRankGrid
function XUiTaikoMasterRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self._RankArray[index], self._SelectedSongId)
    end
end
--endregion

--region Ui - BtnListener
function XUiTaikoMasterRank:AddBtnListener()
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
--endregion

return XUiTaikoMasterRank
