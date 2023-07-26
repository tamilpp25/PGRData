--===========================
--超级爬塔 特权 对象
--模块负责：吕天元
--===========================
local XSuperTowerFunction = XClass(nil, "XSuperTowerFunction")

function XSuperTowerFunction:Ctor(funcCfg, manager)
    self.FuncManager = manager
    self.FuncCfg = funcCfg
end
--=================
--获取特权键值
--=================
function XSuperTowerFunction:GetKey()
    return self.FuncCfg and self.FuncCfg.Key
end
--=================
--获取特权名称
--=================
function XSuperTowerFunction:GetName()
    return self.FuncCfg and self.FuncCfg.Name
end
--=================
--获取特权解锁的条件ID
--=================
function XSuperTowerFunction:GetConditionId()
    return XSuperTowerConfigs.GetBaseConfigByKey(self:GetKey()) or 0
end
--=================
--检查特权是否解锁
--=================
function XSuperTowerFunction:CheckIsUnlock()
    return XConditionManager.CheckCondition(self:GetConditionId())
end
--=================
--获取特权图标
--=================
function XSuperTowerFunction:GetIcon()
    return self.FuncCfg and self.FuncCfg.Icon
end
--=================
--获取特权解锁条件的文字叙述
--=================
function XSuperTowerFunction:GetUnLockDescription()
    return self.FuncCfg and self.FuncCfg.UnLockDescription
end
--=================
--获取特权的序号
--=================
function XSuperTowerFunction:GetOrder()
    return self.FuncCfg and self.FuncCfg.Order
end
--=================
--获取特权所在的主题周
--=================
function XSuperTowerFunction:GetThemeWeek()
    return self.FuncCfg and self.FuncCfg.ThemeWeek
end
--=================
--获取解锁特权的道具ID
--=================
function XSuperTowerFunction:GetItemId()
    return self.FuncCfg and self.FuncCfg.ItemId
end
--=================
--获取特权解锁的提示叙述
--=================
function XSuperTowerFunction:GetLockTips()
    return self.FuncCfg and self.FuncCfg.LockTips
end
--=================
--设置特权解锁事件
--=================
function XSuperTowerFunction:SetUnLockEvent()
    self.UnLockOnStart = self:CheckIsUnlock()
end
--=================
--解锁时
--@return 是否是新解锁
--=================
function XSuperTowerFunction:CheckNewUnlock()
    if self.UnLockOnStart then return false end
    local result = self:CheckIsUnlock()
    if result then self.UnLockOnStart = true end
    return result
end

return XSuperTowerFunction