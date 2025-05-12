local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBabelTowerMyRankInfos = require("XUi/XUiFubenBabelTower/XUiBabelTowerMyRankInfos")
local XUiBabelTowerRankReward = require("XUi/XUiFubenBabelTower/XUiBabelTowerRankReward")
local XUiGridRankItemInfo = require("XUi/XUiFubenBabelTower/XUiGridRankItemInfo")
---@class XUiBabelTowerRankInfo
local XUiBabelTowerRankInfo = XClass(nil, "XUiBabelTowerRankInfo")

---@param uiRoot XUiFubenBabelTowerRank
function XUiBabelTowerRankInfo:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    -- 我的排名
    ---@type XUiBabelTowerMyRankInfos
    self.MyRankInfos = XUiBabelTowerMyRankInfos.New(self.PanelMyBossRank, self.UiRoot)
    -- 奖励
    ---@type XUiBabelTowerRankReward
    self.RankReward = XUiBabelTowerRankReward.New(self.PanelRankReward, self.UiRoot)

    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList.gameObject)
    self.DynamicTable:SetProxy(XUiGridRankItemInfo)
    self.DynamicTable:SetDelegate(self)

    self.BtnRankReward.CallBack = function() self:OnBtnRankRewardClick() end
    self.ActivityType = nil

    self.PlayerRank.gameObject:SetActiveEx(false)
    self.BtnRank.gameObject:SetActiveEx(false)

    local rankRefreshDuration = XFubenBabelTowerConfigs.GetActivityConfigValue("RankRefreshDuration")[1]
    -- 刷新时长
    self.RefreshDuration = tonumber(rankRefreshDuration) * 60
    -- 是否正在请求排行榜信息
    self.IsRequestingRank = false
end

function XUiBabelTowerRankInfo:UpdateCurTime(timeStr)
    self.TxtCurTime.text = timeStr
end

function XUiBabelTowerRankInfo:UpdateRefreshTime()
    if not self.TxtRefreshTime or self.IsRequestingRank then
        return
    end
    local rankUpdateTime = XDataCenter.FubenBabelTowerManager.GetRankUpdateTime()
    local endTime = rankUpdateTime + self.RefreshDuration
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime < 0 then
        leftTime = 0
        self:AutoSelectIndex()
    end
    local leftTimeDesc = XUiHelper.GetText("BabelTowerRankRefresh")
    local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtRefreshTime.text = string.format(leftTimeDesc, timeStr)
end

---@param grid XUiGridRankItemInfo
function XUiBabelTowerRankInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankInfos[index]
        if not data then return end
        grid:Refresh(data)
    end
end

function XUiBabelTowerRankInfo:SetActivityType(value)
    self.ActivityType = value
    self.ActivityId = self:GetActivityId()
end

function XUiBabelTowerRankInfo:GetActivityId()
    local curActivityId = 0
    if self.ActivityType == XFubenBabelTowerConfigs.ActivityType.Normal then
        curActivityId = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    elseif self.ActivityType == XFubenBabelTowerConfigs.ActivityType.Extra then
        curActivityId = XDataCenter.FubenBabelTowerManager.GetExtraActivityId()
    end
    return curActivityId
end

function XUiBabelTowerRankInfo:InitRankTag()
    if not XTool.IsNumberValid(self.ActivityId) then
        return
    end
    local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(self.ActivityId)
    if not activityTemplate then
        return
    end
    local btnTags = {}
    self.BtnStageIds = {}
    -- 总榜
    ---@type XUiComponent.XUiButton
    local btnTotal = XUiHelper.Instantiate(self.BtnRank, self.PanelRankTag)
    btnTotal.gameObject:SetActiveEx(true)
    btnTotal:SetNameByGroup(0, XFubenBabelTowerConfigs.GetActivityConfigValue("RankTotalDesc")[1])
    btnTags[1] = btnTotal
    self.BtnStageIds[1] = 0
    -- 关卡榜
    local stageIds = activityTemplate.StageId or {}
    for index, stageId in ipairs(stageIds) do
        local btnRank = XUiHelper.Instantiate(self.BtnRank, self.PanelRankTag)
        btnRank.gameObject:SetActiveEx(true)
        btnRank:SetNameByGroup(0, XFubenBabelTowerConfigs.GetStageName(stageId))
        btnTags[index + 1] = btnRank
        self.BtnStageIds[index + 1] = stageId
    end
    self.PanelRankGroup:Init(btnTags, function(index) self:OnBtnStageTagClick(index) end)
end

function XUiBabelTowerRankInfo:OnBtnStageTagClick(index)
    if self.CurSelectIndex == index then
        return
    end
    self.CurSelectIndex = index
    self.CurSelectStageId = self.BtnStageIds[index]
    -- 请求服务端后再刷新数据
    self.IsRequestingRank = true
    XDataCenter.FubenBabelTowerManager.GetRank(self.ActivityId, self.CurSelectStageId, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.IsRequestingRank = false
        self:Refresh()
    end)
end

function XUiBabelTowerRankInfo:DefaultSelectIndex()
    self.PanelRankGroup:SelectIndex(1)
end

--- 自动刷新选中的关卡
function XUiBabelTowerRankInfo:AutoSelectIndex()
    local index = self.CurSelectIndex or 1
    self.CurSelectIndex = nil
    self.PanelRankGroup:SelectIndex(index)
end

-- 刷新排名
function XUiBabelTowerRankInfo:Refresh()
    self.RankInfos = XDataCenter.FubenBabelTowerManager.GetRankInfos()
    self.DynamicTable:SetDataSource(self.RankInfos)
    self.DynamicTable:ReloadDataASync()
    self.PanelNoRank.gameObject:SetActiveEx(#self.RankInfos <= 0)
    self.TxtIos.gameObject:SetActiveEx(false)

    self.MyRankInfos:Refresh()

    -- 更新奖励按钮
    self.BtnRankReward.gameObject:SetActiveEx(false)
    self.RewardText.gameObject:SetActiveEx(false)
    local activityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    if not activityNo then
        return
    end
    local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(activityNo)
    if not activityTemplate then
        return
    end
    self.BtnRankReward.gameObject:SetActiveEx(activityTemplate.RankType == XFubenBabelTowerConfigs.RankType.RankAndReward)
    self.RewardText.gameObject:SetActiveEx(activityTemplate.RankType == XFubenBabelTowerConfigs.RankType.OnlyRank)
end

function XUiBabelTowerRankInfo:OnBtnRankRewardClick()
    self.RankReward:Refresh()
end

return XUiBabelTowerRankInfo
