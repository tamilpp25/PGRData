
---@class XChessConditionControl : XControl 战棋活动数据
---@field private _MainControl XBlackRockChessControl
---@field private _Model XBlackRockChessModel
local XChessConditionControl = XClass(XControl, "XChessConditionControl")

local ConditionType = {
    --复活次数判断
    ReviveTimes = 1,
    --击杀次数判断
    KillTimes = 2,
    --回合次数判断
    RoundTimes = 3,
    --指定位置
    StandPoint = 4
}

function XChessConditionControl:OnInit()
    self._CheckFunc = {}

    self:RegisterCheckFunc(ConditionType.ReviveTimes, self.DoCheckReviveTimes)
    self:RegisterCheckFunc(ConditionType.KillTimes, self.DoCheckKillTimes)
    self:RegisterCheckFunc(ConditionType.RoundTimes, self.DoCheckRoundTimes)
    self:RegisterCheckFunc(ConditionType.StandPoint, self.DoCheckStandPoint)
end

function XChessConditionControl:RegisterCheckFunc(type, func)
    if not type or not func then
        XLog.Error("注册Condition函数失败" .. tostring(type) .. ", " .. tostring(func))
        return
    end
    self._CheckFunc[type] = func
end

--- 获取关卡目标描述
---@return string
--------------------------
function XChessConditionControl:GetStageTargetDesc()
    local conditionId = self._MainControl:GetActiveConditionId()
    if not XTool.IsNumberValid(conditionId) then
        return ""
    end
    local condition = self._Model:GetConditionConfig(conditionId)
    local desc = condition.Desc
    if condition.Type == ConditionType.ReviveTimes then
        local reviveCount = self._MainControl:GetChessGamer():GetReviveCount()
        return string.format(desc, reviveCount .. "/" .. condition.Params[1])
    elseif condition.Type == ConditionType.KillTimes then
        local pieceType = condition.Params[2]
        local gamer = self._MainControl:GetChessGamer()
        local count = XTool.IsNumberValid(pieceType) and
                gamer:GetKillCount(pieceType) or gamer:GetKillTotal()
        return string.format("%s(%s/%s)", desc, count, condition.Params[1])
    elseif condition.Type == ConditionType.RoundTimes then
        return string.format("%s(%s/%s)", desc, self._MainControl:GetChessRound(), condition.Params[1])
    else
        return desc
    end
end

function XChessConditionControl:CheckCondition(conditionId, ...)
    local template = self._Model:GetConditionConfig(conditionId)
    if not template then
        return false, "Error"
    end
    local check = self._CheckFunc[template.Type]
    if not check then
        return false, "NoFunction"
    end

    return check(self, template, ...)
end

--- 复活次数小于x次
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XChessConditionControl:DoCheckReviveTimes(template)
    local reviveTimes = self._MainControl:GetChessGamer():GetReviveCount()
    return template.Params[1] >= reviveTimes, template.Desc
end

--- 击杀棋子数量达到（数量，棋子类型-可不配，不配为任意棋子）
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XChessConditionControl:DoCheckKillTimes(template)
    local killCount = template.Params[1]
    local killPieceType = template.Params[2]
    local current = 0
    if XTool.IsNumberValid(killPieceType) then
        current = self._MainControl:GetChessGamer():GetKillCount(killPieceType)
    else
        current = self._MainControl:GetChessGamer():GetKillTotal()
    end

    return current >= killCount, template.Desc
end

--- 回合数达到
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XChessConditionControl:DoCheckRoundTimes(template)
    return self._MainControl:GetChessRound() >= template.Params[1], template.Desc
end

--- 检测指定玩家是否站在指定坐标,必须要玩家回合结束才算
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XChessConditionControl:DoCheckStandPoint(template)
    if self._MainControl:IsGamerRound() then
        return false, template.Desc
    end
    local col = template.Params[1]
    local row = template.Params[2]
    local roleId = template.Params[3]
    local actor = self._MainControl:GetChessGamer():GetRole(roleId)
    if not actor then
        return false, ""
    end
    local movedPoint = actor:GetMovedPoint()

    return movedPoint.x == col and movedPoint.y == row, template.Desc
end

function XChessConditionControl:OnRelease()
    self._CheckFunc = nil
end

return XChessConditionControl