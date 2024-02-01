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
    
    self._CurrentCombatGuide = {}
    
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
        return
    end

    if not self:IsOpen() then
        XUiManager.TipText("FubenRepeatNotInActivityTime")
        return
    end
    
    XLuaUiManager.Open("UiBlackRockChessMain")
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
    return self._CurrentCombatGuide[guideId] == nil
end

function XBlackRockChessAgency:IsSelectActor(actorId)
    if not self._IsFighting then
        return false
    end
    return self._Model:IsSelectActor(actorId)
end

function XBlackRockChessAgency:IsContainReinforce()
    if not self._IsFighting then
        return false
    end
    return self._Model:IsContainReinforce() and 1 or 0
end

function XBlackRockChessAgency:ClearCurrentCombat()
    self._CurrentCombatGuide = {}
end

function XBlackRockChessAgency:MarkGuideCurrentCombat(guideId)
    if not self._CurrentCombatGuide then
        self._CurrentCombatGuide = {}
    end
    self._CurrentCombatGuide[guideId] = guideId
end

--是否展示每日提示
function XBlackRockChessAgency:IsShowCueTip()
    return self._Model:IsShowCueTip()
end

function XBlackRockChessAgency:SetCueTipValue(value)
    self._Model:SetCueTipValue(value)
end

--region   ------------------RedPoint start-------------------
function XBlackRockChessAgency:CheckEntrancePoint()
    return self._Model:CheckEntrancePoint()
end

--endregion------------------RedPoint finish------------------

return XBlackRockChessAgency