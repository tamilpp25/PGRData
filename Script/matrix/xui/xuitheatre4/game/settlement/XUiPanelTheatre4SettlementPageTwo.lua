local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelTheatre4SettlementPageTwo : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4Settlement
local XUiPanelTheatre4SettlementPageTwo = XClass(XUiNode, "XUiPanelTheatre4SettlementPageTwo")

function XUiPanelTheatre4SettlementPageTwo:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnLast, self.OnBtnLastClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridScore.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    -- 冒险结算数据
    ---@type XTheatre4Adventure
    self.AdventureSettleData = self._Control:GetAdventureSettleData()
    ---@type UiObject[]
    self.GridScoreList = {}
    ---@type XUiGridCommon[]
    self.GridRewardList = {}
    self:InitGridScore()
    -- 是否第一次进入
    self.IsFirstEnter = true
end

function XUiPanelTheatre4SettlementPageTwo:Refresh()
    if XTool.IsTableEmpty(self.AdventureSettleData) then
        XLog.Error("AdventureSettleData is nil")
        return
    end
    self.Parent:PlayAnimationWithMask("UiMove", function()
        self:RefreshData()
    end)
    self:RefreshReward()
end

-- 初始化分数
function XUiPanelTheatre4SettlementPageTwo:InitGridScore()
    local params = self._Control:GetClientConfigParams("SettlementDataContent")
    for index, content in pairs(params) do
        local grid = self.GridScoreList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridScore, self.PanelScore)
            self.GridScoreList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtName").text = content
        grid:GetObject("TxtCount").text = 0
        grid:GetObject("TxtScore").text = 0
    end
    -- 总分
    self.TxtPoint.text = 0
    self.TxtMax.gameObject:SetActiveEx(false)
end

-- 刷新数据
function XUiPanelTheatre4SettlementPageTwo:RefreshData()
    local data = self:GetData()
    local totalScore = self:GetTotalScore(data)
    --local isMax = self._Control:GetHistoryMaxScore() <= XMath.ToMinInt(totalScore)
    -- 总分为0或者不是第一次进入则直接刷新数据
    if not XTool.IsNumberValid(totalScore) or not self.IsFirstEnter then
        self:RefreshDataNum(data, totalScore)
        return
    end
    self.IsFirstEnter = false
    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
    local time = XUiHelper.GetClientConfig("BossSingleAnimaTime", XUiHelper.ClientConfigType.Float)
    XLuaUiManager.SetMask(true)
    self:Tween(time, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        for index, v in pairs(data) do
            local grid = self.GridScoreList[index]
            if grid then
                grid:GetObject("TxtCount").gameObject:SetActiveEx(v.Parameter ~= -1)
                if v.Parameter ~= -1 then
                    local count = XMath.ToMinInt(v.Count * f)
                    grid:GetObject("TxtCount").text = count
                    local score = XMath.ToMinInt(count * v.Parameter)
                    score = v.MaxScore > 0 and math.min(score, v.MaxScore) or score
                    grid:GetObject("TxtScore").text = string.format("+%s", score)
                else
                    grid:GetObject("TxtScore").text = string.format("×%s", v.Count)
                end
            end
        end
        -- 总分
        self.TxtPoint.text = XMath.ToMinInt(totalScore * f)
    end, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:RefreshDataNum(data, totalScore)
        self:StopAudio()
        XLuaUiManager.SetMask(false)
    end)
end

-- 直接刷新数据
function XUiPanelTheatre4SettlementPageTwo:RefreshDataNum(data, totalScore)
    for index, v in pairs(data) do
        local grid = self.GridScoreList[index]
        if grid then
            grid:GetObject("TxtCount").gameObject:SetActiveEx(v.Parameter ~= -1)
            if v.Parameter ~= -1 then
                grid:GetObject("TxtCount").text = XMath.ToMinInt(v.Count)
                local score = XMath.ToMinInt(v.Count * v.Parameter)
                score = v.MaxScore > 0 and math.min(score, v.MaxScore) or score
                grid:GetObject("TxtScore").text = string.format("+%s", score)
            else
                grid:GetObject("TxtScore").text = string.format("×%s", v.Count)
            end
        end
    end
    -- 总分
    self.TxtPoint.text = XMath.ToMinInt(totalScore)
    --self.TxtMax.gameObject:SetActiveEx(isMax)
end

---@return { Count:number, Parameter:number, MaxScore:number }[]
function XUiPanelTheatre4SettlementPageTwo:GetData()
    return {
        -- 完成章节
        [1] = {
            Count = self.AdventureSettleData:GetChapterPassCount(),
            Parameter = self:GetChapterNumberParameter(),
            MaxScore = -1,
        },
        -- 繁荣度总值
        [2] = {
            Count = self.AdventureSettleData:GetProsperity(),
            Parameter = self._Control:GetConfig("ProsperityIndexParameter") / XEnumConst.Theatre4.RatioDenominator,
            MaxScore = self._Control:GetEndingMaxProsperity(self.Parent.EndingId),
        },
        -- 翻卡格子数
        [3] = {
            Count = self.AdventureSettleData:GetExploreCount(),
            Parameter = self._Control:GetConfig("CellsOpenedParameter") / XEnumConst.Theatre4.RatioDenominator,
            MaxScore = -1,
        },
        -- 结局倍率
        [4] = {
            Count = self._Control:GetEndingFactor(self.Parent.EndingId),
            Parameter = -1,
            MaxScore = -1,
        },
        -- 难度倍率
        [5] = {
            Count = self._Control:GetDifficultyBPExpRateById(self.AdventureSettleData:GetDifficulty()),
            Parameter = -1,
            MaxScore = -1,
        },
        -- 三星奖励
        [6] = {
            Count = self._Control:GetSettleStarBpExp(),
            Parameter = 1,
            MaxScore = -1,
        },
    }
end

-- 获取章节数参数
function XUiPanelTheatre4SettlementPageTwo:GetChapterNumberParameter()
    local passChapterCount = self.AdventureSettleData:GetChapterPassCount()
    local chapterNumberParameter = 0
    for i = 1, passChapterCount do
        chapterNumberParameter = chapterNumberParameter + self._Control:GetConfig("ChapterNumberParameter", i)
    end
    return chapterNumberParameter / XEnumConst.Theatre4.RatioDenominator
end

-- 获取总分数
function XUiPanelTheatre4SettlementPageTwo:GetTotalScore(data)
    local chapterScore = math.floor(data[1].Count * data[1].Parameter)
    local prosperityScore = math.floor(data[2].Count * data[2].Parameter)
    prosperityScore = math.min(prosperityScore, data[2].MaxScore)
    local exploreScore = math.floor(data[3].Count * data[3].Parameter)
    return math.floor((chapterScore + prosperityScore + exploreScore) * data[4].Count * data[5].Count)
end

-- 刷新奖励
function XUiPanelTheatre4SettlementPageTwo:RefreshReward()
    local rewardList = self._Control:GetSettleRewardGoods()
    if XTool.IsTableEmpty(rewardList) then
        if self.TxtItemNone then
            self.TxtItemNone.gameObject:SetActiveEx(true)
        end
        return
    end
    local rewardsNum = #rewardList
    for i = 1, rewardsNum do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelItemScrollView)
            grid = XUiGridCommon.New(self.Parent, go)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
    if self.TxtItemNone then
        self.TxtItemNone.gameObject:SetActiveEx(rewardsNum == 0)
    end
end

function XUiPanelTheatre4SettlementPageTwo:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiPanelTheatre4SettlementPageTwo:OnBtnLastClick()
    self.Parent:ShowPageOne(true)
end

function XUiPanelTheatre4SettlementPageTwo:OnBtnCloseClick()
    self.Parent:Close()
end

return XUiPanelTheatre4SettlementPageTwo
