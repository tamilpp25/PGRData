local XUiGridReward = require("XUi/XUiKillZone/XUiKillZoneReward/XUiGridReward")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiKillZoneReward = XLuaUiManager.Register(XLuaUi, "UiKillZoneReward")

function XUiKillZoneReward:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridTreasureGrade.gameObject:SetActiveEx(false)
end

function XUiKillZoneReward:OnStart(diff)
    self.Diff = diff

    self.TxtTreasureTitle.text = XKillZoneConfigs.GetStarRewardTitleByDiff(diff)
end

function XUiKillZoneReward:OnEnable()
    self:UpdateRewards()
end

function XUiKillZoneReward:OnGetEvents()
    return {
        XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE,
    }
end

function XUiKillZoneReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE then
        self:UpdateRewards()
    end
end

function XUiKillZoneReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetProxy(XUiGridReward)
    self.DynamicTable:SetDelegate(self)
end

function XUiKillZoneReward:UpdateRewards()
    self.RewardIds = XKillZoneConfigs.GetAllStarRewardIdsByDiff(self.Diff)

    local selectIndex

    --若有奖励可领取时，则按钮任务排列顺序，优先滑动至序号id较小的可领取奖励的任务处
    local minCanGetIndex
    for index, starRewardId in ipairs(self.RewardIds) do
        if XDataCenter.KillZoneManager.IsStarRewardCanGet(starRewardId)
        and not XDataCenter.KillZoneManager.IsStarRewardObtained(starRewardId)
        then
            minCanGetIndex = index
            break
        end
    end

    --若无奖励可领取时，则自动下滑至当前星数距离星级数目要求最少的任务处
    if not minCanGetIndex then
        local curStar = XDataCenter.KillZoneManager.GetTotalStageStarByDiff(self.Diff)
        for index = #self.RewardIds, 1, -1 do
            local starRewardId = self.RewardIds[index]
            local star = XKillZoneConfigs.GetStarRewardStar(starRewardId)
            if curStar >= star then
                break
            end

            selectIndex = index
        end
    else
        selectIndex = minCanGetIndex
    end

    self.DynamicTable:SetDataSource(self.RewardIds)
    self.DynamicTable:ReloadDataASync(selectIndex)
end

function XUiKillZoneReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.RewardIds[index]
        grid:Refresh(rewardId, self.Diff)
    end
end

function XUiKillZoneReward:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnClose.CallBack = function() self:Close() end
end