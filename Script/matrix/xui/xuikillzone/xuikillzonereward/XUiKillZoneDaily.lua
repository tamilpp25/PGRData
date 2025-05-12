local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridDailyReward = require("XUi/XUiKillZone/XUiKillZoneReward/XUiGridDailyReward")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiKillZoneDaily = XLuaUiManager.Register(XLuaUi, "UiKillZoneDaily")

function XUiKillZoneDaily:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridDailyReward.gameObject:SetActiveEx(false)
end

function XUiKillZoneDaily:OnStart()
    self.TxtTips.text = CsXTextManagerGetText("KillZoneDailyRewardTips")
end

function XUiKillZoneDaily:OnEnable()
    self:UpdateRewards()
end

function XUiKillZoneDaily:OnGetEvents()
    return {
        XEventId.EVENT_KILLZONE_DAILYSTARREWARDINDEX_CHANGE,
    }
end

function XUiKillZoneDaily:OnNotify(evt, ...)
    if evt == XEventId.EVENT_KILLZONE_DAILYSTARREWARDINDEX_CHANGE then
        self:UpdateRewards()
    end
end

function XUiKillZoneDaily:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SView)
    self.DynamicTable:SetProxy(XUiGridDailyReward)
    self.DynamicTable:SetDelegate(self)
end

function XUiKillZoneDaily:UpdateRewards()
    self.RewardIds = XDataCenter.KillZoneManager.GetAllDailyStarRewardIds()

    local currentId, selectIndex = 0, -1

    local yesterdayStar = XDataCenter.KillZoneManager.GetYesterdayStar()
    for index, id in pairs(self.RewardIds) do
        if yesterdayStar == XKillZoneConfigs.GetDailyStarRewardStar(id) then
            currentId, selectIndex = id, index
            break
        end
    end

    if not XTool.IsNumberValid(currentId) then
        XLog.Error("XUiKillZoneDaily:UpdateRewards error: 找不到当前星级对应奖励配置, yesterdayStar: ", yesterdayStar.." ,配置路径: " .. XKillZoneConfigs.GetDailyStarRewardConfigPath())
        return
    end

    self.DynamicTable:SetDataSource(self.RewardIds)
    self.DynamicTable:ReloadDataASync(selectIndex)

    self.GridReward = self.GridReward or XUiGridDailyReward.New(self.GridDailyRewardBottom)
    self.GridReward:InitRootUi(self)
    self.GridReward:RefreshCommon(currentId)

    local hasGot = XDataCenter.KillZoneManager.IsDailyStarRewardObtained()
    self.BtnReceive:SetDisable(hasGot, not hasGot)
end

function XUiKillZoneDaily:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.RewardIds[index]
        grid:Refresh(rewardId)
    end
end

function XUiKillZoneDaily:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
    self.BtnReceive.CallBack = handler(self, self.OnClickBtnReceive)
end

function XUiKillZoneDaily:OnClickBtnReceive()
    local cb = function(rewardGoods)
        if not XTool.IsTableEmpty(rewardGoods) then
            XUiManager.OpenUiObtain(rewardGoods)
        end
    end
    XDataCenter.KillZoneManager.KillZoneTakeDailyStarRewardRequest(cb)
end