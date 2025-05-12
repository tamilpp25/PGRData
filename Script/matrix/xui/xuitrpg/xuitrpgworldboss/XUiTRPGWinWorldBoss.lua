local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTRPGWinWorldBoss = XLuaUiManager.Register(XLuaUi, "UiTRPGWinWorldBoss")

function XUiTRPGWinWorldBoss:OnStart(data)
    self.GridReward.gameObject:SetActiveEx(false)
    self:InitRewardList(data.RewardGoodsList)
    self:SetButtonCallback()
    self:ShowPanel(data)
end

function XUiTRPGWinWorldBoss:OnEnable()
    self:PlayAnimation("PanelBossSingleinfo", function()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end)
end

function XUiTRPGWinWorldBoss:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

-- 物品奖励列表
function XUiTRPGWinWorldBoss:InitRewardList(rewardGoodsList)
    rewardGoodsList = rewardGoodsList or {}
    self.GridRewardList = {}
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for i, item in ipairs(rewards) do
        local grid
        if i == 1 then
            grid = XUiGridCommon.New(self, self.GridReward)
        else
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self, ui)
        end
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActive(false)
        table.insert(self.GridRewardList, grid)
    end
end

function XUiTRPGWinWorldBoss:SetButtonCallback()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
end

function XUiTRPGWinWorldBoss:ShowPanel(data)
    self.StageId = data.StageId
    self.RewardGoodsList = data.RewardGoodsList
    self.TRPGBossFightResult = data.SettleData and data.SettleData.TRPGBossFightResult

    local _, name = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtDifficult.text = name

    self:PlayRewardAnimation()
    self:PlayScoreAndTimeAnimation()
end

-- 奖励动画
function XUiTRPGWinWorldBoss:PlayRewardAnimation()
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    local this = self

    if not self.GridRewardList or #self.GridRewardList == 0 then
        return
    end

    self.RewardAnimationIndex = 1
    XScheduleManager.Schedule(function()
        this:PlayReward(this.RewardAnimationIndex)
        this.RewardAnimationIndex = this.RewardAnimationIndex + 1
    end, interval, #self.GridRewardList, delay)
end

function XUiTRPGWinWorldBoss:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActive(true)
end

function XUiTRPGWinWorldBoss:PlayScoreAndTimeAnimation()
    if not self.TRPGBossFightResult then return end
    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
    local totalTime = self.TRPGBossFightResult.FightTime
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        local totalTimeText = XUiHelper.GetTime(math.floor(f * totalTime))
        local bossLoseHpText = math.floor(f * self.TRPGBossFightResult.BossDamage)
        self.TxtStageTime.text = totalTimeText
        self.TxtBossLoseHpScore.text = bossLoseHpText
    end, function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self:StopAudio()
    end)
end

function XUiTRPGWinWorldBoss:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiTRPGWinWorldBoss:OnBtnBlockClick()
    self:StopAudio()
    self:Close()
    XTipManager.Execute()
end