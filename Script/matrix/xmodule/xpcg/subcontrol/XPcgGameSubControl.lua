---@class XPcgGameSubControl : XControl
---@field private _Model XPcgModel
---@field _MainControl XPcgControl
local XPcgGameSubControl = XClass(XControl, "XPcgGameSubControl")
function XPcgGameSubControl:OnInit()
    --初始化内部变量
end

function XPcgGameSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPcgGameSubControl:RemoveAgencyEvent()

end

function XPcgGameSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

function XPcgGameSubControl:OnStageContinue()
    self._Model:OnStageContinue()
end

--region 游戏数据读取
-- 获取当前进行中的关卡数据
---@return XPcgPlayingStage
function XPcgGameSubControl:GetPlayingStageData()
    return self._Model.PlayingStageData
end

-- 获取上一次通关记录
function XPcgGameSubControl:GetLastStageRecord()
    return self._Model:GetLastStageRecord()
end

-- 获取新解锁的角色Id列表
function XPcgGameSubControl:GetNewUnlockCharacterIds()
    return self._Model:GetNewUnlockCharacterIds()
end

-- 应用缓存的下一回合关卡数据
function XPcgGameSubControl:UseCacheNextPlayingStageData()
    return self._Model:UseCacheNextPlayingStageData()
end

-- 应用缓存的结算效果列表
function XPcgGameSubControl:UseCacheEffectSettles()
    return self._Model:UseCacheEffectSettles()
end

-- 获取回合日志
function XPcgGameSubControl:GetRoundLogs()
    return self._Model:GetRoundLogs()
end

-- 获取上一局的关卡Id
function XPcgGameSubControl:GetLastStageId()
    return self._Model:GetLastStageId()
end

-- 获取对局的角色Id列表
function XPcgGameSubControl:GetLastCharacterIds()
    return self._Model:GetLastCharacterIds()
end

-- 获取怪物行为图标 + 怪物行为数值文本
function XPcgGameSubControl:GetMonsterBehaviorPreviewsIconAndTxt(behaviorPreviews)
    return self._Model:GetMonsterBehaviorPreviewsIconAndTxt(behaviorPreviews)
end
--endregion

--region 游戏状态和回合状态
-- 设置游戏状态
function XPcgGameSubControl:SetGameState(gameState)
    self._Model:SetGameState(gameState)
end

-- 获取游戏状态
function XPcgGameSubControl:GetGameState()
    return self._Model:GetGameState()
end

-- 设置下一回合状态
function XPcgGameSubControl:SetNextRoundState()
    self._Model:SetNextRoundState()
end

-- 获取回合状态
function XPcgGameSubControl:GetRoundState()
    return self._Model:GetRoundState()
end
--endregion

return XPcgGameSubControl
