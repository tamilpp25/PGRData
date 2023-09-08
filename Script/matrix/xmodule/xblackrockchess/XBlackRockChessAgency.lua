local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
---@class XBlackRockChessAgency : XFubenBaseAgency
---@field private _Model XBlackRockChessModel
---@field public ExConfig XTableFubenActivity
local XBlackRockChessAgency = XClass(XFubenActivityAgency, "XBlackRockChessAgency")
function XBlackRockChessAgency:OnInit()
    --初始化一些变量
    
    --添加到Manager里
    local instance = XMVCA:GetAgency(ModuleId.XFubenEx)
    instance:RegisterActivityAgency(self)
    
    self._IsFighting = false
    
    self._CurrentCombatGuide = {}
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
    return self:IsOpen()
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

function XBlackRockChessAgency:ClearCurrentCombat()
    self._CurrentCombatGuide = {}
end

function XBlackRockChessAgency:MarkGuideCurrentCombat(guideId)
    if not self._CurrentCombatGuide then
        self._CurrentCombatGuide = {}
    end
    self._CurrentCombatGuide[guideId] = guideId
end

--region   ------------------RedPoint start-------------------
function XBlackRockChessAgency:CheckEntrancePoint()
    return self._Model:CheckEntrancePoint()
end

--endregion------------------RedPoint finish------------------

return XBlackRockChessAgency