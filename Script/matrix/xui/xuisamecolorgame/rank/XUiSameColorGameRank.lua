local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSameColorRankGrid = require("XUi/XUiSameColorGame/Rank/XUiSameColorRankGrid")
local XUiSameColorPanelSkillDetail = require("XUi/XUiSameColorGame/PopTip/XUiSameColorPanelSkillDetail")

---@class XUiSameColorGameRank:XLuaUi
---@field _Control XSameColorControl
local XUiSameColorGameRank = XLuaUiManager.Register(XLuaUi, "UiFubenSameColorGameRank")

local RankType = {
    Total = 0,
    Boss = 1,
}

function XUiSameColorGameRank:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.BossManager = self.SameColorGameManager.GetBossManager()
    self.CurrentRankList = nil
    self.CurrentMyRankInfo = nil
    self.CurrentRankType = nil
    self.CurrentBosses = nil
    self.CurrentTabIndex = 1
    
    self:InitRankList()
    self:InitPanelAsset()
    self:InitSkillDetail()
    self:AddBtnListener()
    self:AddEventListener()
end

function XUiSameColorGameRank:OnStart(rankList, myRankInfo)
    self.CurrentRankType = RankType.Total
    self.CurrentRankList = rankList
    self.CurrentMyRankInfo = myRankInfo
    self.CurrentBosses = self.BossManager:GetBosses(true)
    self.CurrentTabIndex = 1
    
    self:InitRankTags()
    self:RefreshMyRankInfo(self.CurrentMyRankInfo)
    self:RefreshRankList(self.CurrentRankList)
    self:InitAutoClose()
end

function XUiSameColorGameRank:OnDisable()
    self:RemoveEventListener()
end

--region Ui - AutoClose
function XUiSameColorGameRank:InitAutoClose()
    --local endTime = self.SameColorGameManager.GetEndTime()
    --self:SetAutoCloseInfo(endTime, function(isClose)
    --    if isClose then
    --        self.SameColorGameManager.HandleActivityEndTime()
    --    end
    --end)
end
--endregion

--region Ui - PanelAsset
function XUiSameColorGameRank:InitPanelAsset()
    --local itemIds = self._Control:GetCfgAssetItemIds()
    --XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelAsset, self, nil , function(uiSelf, index)
    --    local itemId = itemIds[index]
    --    XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
    --end)
end
--endregion

--region Ui - SkillDetail
function XUiSameColorGameRank:InitSkillDetail()
    self.UiPanelSkillDetail = XUiSameColorPanelSkillDetail.New(self.PanelPopup)
end

---@param skill XSCRoleSkill
function XUiSameColorGameRank:OpenSkillDetail(skill)
    self.UiPanelSkillDetail:Open()
    self.UiPanelSkillDetail:SetData(XTool.Clone(skill))
end
--endregion

--region Ui - RankTag
function XUiSameColorGameRank:InitRankTags()
    self.BtnRankTag:SetNameByGroup(0, XUiHelper.GetText("SCRankTotalName"))
    local btnTabList = { self.BtnRankTag }
    local bosses = self.CurrentBosses
    local go, xUiButton, boss
    for i = 1, #bosses do
        boss = bosses[i]
        go = CS.UnityEngine.Object.Instantiate(self.BtnRankTag, self.PanelTag.transform)
        xUiButton = go.transform:GetComponent("XUiButton")
        xUiButton:SetNameByGroup(0, boss:GetName())
        table.insert(btnTabList, xUiButton)
    end
    self.PanelTag:Init(btnTabList, function(index)
        self:OnBtnTagClicked(index)
    end)
    self.PanelTag:SelectIndex(self.CurrentTabIndex)
end

function XUiSameColorGameRank:OnBtnTagClicked(index)
    if index == self.CurrentTabIndex then return end
    self.CurrentTabIndex = index
    local bossId = 0
    if index > 1 then
        bossId = self.CurrentBosses[index - 1]:GetId()
    end
    self.SameColorGameManager.RequestRankData(bossId, function(rankList, myRankInfo)
        self:RefreshMyRankInfo(myRankInfo)
        self:RefreshRankList(rankList)
    end)
    self:PlayAnimation("QieHuan")
end
--endregion

--region Ui - RankList
function XUiSameColorGameRank:InitRankList()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiSameColorRankGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridPlayerRank.gameObject:SetActiveEx(false)
end

function XUiSameColorGameRank:RefreshRankList(rankList)
    local index = 1
    if self.CurrentMyRankInfo.Rank <= XEnumConst.SAME_COLOR_GAME.RANK_MAX_TOP_COUNT then
        index = self.CurrentMyRankInfo.Rank
    end
    self.CurrentRankList = rankList
    self.DynamicTable:SetDataSource(self.CurrentRankList)
    self.DynamicTable:ReloadDataSync(index)
    local isEmpty = #rankList <= 0
    self.PanelNoRank.gameObject:SetActiveEx(isEmpty)
    self.PlayerRankList.gameObject:SetActiveEx(not isEmpty)
end

---@param grid XUiSameColorRankGrid
function XUiSameColorGameRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.CurrentRankList[index])
    end
end

function XUiSameColorGameRank:RefreshMyRankInfo(rankInfo)
    self.CurrentMyRankInfo = rankInfo
    self.TxtPlayerName.text = rankInfo.Name
    local rank = rankInfo.Rank
    local rankText = rank
    -- 没进入排行
    if rank <= 0 then
        rankText = XUiHelper.GetText("SCRankEmptyText")
    elseif rank > XEnumConst.SAME_COLOR_GAME.RANK_PERCENT_LIMIT then
        local tmp = math.floor((rank / rankInfo.MemberCount) * 100)
        tmp = math.min(math.max(tmp, 1), 99)
        rankText = tmp .. "%"
    end
    self.TxtRank.text = rankText
    self.TxtRankScore.text = rankInfo.Score
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
end
--endregion

--region Ui - BtnListener
function XUiSameColorGameRank:AddBtnListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnMyRank.CallBack = function() self:OnBtnMyRankClicked() end
    self.BtnMyHead.CallBack = function() self:OnBtnMyHeadClicked() end
    self:BindHelpBtn(self.BtnHelp, self._Control:GetCfgHelpId())
end

function XUiSameColorGameRank:OnBtnMyHeadClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.CurrentMyRankInfo.PlayerId)
end

function XUiSameColorGameRank:OnBtnMyRankClicked()
    self.DynamicTable:ReloadDataSync(1)
end
--endregion

--region event
function XUiSameColorGameRank:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_OPEN_SKILL_DETAIL, self.OpenSkillDetail, self)
end

function XUiSameColorGameRank:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_OPEN_SKILL_DETAIL, self.OpenSkillDetail, self)
end
--endregion

return XUiSameColorGameRank