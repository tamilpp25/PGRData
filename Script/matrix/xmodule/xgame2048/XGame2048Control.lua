---@class XGame2048Control : XControl
---@field private _Model XGame2048Model
local XGame2048Control = XClass(XControl, "XGame2048Control")
function XGame2048Control:OnInit()
    self:StartCheckOverTimer()
end

function XGame2048Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XGame2048Control:RemoveAgencyEvent()

end

function XGame2048Control:OnRelease()
    self:StopCheckOverTimer()
    self.GameControl = nil
end

--region Activity Data
---@return XTableGame2048Activity
function XGame2048Control:GetCurActivityCfg()
    return self._Model:GetCurActivityCfg()
end

function XGame2048Control:GetCurActivityTimeId()
    return self._Model:GetCurActivityTimeId()
end

function XGame2048Control:GetCurActivityItemId()
    return self._Model:GetClientConfigNum('ItemId')
end

function XGame2048Control:GetChapterCurStarSummary(chapterId)
    return self._Model:GetChapterCurStarSummary(chapterId)
end

function XGame2048Control:CheckHasGetStarRewardById(stageId, starIndex)
    local info = self._Model:GetStageInfoById(stageId)

    if info then
        return table.contains(info.GetRewardIndex, starIndex)
    end
    
    return false
end

function XGame2048Control:GetStageCurStarCountById(stageId)
    local info = self._Model:GetStageInfoById(stageId)

    if info then
        return XTool.GetTableCount(info.GetRewardIndex)
    end

    return 0
end

function XGame2048Control:GetStageMaxScoreById(stageId)
    local info = self._Model:GetStageInfoById(stageId)

    if info then
        return info.Score or 0
    end

    return 0
end

function XGame2048Control:GetStageMaxBlockNumById(stageId)
    local info = self._Model:GetStageInfoById(stageId)

    if info then
        return info.MaxBlockNum or 0
    end

    return 0
end

function XGame2048Control:GetStageMaxStepsById(stageId)
    local info = self._Model:GetStageInfoById(stageId)

    if info then
        return info.MaxStep
    end

    return 0
end

function XGame2048Control:GetCurStageData()
    return self._Model:GetCurStageData()
end

function XGame2048Control:TryGetCurActivityNextStageIdInChapter(chapterId, curStageId)
    local stageIds = self:GetChapterStageIdsById(chapterId)

    if stageIds then
        for i, v in ipairs(stageIds) do
            if v == curStageId then
                local nextStageId = stageIds[i + 1]
                if XTool.IsNumberValid(nextStageId) then
                    -- 下一关需要解锁
                    if XMVCA.XGame2048:CheckUnlockByStageId(nextStageId) then
                        return nextStageId
                    end
                end
                break
            end
        end
    end
end
--endregion

--region Configs

--- Chapter
function XGame2048Control:GetChapterStarTotalById(chapterId)
    return self._Model:GetChapterStarTotalById(chapterId)
end

function XGame2048Control:GetChapterUnLockLeftTime(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            local now = XTime.GetServerNowTimestamp()
            local startTime = XFunctionManager.GetStartTimeByTimeId(chapterCfg.TimeId)
            local leftTime = startTime - now

            if leftTime < 0 then
                leftTime = 0
            end
            
            return leftTime
        end
    end
    return 0
end

function XGame2048Control:GetChapterUnLockConditionDesc(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            if XTool.IsNumberValid(chapterCfg.Condition) then
                return XConditionManager.GetConditionDescById(chapterCfg.Condition)
            end
        end
    end
    return ''
end

function XGame2048Control:GetChapterNameById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            return chapterCfg.Name
        end
    end
    return ''
end

function XGame2048Control:GetChapteTitleIconById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            return chapterCfg.TitleIcon
        end
    end
    return ''
end

function XGame2048Control:GetChapterStageIdsById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            return chapterCfg.StageIds
        end
    end
end

function XGame2048Control:GetChapterFullBgById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local chapterCfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if chapterCfg then
            return chapterCfg.FullBg
        end
    end
end

function XGame2048Control:GetChapterIdByStageId(stageId)
    local chapterCfgs = self._Model:GetGame2048ChapterCfgs()

    if not XTool.IsTableEmpty(chapterCfgs) then
        ---@param chapterCfg XTableGame2048Chapter
        for i, chapterCfg in pairs(chapterCfgs) do
            if not XTool.IsTableEmpty(chapterCfg.StageIds) then
                for i, id in pairs(chapterCfg.StageIds) do
                    if stageId == id then
                        return chapterCfg.Id
                    end
                end
            end
        end
    end
    
    return 0
end

--- ChapterShow

function XGame2048Control:GetChapterStageEntranceIconById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.StageEntranceIcon
        end
    end
    
    return ''
end

function XGame2048Control:GetChapterStageEntranceSelectedIconById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.StageEntranceSelectedIcon
        end
    end

    return ''
end

function XGame2048Control:GetChapterGameBoardBgById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.GameBoardBg
        end
    end

    return ''
end

function XGame2048Control:GetChapterGameBoardBgMaskById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.GameBoardBgMask
        end
    end

    return ''
end

function XGame2048Control:GetChapterScoreNumberColorById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.ScoreNumberColor
        end
    end

    return ''
end

function XGame2048Control:GetChapterScoreLabelColorById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.ScoreLabelColor
        end
    end

    return ''
end

function XGame2048Control:GetChapterGameBoardBlocksBgById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.GameBoardBlocksBg
        end
    end

    return ''
end

function XGame2048Control:GetChapterGameBoardGridBgById(chapterId, index)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.GameBoardGridBg[index]
        end
    end

    return ''
end

function XGame2048Control:GetChapterStepColorById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.StepColor
        end
    end

    return ''
end

function XGame2048Control:GetChapterBuffCdBgColorById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.BuffCdBgColor
        end
    end

    return ''
end

function XGame2048Control:GetChapterBuffCdNumColorById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local cfg = self._Model:GetChapterShowCfgById(chapterId)

        if cfg then
            return cfg.BuffCdNumColor
        end
    end

    return ''
end

--- Stage
function XGame2048Control:GetStageNameById(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.Name
        end
    end
    return ''
end

function XGame2048Control:GetStageTypeById(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.Type
        end
    end
    return ''
end

function XGame2048Control:GetStageStarRewardIds(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.RewardIds
        end
    end
end

function XGame2048Control:GetStageStarDescList(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.StarDescs
        end
    end
end

function XGame2048Control:GetStageScoreList(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.Scores
        end
    end
end

function XGame2048Control:GetStageBuffIds(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.BuffIds
        end
    end
end

function XGame2048Control:GetStageInitBuffCharges(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.InitBuffCharge
        end
    end
end

function XGame2048Control:GetStageItemIds(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.ItemIds
        end
    end
end

function XGame2048Control:GetStageShowCharacterId(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.ShowCharacterId
        end
    end
end

function XGame2048Control:GetStageBoardShowGroupId(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.BoardShowGroupId
        end
    end
end

function XGame2048Control:GetStageEntranceEmojiIcon(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.EntranceEmojiIcon
        end
    end
end

function XGame2048Control:GetStageTimeId(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            return stageCfg.TimeId
        end
    end
end

--- Buff
function XGame2048Control:GetBuffIcon(buffId)
    if XTool.IsNumberValid(buffId) then
        ---@type XTableGame2048Buff
        local buffCfg = self._Model:GetGame2048BuffCfgs()[buffId]
        if buffCfg then
            return buffCfg.IconRes
        end
    end
    return ''
end

function XGame2048Control:GetBuffDesc(buffId)
    if XTool.IsNumberValid(buffId) then
        ---@type XTableGame2048Buff
        local buffCfg = self._Model:GetGame2048BuffCfgs()[buffId]
        if buffCfg then
            return buffCfg.Desc
        end
    end
    return ''
end

function XGame2048Control:GetBuffName(buffId)
    if XTool.IsNumberValid(buffId) then
        ---@type XTableGame2048Buff
        local buffCfg = self._Model:GetGame2048BuffCfgs()[buffId]
        if buffCfg then
            return buffCfg.Name
        end
    end
    return ''
end

function XGame2048Control:GetBuffType(buffId)
    if XTool.IsNumberValid(buffId) then
        ---@type XTableGame2048Buff
        local buffCfg = self._Model:GetGame2048BuffCfgs()[buffId]
        if buffCfg then
            return buffCfg.Type
        end
    end
    return 0
end


function XGame2048Control:GetBuffIsTriggerOnce(buffId)
    if XTool.IsNumberValid(buffId) then
        ---@type XTableGame2048Buff
        local buffCfg = self._Model:GetGame2048BuffCfgs()[buffId]
        if buffCfg then
            return buffCfg.IsTriggerOnce
        end
    end
    return false
end

function XGame2048Control:GetBuffCD(buffId)
    if XTool.IsNumberValid(buffId) then
        ---@type XTableGame2048Buff
        local buffCfg = self._Model:GetGame2048BuffCfgs()[buffId]
        if buffCfg then
            return buffCfg.TriggerCD
        end
    end
    return 0
end

--- BoardShowGroup
function XGame2048Control:GetBoardShowStandAnim(characterId)
    if XTool.IsNumberValid(characterId) then
        ---@type XTableGame2048BoardShowGroup
        local boardShowGroupCfg = self._Model:GetGame2048BoardShowGroupCfgById(characterId)
        if boardShowGroupCfg then
            return boardShowGroupCfg.Stand
        end
    end
    return ''
end

---Block
function XGame2048Control:GetBlockLevelUpId(blockId)
    if XTool.IsNumberValid(blockId) then
        ---@type XTableGame2048Block
        local blockCfg = self._Model:GetGame2048BlockCfgs()[blockId]
        if blockCfg then
            return blockCfg.LevelUpId
        end
    end
end

function XGame2048Control:GetBlockCfgById(blockId)
    if XTool.IsNumberValid(blockId) then
        return self._Model:GetGame2048BlockCfgs()[blockId]
    end
end

--- Board
function XGame2048Control:GetGame2048BoardCfgById(id, noTips)
    return self._Model:GetGame2048BoardCfgById(id, noTips)
end

--- BoardShow
function XGame2048Control:GetBoardShowCfgById(boardShowId)
    return self._Model:GetGame2048BoardShowCfgById(boardShowId)
end

--- ShowCondition
function XGame2048Control:GetBoardShowConditionPriorityById(conditionId)
    ---@type XTableGame2048ShowCondition
    local conditionCfg = self._Model:GetGame2048ShowConditionCfgById(conditionId)

    if conditionCfg then
        return conditionCfg.Params[2] or math.maxinteger
    end
    
    return math.maxinteger
end

--- ClientConfig
function XGame2048Control:GetClientConfigVector2(key)
    return self._Model:GetClientConfigVector2(key)
end

function XGame2048Control:GetClientConfigNum(key, index)
    return self._Model:GetClientConfigNum(key, index)
end

function XGame2048Control:GetClientConfigText(key, index)
    return self._Model:GetClientConfigText(key, index)
end
--endregion

--region 到点踢出
function XGame2048Control:StartCheckOverTimer()
    self:StopCheckOverTimer()
    self:UpdateTimer()
    self._CheckOverTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), XScheduleManager.SECOND)
end

function XGame2048Control:StopCheckOverTimer()
    if self._CheckOverTimerId then
        XScheduleManager.UnSchedule(self._CheckOverTimerId)
        self._CheckOverTimerId = nil
    end
end

function XGame2048Control:UpdateTimer()
    local activityTimeId = self:GetCurActivityTimeId()
    if XTool.IsNumberValid(activityTimeId) then
        if XFunctionManager.CheckInTimeByTimeId(activityTimeId) then
            return
        end
    end

    if self._LockTickOut then
        return
    end

    XLuaUiManager.RunMain()
    XUiManager.TipText('ActivityMainLineEnd')
end

--- 玩法界面不需要踢出
function XGame2048Control:LockTickOut()
    self._LockTickOut = true
end

--- 需成对使用，防止踢出功能失效
function XGame2048Control:UnLockTickOut()
    self._LockTickOut = false
end
--endregion

--region 界面数据
function XGame2048Control:SetCurChapterId(chapterId)
    self._ChapterId = chapterId
end

function XGame2048Control:GetCurChapterId()
    return self._ChapterId
end

function XGame2048Control:SetCurStageId(stageId)
    self._StageId = stageId
end

function XGame2048Control:GetCurStageId()
    return self._StageId or 0
end

function XGame2048Control:GetLastSelectStageIndex(chapterId)
    return self._Model:GetLastSelectStageIndex(chapterId)
end

function XGame2048Control:SetSelectStageIndex(chapterId, stageIndex)
    self._Model:SetSelectStageIndex(chapterId, stageIndex)
end
--endregion

--region In Game
function XGame2048Control:EnterGameInit()
    if self.GameControl then
        self:RemoveSubControl(self.GameControl)
        self.GameControl = nil
    end
    self.GameControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048GameControl'))
end

function XGame2048Control:GetIsWaitForSettle()
    return self._IsWaitForSettle
end

function XGame2048Control:GetIsGameOver()
    return self._IsGameOver
end

function XGame2048Control:ExitGameRelease(isOverGame)
    if self.GameControl then
        if isOverGame then
            -- 清空缓存的回合数据
            self._Model:UpdateCurStageData(nil)
        else
            -- 记录玩法内最后一个回合的初始状态缓存
            self._Model:UpdateCurStageData(self.GameControl.TurnControl:GetStageContextFromClient())
        end
        self:RemoveSubControl(self.GameControl)
        self.GameControl = nil
        self._StageLastMaxScore = nil
        self._StageLastMaxBlockNum = nil
        self._IsGameOver = false
        self._IsWaitForSettle = false
    end
end

function XGame2048Control:GetGameControl()
    return self.GameControl
end

function XGame2048Control:MarkStageLastMaxScore(stageId)
    self._StageLastMaxScore = self:GetStageMaxScoreById(stageId)
end

function XGame2048Control:MarkStageLastMaxBlockNum(stageId)
    self._StageLastMaxBlockNum = self:GetStageMaxBlockNumById(stageId)
end

function XGame2048Control:GetStageLastMaxScore()
    return self._StageLastMaxScore
end

function XGame2048Control:GetStageLastMaxBlockNum()
    return self._StageLastMaxBlockNum
end

function XGame2048Control:RequestGame2048EnterStage(stageId, cb)
    XNetwork.Call('Game2048EnterStageRequest', {StageId = stageId}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:UpdateCurStageData(res.StageContext)
        self._IsGameOver = false
        if cb then
            cb(res)
        end
    end)
end

function XGame2048Control:RequestGame2048Settle(settleType, cb)
    if self._IsWaitForSettle or self._IsGameOver then
        return
    end
    
    self._IsWaitForSettle = true
    XNetwork.Call('Game2048SettleRequest', { SettleType =  settleType}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self._IsWaitForSettle = false
            return
        end

        if cb then
            cb(res)
        end
        self._IsGameOver = true
        self._IsWaitForSettle = false

        if self.GameControl and self.GameControl:CheckDebugEnable() then
            XMVCA.XGame2048:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_END_RECORD)
        end
    end)
end

function XGame2048Control:RequestGame2048GiveUp(cb)
    XNetwork.Call('Game2048GiveUpRequest', nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateCurStageData(nil)
        self._IsGameOver = false
        if cb then
            cb(res)
        end
    end)
end
--endregion

return XGame2048Control