--===========================
--超级爬塔 特权 管理器
--模块负责：吕天元
--===========================
local XSuperTowerFunctionManager = XClass(nil, "XSuperTowerFunctionManager")

function XSuperTowerFunctionManager:Ctor(rootManager)
    self.ActivityManager = rootManager
    self.UnlockList = {}
    self:Init()
end
--=================
--初始化
--=================
function XSuperTowerFunctionManager:Init()
    local funcDic = XSuperTowerConfigs.GetAllFunctionCfgs()
    local script = require("XEntity/XSuperTower/Function/XSuperTowerFunction")
    self.Functions = {} --使用键值的特权字典
    self.FunctionByOrder = {} --使用序号的特权列表
    for key, cfg in pairs(funcDic) do
        local func = script.New(cfg, self)
        self.Functions[key] = func
        local order = cfg.Order
        self.FunctionByOrder[order] = func
    end
end
--=================
--初始化最新特权的序号
--=================
function XSuperTowerFunctionManager:InitFunctionNewIndex()
    self.NewIndex = -1
    for order, func in pairs(self.FunctionByOrder) do
        --若最新未解锁序号未赋值或大于检查中的未解锁特权序号，则赋值
        if not func:CheckIsUnlock() and ((self.NewIndex == -1) or (self.NewIndex > order)) then
            self.NewIndex = order
        end
    end
end
--=================
--设置特权道具数量变化监听
--=================
function XSuperTowerFunctionManager:SetUnLockEvent()
    for _, func in pairs(self.Functions) do
        func:SetUnLockEvent()
    end
end

function XSuperTowerFunctionManager:CheckUnLock()
    for _, func in pairs(self.Functions) do
        if func:CheckNewUnlock() then
            self:AddUnlockFunction(func)
        end
    end
    self:InitFunctionNewIndex()
end
--=================
--根据特权Key获取特权对象
--@param key:特权键值 XSuperTowerManager.FunctionName
--=================
function XSuperTowerFunctionManager:GetFunctionByKey(key)
    return self.Functions[key]
end
--=================
--根据特权Key检查特权是否解锁
--@param key:特权键值 XSuperTowerManager.FunctionName
--=================
function XSuperTowerFunctionManager:CheckFunctionUnlockByKey(key)
    if not self.Functions[key] then
        return false
    else
        return self.Functions[key]:CheckIsUnlock()
    end
end
--=================
--获取最新未解锁的特权对象
--=================
function XSuperTowerFunctionManager:GetTheNewFunction()
    if not self.NewIndex then self:InitFunctionNewIndex() end
    if self.NewIndex == -1 then return nil end --全解锁的情况或初始化失败的情况
    return self.FunctionByOrder[self.NewIndex]
end
--=================
--把解锁特权对象入队解锁队列
--=================
function XSuperTowerFunctionManager:AddUnlockFunction(func)
    table.insert(self.UnlockList, func)
end
--=================
--获取解锁队列中的第一个特权对象
--=================
function XSuperTowerFunctionManager:GetUnlockList()
    local list = self.UnlockList
    self.UnlockList = {}
    return list
end
return XSuperTowerFunctionManager