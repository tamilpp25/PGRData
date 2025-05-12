--- 公会战7.0新增龙怒系统相关的数据管理类
---@class XGuildWarDragonRageData
local XGuildWarDragonRageData = XClass(nil, 'XGuildWarDragonRageData')

function XGuildWarDragonRageData:ResetData()
    self.GameThrough = nil
    self.DragonRage = nil
    self.FullDragonRageTime = nil
    self.GameThroughCfgId = nil
    self.DragonRageCfgId = nil
    self.LastDragonRageReduceTime = nil
    self.FullDragonRageCfgId = nil
    self._IsOpenSystem = nil
    self._CurLatestNewGameActionId = nil
end

--- 更新龙怒值
function XGuildWarDragonRageData:UpdateDragonRageValue(data)
    if type(data) == 'table' then
        self.DragonRage = data.CurDragonRage
    else
        self.DragonRage = data
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE)
end

--- 更新整个系统的数据
function XGuildWarDragonRageData:UpdateDragonRageData(data)
    local dragonRageValueChanged = self.DragonRage ~= nil and self.DragonRage ~= data.DragonRage
    local gameThoughChanged = self.GameThrough ~= nil and  self.GameThrough ~= data.GameThrough

    self.GameThrough = data.GameThrough -- 周目
    self.DragonRage = data.DragonRage -- 龙怒值
    self.FullDragonRageTime = data.FullDragonRageTime --满龙怒次数
    self.GameThroughCfgId = data.GameThroughCfgId -- 当前周目配置
    self.DragonRageCfgId = data.DragonRageCfgId -- 当前龙怒配置
    self.LastDragonRageReduceTime = data.LastDragonRageReduceTime -- 上次龙怒减少时间
    self.FullDragonRageCfgId = data.FullDragonRageCfgId -- 当前满龙怒状态配置
    self._IsOpenSystem = not XTool.IsTableEmpty(data) and XTool.IsNumberValid(data.GameThroughCfgId)

    if dragonRageValueChanged or gameThoughChanged then
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_DRAGONRAGE_CHANGE)
    end
end

--- 是否开启龙怒系统玩法
function XGuildWarDragonRageData:GetIsOpenDragonRage()
    return self._IsOpenSystem
end

--- 是否解锁龙怒系统
function XGuildWarDragonRageData:GetIsUnlockDragonRage()
    return XTool.IsNumberValid(self.DragonRageCfgId) or false
end

--- 当前龙怒等级
function XGuildWarDragonRageData:GetDragonRageLevel()
    return self.GameThrough or 0
end

--- 当前龙怒值
function XGuildWarDragonRageData:GetDragonRageValue()
    return self.DragonRage or 0
end

--- 当前龙怒配置Id
function XGuildWarDragonRageData:GetDragonRageCfgId()
    return self.DragonRageCfgId or 0
end

--- 当前周目配置Id
function XGuildWarDragonRageData:GetGameThroughCfgId()
    return self.GameThroughCfgId or 0
end

--- 当前满龙怒状态配置Id
function XGuildWarDragonRageData:GetFullDragonRageCfgId()
    return self.FullDragonRageCfgId or 0
end

--- 当前龙怒值是否处于下降阶段
function XGuildWarDragonRageData:GetIsDragonRageValueDown()
    return XTool.IsNumberValid(self.FullDragonRageCfgId) or false
end

--- 临时缓存，记录当前登录最新周目action的Id，防止之前的action延时下发导致重复播放
function XGuildWarDragonRageData:SetCurLatestNewGameActionId(actionId)
    self._CurLatestNewGameActionId = actionId
end

function XGuildWarDragonRageData:GetCurLatestNewGameActionId()
    return self._CurLatestNewGameActionId or 0
end

--- 临时缓存，标记存在周目行为等待播放，用于Boss详情界面踢出
function XGuildWarDragonRageData:SetIsNewGameThroughActionWaitToPlay(isHave)
    self._IsNewGameThroughActionWaitToPlay = isHave
end

function XGuildWarDragonRageData:GetIsNewGameThroughActionWaitToPlay()
    return self._IsNewGameThroughActionWaitToPlay
end


return XGuildWarDragonRageData