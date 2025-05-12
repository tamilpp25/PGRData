local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
---@class XBlackRockChessAgency : XFubenBaseAgency
---@field private _Model XBlackRockChessModel
---@field public ExConfig XTableFubenActivity
local XBlackRockChessAgency = XClass(XFubenActivityAgency, "XBlackRockChessAgency")

local RoleSkillType = {
    LunaProtect = 1, --露娜受伤被保护技能
    LunaHyperAddDps = 2, --露娜大招被动增加伤害
    LunaHyperAddRange = 3, --露娜大招被动增加射程
    LunaHyperAddMove = 4, --露娜大招被动增加移动距离
    VeraHyperAddDps = 5, --薇拉大招增加的伤害
    VeraHyperAddCost = 6, --薇拉大招增加的能量消耗
    VeraHyperSummon = 7, --薇拉大招复活临时棋子
    VeraPosAddDps = 10, --薇拉所站格子与遮天碧碧状态不同颜色，会增加对遮天碧碧的伤害
}

local BuffType = {
    Display = CS.XBlackRockChess.XBuffType.Display:GetHashCode(),
    InvincibleCount = CS.XBlackRockChess.XBuffType.InvincibleCount:GetHashCode(),
    InvincibleAlive = CS.XBlackRockChess.XBuffType.InvincibleAlive:GetHashCode(),
    InvincibleAround = CS.XBlackRockChess.XBuffType.InvincibleAround:GetHashCode(),
    SetMoveRange = CS.XBlackRockChess.XBuffType.SetMoveRange:GetHashCode(),
    CallAfterDeath = CS.XBlackRockChess.XBuffType.CallAfterDeath:GetHashCode(),
    CallAfterDeathWithAround = CS.XBlackRockChess.XBuffType.CallAfterDeathWithAround:GetHashCode(),
    CallAfterWithAttacked = CS.XBlackRockChess.XBuffType.CallAfterWithAttacked:GetHashCode(),
    TransformerWithDeath = CS.XBlackRockChess.XBuffType.TransformerWithDeath:GetHashCode(),
    CallAfterMoveWithAround = CS.XBlackRockChess.XBuffType.CallAfterMoveWithAround:GetHashCode(),
    AddFriendlyHpWithDeath = CS.XBlackRockChess.XBuffType.AddFriendlyHpWithDeath:GetHashCode(),
    ChangeSkillPropertyWithDeath = CS.XBlackRockChess.XBuffType.ChangeSkillPropertyWithDeath:GetHashCode(),
    StandInWhiteBlock = CS.XBlackRockChess.XBuffType.StandInWhiteBlock:GetHashCode(),
    StandInBlackBlock = CS.XBlackRockChess.XBuffType.StandInBlackBlock:GetHashCode(),
    InitEnergyAdd = CS.XBlackRockChess.XBuffType.InitEnergyAdd:GetHashCode(),
    SkillEnergyCostAdd = CS.XBlackRockChess.XBuffType.SkillEnergyCostAdd:GetHashCode(),
    InitContinuationRound = CS.XBlackRockChess.XBuffType.InitContinuationRound:GetHashCode(),
    EnergyAdd = CS.XBlackRockChess.XBuffType.EnergyAdd:GetHashCode(),
    ResetSkillCd = CS.XBlackRockChess.XBuffType.ResetSkillCd:GetHashCode(),
    DestoryAddHp = CS.XBlackRockChess.XBuffType.DestoryAddHp:GetHashCode(),
    SkillCdChange = CS.XBlackRockChess.XBuffType.SkillCdChange:GetHashCode(),
    MoveTimesAdd = CS.XBlackRockChess.XBuffType.MoveTimesAdd:GetHashCode(),
    DestoryInjuryFree = CS.XBlackRockChess.XBuffType.DestoryInjuryFree:GetHashCode(),
}

--喊话触发类型
local GrowlsTriggerType = {
    --角色释放技能
    UseSkill = 1,
    --角色未操作屏幕
    IdleTime = 2,
    --角色选中技能时处于危险区域
    SelectSkillInDanger = 3,
    --角色被击杀
    CheckMate = 4,
    --进入关卡
    EnterFight = 5,
    --胜利
    OnWin = 6,
    --棋子出生
    PieceGenerate = 7,
    --棋子受到攻击
    PieceAttacked = 8,
    --棋子被击杀
    PieceKilled = 9,
    --触发角色技能
    CharacterSkill = 10
}

--成就类型
local ArchiveType = {
    --剧情
    Story = 1,
    --通讯
    Communication = 2,
}

function XBlackRockChessAgency:OnInit()
    --初始化一些变量
    
    --添加到Manager里
    self:RegisterActivityAgency()
    
    self._IsFighting = false
    
    self.RoleSkillType = RoleSkillType
    self.BuffType = BuffType
    
    self.GrowlsTriggerType = GrowlsTriggerType
    self.ArchiveType = ArchiveType
end

function XBlackRockChessAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyBlackRockChessData = handler(self, self.NotifyBlackRockChessData)
    XRpc.NotifyBlackRockChessSettleData = handler(self, self.NotifyBlackRockChessSettleData)
end

function XBlackRockChessAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XBlackRockChessAgency:IsOpen()
    return self._Model:IsOpen()
end

--region   ------------------副本入口扩展 start-------------------

function XBlackRockChessAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BlackRockChess) then
        return false
    end

    if not self:IsOpen() then
        XUiManager.TipText("FubenRepeatNotInActivityTime")
        return false
    end
    
    XLuaUiManager.Open("UiBlackRockChessMain")
    return true
end

function XBlackRockChessAgency:ExCheckInTime()
    return XFubenActivityAgency.ExCheckInTime(self)
end

function XBlackRockChessAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    return self.ExConfig
end

function XBlackRockChessAgency:ExGetProgressTip()
    if self:IsInFight() then
        return XUiHelper.GetText("InChallenge")
    end
    if not self:IsOpen() then
        return ""
    end
    return XUiHelper.GetText("CerbrusGameChallengeProgress", math.floor(self._Model:GetActivityProgress() * 100) .. "%")
end

--endregion------------------副本入口扩展 finish------------------

--region   ------------------CS传输 start-------------------

function XBlackRockChessAgency:NotifyBlackRockChessData(notifyData)
    --登录下发只更新活动信息
    self._Model:UpdateBlackRockChessData(notifyData.BlackRockChessData)
    
    
    local chessInfo = notifyData.BlackRockChessData and notifyData.BlackRockChessData.CurChessInfo or {}
    local isFight = not XTool.IsTableEmpty(chessInfo)
    self:SetIsInFight(isFight, isFight and chessInfo.StageId or 0)
end

function XBlackRockChessAgency:NotifyBlackRockChessSettleData(notifyData)
    if not self:IsInFight() then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, notifyData.BlackRockChessData, notifyData.SettleResult)
end

--endregion------------------CS传输 finish------------------

function XBlackRockChessAgency:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

function XBlackRockChessAgency:IsInFight()
    return self._IsFighting
end

function XBlackRockChessAgency:GetFightingStageId()
    return self._FightingStageId
end

function XBlackRockChessAgency:SetIsInFight(isFight, stageId)
    self._IsFighting = isFight
    self._FightingStageId = stageId
end

function XBlackRockChessAgency:IsCurStageId(stageId)
    if not self._IsFighting then
        return false
    end
    return self._FightingStageId == stageId
end

function XBlackRockChessAgency:IsEnergyGreatOrEqual(target)
    if not self._IsFighting then
        return false
    end
    return self._Model:GetCurEnergy() >= target
end

function XBlackRockChessAgency:IsExtraRound()
    if not self._IsFighting then
        return false
    end
    return self._Model:IsExtraRound()
end

function XBlackRockChessAgency:IsGuideCurrentCombat(guideId)
    if not XTool.IsNumberValid(guideId) then
        return false
    end
    local guideDict = XSaveTool.GetData(string.format("BlackRockGuide10405_%s", XPlayer.Id))
    return not guideDict or not guideDict[guideId]
end

function XBlackRockChessAgency:IsSelectActor(actorId)
    if not self._IsFighting then
        return false
    end
    return self._Model:IsSelectActor(actorId)
end

function XBlackRockChessAgency:IsBossInDelaySkill(bossId, skillId, count)
    if not self._IsFighting then
        return false
    end

    ---@type XBlackRockChessInfo
    local chessControl = self._Model:GetChessControl()
    if not chessControl then return false end

    local bossInfo = chessControl:GetEnemyInfo():GetBossInfo(bossId)
    if not bossInfo then return false end

    local delaySkillInfo = bossInfo:GetDelaySkillInfo()
    if not delaySkillInfo then return false end
    if delaySkillInfo.SkillId ~= skillId then return false end
    if delaySkillInfo.DelayRound ~= 0 then return false end

    -- 不配置延迟结算阶段Count，视为所有阶段都满足
    if count == nil or count == delaySkillInfo.Count then
        return true
    end

    return false
end

function XBlackRockChessAgency:IsContainReinforce()
    if not self._IsFighting then
        return false
    end
    return self._Model:IsContainReinforce() and 1 or 0
end

function XBlackRockChessAgency:IsStageUnlock(stageId)
    if not stageId then
        return false, ""
    end
    local isUnlock, lockDesc = true, ""
    -- 章节未解锁
    local chapterId = self._Model:GetChapterIdByStage(stageId)
    local difficulty = self._Model:GetStageDifficulty(stageId)
    isUnlock, lockDesc = self._Model:CheckChapterCondition(chapterId, difficulty)
    -- 前置关卡未解锁
    if isUnlock then
        local preFight = nil
        if difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL then
            local stageIds = self._Model:GetChapterStageIds(chapterId, difficulty)
            for _, id in ipairs(stageIds) do
                if id == stageId then
                    break
                end
                preFight = id
            end
        else
            local map = self._Model:GetChapterDifficultyMap()
            local normalStageIds = map[chapterId][XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL].StageIds
            local hardStageIds = map[chapterId][XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD].StageIds
            local index = table.indexof(hardStageIds, stageId)
            preFight = normalStageIds[index]
        end
        if XTool.IsNumberValid(preFight) and not self._Model:IsStagePass(preFight) then
            local config = self._Model:GetStageConfig(preFight)
            isUnlock = false
            lockDesc = XUiHelper.GetText("BlackRockChessPreStageUnlock", config.Name)
        end
    end
    -- 关卡条件未解锁
    if isUnlock then
        local config = self._Model:GetStageConfig(stageId)
        if XTool.IsNumberValid(config.Condition) then
            isUnlock, lockDesc = XConditionManager.CheckCondition(config.Condition)
        end
    end

    return isUnlock, lockDesc
end

function XBlackRockChessAgency:ClearCurrentCombat()
    XSaveTool.SaveData(string.format("BlackRockGuide10405_%s", XPlayer.Id), false)
end

function XBlackRockChessAgency:MarkGuideCurrentCombat(guideId)
    local guideDict = XSaveTool.GetData(string.format("BlackRockGuide10405_%s", XPlayer.Id)) or {}
    guideDict[guideId] = true
    XSaveTool.SaveData(string.format("BlackRockGuide10405_%s", XPlayer.Id), guideDict)
end

--是否展示每日提示
function XBlackRockChessAgency:IsShowCueTip()
    return self._Model:IsShowCueTip()
end

function XBlackRockChessAgency:SetCueTipValue(value)
    self._Model:SetCueTipValue(value)
end

function XBlackRockChessAgency:CheckGuideNode(nodeId, isLocaled)
    local nodeCfg = self._Model:GetCurNodeCfg()
    if nodeCfg then
        if isLocaled then
            return nodeCfg.Id == nodeId
        else
            return nodeCfg.Id ~= nodeId
        end
    else
        return false
    end
end

--region   ------------------RedPoint start-------------------

---主界面章节按钮红点（只需检查普通关 困难关不用）
function XBlackRockChessAgency:CheckMainRedPoint()
    if not self._Model:CheckRedPointBase() then
        return false
    end
    for _, chapterId in pairs(self._Model:_GetActivityConfig().Chapters) do
        local stageIds = self._Model:GetChapterStageIds(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
        for _, stageId in pairs(stageIds) do
            if self:IsStageUnlock(stageId) and not self._Model:IsEverBeenEnterStage(stageId) then
                return true
            end
        end
    end
    return false
end

function XBlackRockChessAgency:CheckEntrancePoint()
    if self:CheckMainRedPoint() then
        return true
    end

    if self._Model:CheckShopRedPoint() then
        return true
    end

    return false
end

--endregion------------------RedPoint finish------------------

return XBlackRockChessAgency