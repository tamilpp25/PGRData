---@class XUiPanelRogueSimSettle : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimSettlement
local XUiPanelRogueSimSettle = XClass(XUiNode, "XUiPanelRogueSimSettle")

function XUiPanelRogueSimSettle:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.Grid256New.gameObject:SetActiveEx(false)
    ---@type XUiGridCommon[]
    self.GridRewardList = {}
    self.GridData.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridDataList = {}
    self:InitGrid()
end

function XUiPanelRogueSimSettle:Refresh()
    self.SettleData = self._Control:GetStageSettleData()
    if XTool.IsTableEmpty(self.SettleData) then
        XLog.Error("error: SettleData is nil")
        return
    end
    self:RefreshData()
    self:RefreshReward()
end

function XUiPanelRogueSimSettle:InitGrid()
    local params = self._Control:GetClientConfigParams("SettlementDataContent")
    for index, data in pairs(params) do
        local grid = self.GridDataList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridData, self.ListData)
            self.GridDataList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtDataTitle").text = data
        grid:GetObject("TxtDataNum").text = 0
        grid:GetObject("TxtRewardNum").text = 0
    end
    -- 总分
    self.TxtNumber.text = 0
end

function XUiPanelRogueSimSettle:RefreshData()
    -- 数据
    local data = self:GetData()
    -- 总分为0时不播放动画
    if not XTool.IsNumberValid(self.SettleData.Point) then
        self:RefreshDataNum(data)
        return
    end
    -- 播放音效
    self.AudioInfo = XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.UiSettle_Win_Number, XSoundManager.SoundType.Sound)
    local time = XUiHelper.GetClientConfig("BossSingleAnimaTime", XUiHelper.ClientConfigType.Float)
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        -- 数据
        for index, v in pairs(data) do
            local grid = self.GridDataList[index]
            if grid then
                local count = XMath.ToMinInt(v.Count * f)
                grid:GetObject("TxtDataNum").text = self._Control:ConvertNumToK(count)
                local score = XMath.ToMinInt(v.Score * math.max(0, count - v.Extra))
                grid:GetObject("TxtRewardNum").text = score
            end
        end
        -- 总分
        self.TxtNumber.text = XMath.ToMinInt(self.SettleData.Point * f)
    end, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:StopAudio()
        XLuaUiManager.SetMask(false)
    end)
end

-- 直接刷新数据
function XUiPanelRogueSimSettle:RefreshDataNum(data)
    -- 数据
    for index, v in pairs(data) do
        local grid = self.GridDataList[index]
        if grid then
            grid:GetObject("TxtDataNum").text = XMath.ToMinInt(v.Count)
            grid:GetObject("TxtRewardNum").text = XMath.ToMinInt(v.Score * math.max(0, v.Count - v.Extra))
        end
    end
    -- 总分
    self.TxtNumber.text = XMath.ToMinInt(self.SettleData.Point)
end

function XUiPanelRogueSimSettle:GetData()
    return {
        -- 获取金币
        [1] = {
            Count = self.SettleData.AccumulateGoldCount,
            Score = self._Control:GetActivitySettlePointPerGold(),
            Extra = 0,
        },
        -- 主城等级
        [2] = {
            Count = self.SettleData.MainLevel,
            Score = self._Control:GetActivitySettlePointPerMainLevel(),
            Extra = 1,
        },
        -- 建造建筑
        [3] = {
            Count = self.SettleData.BuildingCount,
            Score = self._Control:GetActivitySettlePointPerBuilding(),
            Extra = 0,
        },
        -- 探索城邦
        [4] = {
            Count = self.SettleData.CityCount,
            Score = self._Control:GetActivitySettlePointPerCity(),
            Extra = 0,
        },
        -- 完成事件
        [5] = {
            Count = self.SettleData.FinishedEventCount,
            Score = self._Control:GetActivitySettlePointPerEvent(),
            Extra = 0,
        },
        -- 获取道具
        [6] = {
            Count = self.SettleData.PropCount,
            Score = self._Control:GetActivitySettlePointPerProp(),
            Extra = 0,
        },
    }
end

function XUiPanelRogueSimSettle:RefreshReward()
    local rewardList = self.SettleData.RewardGoodsList or {}
    local coinCount = self.SettleData.AwardCoinCount
    if XTool.IsNumberValid(coinCount) then
        local reward = XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.RogueSimCoin, coinCount)
        table.insert(rewardList, 1, reward)
    end
    self.TxtEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(rewardList))
    local rewardsNum = #rewardList
    for i = 1, rewardsNum do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelRewardList)
            grid = XUiGridCommon.New(self.Parent, go)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimSettle:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiPanelRogueSimSettle:OnBtnCloseClick()
    self.Parent:Close()
end

return XUiPanelRogueSimSettle
