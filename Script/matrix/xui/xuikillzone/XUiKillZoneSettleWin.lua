local XUiGridWinRole = require("XUi/XUiSettleWin/XUiGridWinRole")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridRewardLine = require("XUi/XUiStronghold/XUiGridRewardLine")

local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiKillZoneSettleWin = XLuaUiManager.Register(XLuaUi, "UiKillZoneSettleWin")

function XUiKillZoneSettleWin:OnAwake()
    self:AutoAddListener()

    self.GridReward.gameObject:SetActiveEx(false)
    self.GridCond.gameObject:SetActiveEx(false)
    self.GridWinRole.gameObject:SetActiveEx(false)

    self.BtnRight.gameObject:SetActiveEx(false)
    self.BtnLeft.gameObject:SetActiveEx(false)
    self.PanelRewardInfo.gameObject:SetActiveEx(false)
    self.TxtRewardEmpty.gameObject:SetActiveEx(false)
    self.TxtHighScore.gameObject:SetActiveEx(false)
    self.PanelNewRecord.gameObject:SetActiveEx(false)
    self.TxtPoint.text = 0
end

function XUiKillZoneSettleWin:OnStart(data, closeCb)
    self.WinData = data
    self.StageId = data.StageId
    self.CloseCb = closeCb

    self.RewardGrids = {}
    self.StarDescGrids = {}
    self.RewardTeamGrids = {}

    self:SetAutoCloseInfo(XDataCenter.KillZoneManager.GetEndTime(), function(isColse)
        if isColse then
            self.IsEnd = true
            XDataCenter.KillZoneManager.OnActivityEnd()
        end
    end)
end

function XUiKillZoneSettleWin:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()
    XScheduleManager.ScheduleOnce(function()
        self:PlayAnimationWithMask("AnimEnable2")
    end, 0)
end

function XUiKillZoneSettleWin:OnDisable()
    self.Super.OnDisable(self)
    self:StopAudio()
end

function XUiKillZoneSettleWin:OnDestroy()
    if self.CloseCb then self.CloseCb() end
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiKillZoneSettleWin:OnGetEvents()
    return {
        XEventId.EVENT_KILLZONE_FARM_REWARD_OBTAIN_COUNT_CHANGE,
    }
end

function XUiKillZoneSettleWin:OnNotify(evt, ...)
    if self.IsEnd then return end

    local args = { ... }
    if evt == XEventId.EVENT_KILLZONE_FARM_REWARD_OBTAIN_COUNT_CHANGE then
        self:UpdateRewards()
    end
end

function XUiKillZoneSettleWin:UpdateView()
    local stageId = self.StageId

    local name = XKillZoneConfigs.GetStageName(stageId)
    self.TxtStageName.text = name

    self:UpdateRewards()
    self:UpdateStarDescs()
    self:UpdatePlayerInfo()
    self:UpdateTeamInfo()
    self:UpdateScore()
end

-- 玩家经验
function XUiKillZoneSettleWin:UpdatePlayerInfo()
    local data = self.WinData
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    local addExp = XDataCenter.FubenManager.GetTeamExp(data.StageId)

    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

function XUiKillZoneSettleWin:UpdateTeamInfo()
    local data = self.WinData
    local charExp = data.CharExp
    local count = #charExp
    if count <= 0 then
        return
    end

    local cardExp = XDataCenter.FubenManager.GetCardExp(data.StageId)
    for index = 1, count do
        local grid = self.RewardTeamGrids[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole, self.PanelRoleContent)
            grid = XUiGridWinRole.New(self, ui)
            self.RewardTeamGrids[index] = grid
        end

        local charId = charExp[index].Id
        local isRobot = XRobotManager.CheckIsRobotId(charId)
        if isRobot then
            grid:UpdateRobotInfo(charId)
        else
            grid:UpdateRoleInfo(charExp[index], cardExp)
        end

        grid.GameObject:SetActiveEx(true)
    end
end

function XUiKillZoneSettleWin:UpdateRewards()
    local stageId = self.StageId

    local isPassed = XDataCenter.KillZoneManager.IsStageFinished(stageId)
    self.PanelFirst.gameObject:SetActiveEx(not isPassed)
    self.BtnBlock.gameObject:SetActiveEx(true)

    --[[if not isPassed then
        local rewardId = XFubenConfigs.GetFirstRewardShow(stageId)
        local rewards = XRewardManager.GetRewardList(rewardId)
        if rewards then
            for index, item in ipairs(rewards) do
                local grid = self.RewardGrids[index]

                if not grid then
                    local ui = CSUnityEngineObjectInstantiate(self.GridReward, self.PanelRewardContent)
                    grid = XUiGridCommon.New(self, ui)
                    self.RewardGrids[index] = grid
                end

                grid:Refresh(item)
                grid.GameObject:SetActiveEx(true)
            end
        end
        for index = #rewards + 1, #self.RewardGrids do
            self.RewardGrids[index].GameObject:SetActiveEx(false)
        end

        self.TxtRewardBeat.gameObject:SetActiveEx(false)
        self.PanelRewardContent.gameObject:SetActiveEx(true)
    else
        local killCount = self.WinData.SettleData.KillZoneStageResult.CurKillCount or 0
        self.TxtRewardBeat.text = CsXTextManagerGetText("KillZoneSettleWinKillEnemyCount", killCount)

        self.TxtRewardBeat.gameObject:SetActiveEx(true)
        self.PanelRewardContent.gameObject:SetActiveEx(false)
    end]]

    -- local leftCount = XDataCenter.KillZoneManager.GetLeftFarmRewardObtainCount()
    -- self.TxtRewardTime.text = leftCount .. "/" .. XKillZoneConfigs.MaxFarmRewardCount
    -- local isEmpty = leftCount <= 0
    -- self.TxtRewardEmpty.gameObject:SetActiveEx(isEmpty)
    -- self.PanelRewardContent.gameObject:SetActiveEx(not isEmpty)
end

function XUiKillZoneSettleWin:UpdateStarDescs()
    local stageId = self.StageId
    local currentStar = self.WinData.SettleData.KillZoneStageResult.CurStar

    local starDescList = XKillZoneConfigs.GetStageStarDescList(stageId)
    for star, desc in ipairs(starDescList) do
        local grid = self.StarDescGrids[star]
        if not grid then
            local go = star == 1 and self.GridCond or CSUnityEngineObjectInstantiate(self.GridCond, self.PanelCondContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.StarDescGrids[star] = grid
        end

        grid.TxtDesc.text = desc

        local isPassed = currentStar >= star
        grid.TxtLoaded.gameObject:SetActiveEx(isPassed)
        grid.TxtNotLoaded.gameObject:SetActiveEx(not isPassed)

        grid.GameObject:SetActiveEx(true)
    end
end

function XUiKillZoneSettleWin:UpdateScore()
    if not self.WinData then
        return
    end
    -- 历史最高分
    local historyScore = XDataCenter.KillZoneManager.GetStageMaxScore(self.StageId)
    if XTool.IsNumberValid(historyScore) then
        self.TxtHighScore.gameObject:SetActiveEx(true)
        self.TxtHighScore.text = XUiHelper.GetText("KillZoneSettleWinMaxHistoryScore", historyScore)
    end
    -- 最新分数
    local score = self.WinData.SettleData.KillZoneStageResult.Score or 0
    local isNewRecord = self.WinData.SettleData.KillZoneStageResult.IsNewRecord or false
    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
    local time = XUiHelper.GetClientConfig("BossSingleAnimaTime", XUiHelper.ClientConfigType.Float)
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        -- 分数
        self.TxtPoint.text = XUiHelper.GetText("KillZoneSettleWinMaxScore", XMath.ToInt(f * score))
    end, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:StopAudio()
        self.PanelNewRecord.gameObject:SetActiveEx(isNewRecord)
    end)
end

function XUiKillZoneSettleWin:AutoAddListener()
    self.BtnLeft.CallBack = handler(self, self.Close)
    self.BtnBlock.CallBack = handler(self, self.Close)
    self.BtnRight.CallBack = handler(self, self.OnClickBtnRight)
end

function XUiKillZoneSettleWin:OnClickBtnRight()
    local stageId = self.StageId
    local cb = function(rewardGoods)
        if not XTool.IsTableEmpty(rewardGoods) then
            XUiManager.OpenUiObtain(rewardGoods)
        end
    end
    XDataCenter.KillZoneManager.KillZoneTakeFarmRewardRequest(stageId, cb)
    self:Close()
end

function XUiKillZoneSettleWin:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

return XUiKillZoneSettleWin