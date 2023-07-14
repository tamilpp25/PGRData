--===========================================================================
 ---@desc 中心枢纽关卡结算
--===========================================================================
local XUiPivotCombatCenterSettle = XLuaUiManager.Register(XLuaUi, "UiPivotCombatCenterSettle")

function XUiPivotCombatCenterSettle:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiPivotCombatCenterSettle:OnStart(winData)
    self.WinData = winData
    self.CustomData = XDataCenter.FubenManager.CurFightResult.CustomData
end

function XUiPivotCombatCenterSettle:OnEnable()
    self:Refresh()
end

function XUiPivotCombatCenterSettle:Refresh()
    if not self.WinData then
        return
    end

    
    --刷新角色列表
    self:RefreshCharacterList(self.WinData)
    --刷新积分统计
    local baseScore = self:RefreshIntegralStatistics()
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    local data = self.WinData
    
    local stage = XDataCenter.PivotCombatManager.GetStage(data.StageId)
    local curScore = math.ceil(baseScore * (1 + XDataCenter.PivotCombatManager.GetTotalScoreAddition()))
    local maxScore = XDataCenter.PivotCombatManager.GetHistoryScore()
    local highestGrade = XDataCenter.PivotCombatManager.GetHistoryRankingLevel()
    
    self.PanelNewTag.gameObject:SetActiveEx(curScore > maxScore)

    --刷新最高积分
    if curScore > maxScore then
        XDataCenter.PivotCombatManager.RefreshHistoryScore(curScore)
    end
    --刷新历史最高评分等级
    if self.CurRatingLevel then
        --当前评分等级
        self.TxtAllRating.text = XPivotCombatConfigs.FightGrade[self.CurRatingLevel] or ""
        if self.CurRatingLevel > highestGrade then
            XDataCenter.PivotCombatManager.RefreshHistoryRankingLevel(self.CurRatingLevel)
        end
    else
        self.TxtAllRating.gameObject:SetActiveEx(false)
    end
    
    --积分加成
    self.TxtIntegralUp.text = string.format("%s%%", math.ceil(XDataCenter.PivotCombatManager.GetTotalScoreAddition() * 100))
   
    --历史最高评分等级
    self.TxtHistoryGrade.text = XPivotCombatConfigs.FightGrade[highestGrade] or ""
        
    --播放音效
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)
    
    XUiHelper.Tween(time, function(delta) 
        
        --当前总分
        local point = math.ceil(delta * curScore)
        self.TxtAllScore.text = point
        
        --历史最高分
        local oldPoint = math.ceil(delta * maxScore)
        self.TxtHistoryScore.text = oldPoint
        
    end, function()
        self:StopAudio()
    end)
    
end

--刷新参战角色列表
function XUiPivotCombatCenterSettle:RefreshCharacterList(data)
    local charExp = data.CharExp
    local count = #charExp
    if count <= 0 then
        return
    end
    for idx = 1, count do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole, self.PanelRoleContent)
        local grid = {}
        XTool.InitUiObjectByUi(grid, ui)
        local charId = charExp[idx].Id
        if XRobotManager.CheckIsRobotId(charId) then
            charId = XRobotManager.GetCharacterId(charId)
        end
        local icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(charId)
        grid.RImgIcon:SetRawImage(icon)
        grid.GameObject:SetActiveEx(true)
    end
end

--刷新积分统计
function XUiPivotCombatCenterSettle:RefreshIntegralStatistics()
    local resultKeys = XPivotCombatConfigs.FightResultKey
    local customData = {}
    if self.CustomData.Count <= 0 then return end
    
    XTool.LoopMap(self.CustomData, function(playerId, data)
        XTool.LoopMap(data.Dict, function(key, value)
            customData[key] = value
        end)
    end)
    --基础积分
    local baseScore = 0
    for key, value in pairs(customData) do
        --超过key的最大值
        if key > resultKeys.HighestGrade then
            goto CONTINUE
        end
        local title = XPivotCombatConfigs.GetSettleDesc(key)
        --评分等级
        if key == resultKeys.HighestGrade then
            -- 当前评分等级
            self.CurRatingLevel = value
            value = XPivotCombatConfigs.FightGrade[self.CurRatingLevel]
        else
            baseScore = baseScore + tonumber(value)
        end
        self:NewTipsGrid(title, value)
        ::CONTINUE::
    end
    return baseScore
end

function XUiPivotCombatCenterSettle:NewTipsGrid(title, score)
    local ui = CS.UnityEngine.Object.Instantiate(self.BossLoseHp, self.PanelInfo)
    local grid = {}
    XTool.InitUiObjectByUi(grid, ui)
    grid.TxtTitle.text  = title
    grid.TxtNum.text    = ""
    grid.TxtScore.text  = score
    grid.GameObject:SetActiveEx(true)
end

function XUiPivotCombatCenterSettle:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiPivotCombatCenterSettle:InitUI()
    self.BtnQuit.gameObject:SetActiveEx(true)
    self.BtnReFight.gameObject:SetActiveEx(true)
    self.GridWinRole.gameObject:SetActiveEx(false)
    self.BossLoseHp.gameObject:SetActiveEx(false)
    self.TxtAllRating = self.TxtHistoryScore.transform.parent:Find("TxtAllRating"):GetComponent("Text")
end

function XUiPivotCombatCenterSettle:InitCB()
    self.BtnQuit.CallBack = function()
        self:Close()
    end
    
    self.BtnReFight.CallBack = function()
        if not XDataCenter.PivotCombatManager.IsOpen() then return end
        --避免多次挑战出现UI堆叠
        self:Close()
        local region = XDataCenter.PivotCombatManager.GetCenterRegion()
        if not region then return end
        local team = XDataCenter.PivotCombatManager.GetTeam(region:GetRegionId())
        local stageId = self.WinData.StageId
        
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local teamId = team:GetId()
        local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1
        
        XDataCenter.FubenManager.EnterFight(stageCfg, teamId, isAssist)
    end
end

function XUiPivotCombatCenterSettle:OnGetEvents()
    return {
        XEventId.EVENT_ACTIVITY_ON_RESET,
        XEventId.EVENT_PIVOTCOMBAT_ACTIVITY_END,
    }
end

function XUiPivotCombatCenterSettle:OnNotify(evt, ...)
    local args = { ... }
    --通用处理事件
    XDataCenter.PivotCombatManager.OnNotify(evt, args)
end

