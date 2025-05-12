local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridRogueSimStarLevel = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimStarLevel")
---@class XUiPanelRogueSimSettle : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimSettlement
local XUiPanelRogueSimSettle = XClass(XUiNode, "XUiPanelRogueSimSettle")

function XUiPanelRogueSimSettle:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.PanelTitle.gameObject:SetActiveEx(false)
    self.Grid256New.gameObject:SetActiveEx(false)
    self.GridData.gameObject:SetActiveEx(false)
    ---@type XUiGridCommon[]
    self.GridRewardList = {}
    ---@type UiObject[]
    self.GridDataList = {}
    ---@type XUiGridRogueSimStarLevel
    self.MainStarLevel = false
    self:InitGrid()
end

function XUiPanelRogueSimSettle:Refresh()
    self.SettleData = self._Control:GetStageSettleData()
    if not self.SettleData then
        XLog.Error("SettleData is empty")
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
        grid:GetObject("ListStar").gameObject:SetActiveEx(false)
    end
    -- 总分
    self.TxtNumber.text = 0
    self.ImgNewTag.gameObject:SetActiveEx(false)
end

function XUiPanelRogueSimSettle:RefreshData()
    -- 数据
    local data = self:GetData()
    -- 刷新主城星级(特殊处理)
    self:RefreshMainStarLevel(self.GridDataList[2], data[2])
    -- 总分为0时不播放动画
    if not XTool.IsNumberValid(self.SettleData:GetPoint()) then
        self:RefreshDataNum(data)
        return
    end
    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
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
        self.TxtNumber.text = XMath.ToMinInt(self.SettleData:GetPoint() * f)
    end, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        local stageId = self._Control:GetStageSettleStageId()
        local maxPoint = self._Control:GetStageRecordMaxPoint(stageId)
        local isNewRecord = self.SettleData:GetPoint() >= maxPoint
        self.ImgNewTag.gameObject:SetActiveEx(isNewRecord)
        self:RefreshScoreTitle()
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
    self.TxtNumber.text = XMath.ToMinInt(self.SettleData:GetPoint())
    self:RefreshScoreTitle()
end

function XUiPanelRogueSimSettle:GetData()
    return {
        -- 获取金币
        [1] = {
            Count = self.SettleData:GetAccumulateGoldCount(),
            Score = self._Control:GetActivitySettlePointPerGold(),
            Extra = 0,
        },
        -- 主城等级
        [2] = {
            Count = self.SettleData:GetMainLevel(),
            Score = self._Control:GetActivitySettlePointPerMainLevel(),
            Extra = 1,
        },
        -- 建造建筑(自建)
        [3] = {
            Count = self.SettleData:GetBuildingCount(),
            Score = self._Control:GetActivitySettlePointPerBuilding(),
            Extra = 0,
        },
        -- 城邦总星级数
        [4] = {
            Count = self.SettleData:GetCityLevel(),
            Score = self._Control:GetActivitySettlePointPerCity(),
            Extra = 0,
        },
        -- 完成事件
        [5] = {
            Count = self.SettleData:GetFinishedEventCount(),
            Score = self._Control:GetActivitySettlePointPerEvent(),
            Extra = 0,
        },
        -- 解锁区域
        [6] = {
            Count = self.SettleData:GetUnlockAreaCount(),
            Score = self._Control:GetActivitySettlePointPerArea(),
            Extra = 0,
        },
    }
end

function XUiPanelRogueSimSettle:RefreshReward()
    local rewardList = {}
    -- 螺母
    local nutCount = self.SettleData:GetAwardNutCount()
    if XTool.IsNumberValid(nutCount) then
        local reward = XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.Coin, nutCount)
        table.insert(rewardList, 1, reward)
    end
    -- 代币
    local coinCount = self.SettleData:GetAwardCoinCount()
    if XTool.IsNumberValid(coinCount) then
        local reward = XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.RogueSimCoin, coinCount)
        table.insert(rewardList, 1, reward)
    end
    local goodsList = self.SettleData:GetRewardGoodsList()
    for _, goods in pairs(goodsList) do
        table.insert(rewardList, goods)
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

-- 刷新主城等级星级
function XUiPanelRogueSimSettle:RefreshMainStarLevel(grid, data)
    if self.MainStarLevel then
        return
    end
    grid:GetObject("TxtDataNum").gameObject:SetActiveEx(false)
    self.MainStarLevel = XUiGridRogueSimStarLevel.New(grid:GetObject("ListStar"), self)
    self.MainStarLevel:Open()
    -- 结算时特殊处理只显示点亮的星级 isMaxLevel默认设置为true
    self.MainStarLevel:Refresh(data.Count, true)
end

-- 刷新分数称号
function XUiPanelRogueSimSettle:RefreshScoreTitle()
    local config = self._Control:GetScoreTitleConfigByScore(self.SettleData:GetPoint())
    if not config then
        self.PanelTitle.gameObject:SetActiveEx(false)
        return
    end
    self.PanelTitle.gameObject:SetActiveEx(true)
    self.TxtTitle.text = config.Content
    self.ImgBg:SetSprite(config.BgIcon)
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
