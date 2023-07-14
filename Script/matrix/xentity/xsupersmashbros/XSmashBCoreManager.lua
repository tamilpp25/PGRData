--===========================
--超限乱斗核心管理器
--模块负责：吕天元
--===========================
local XSmashBCoreManager = {}
local Cores
local CoresById
local TransEnergy = 0 --玩家已经转换的能量
--=============
--初始化
--=============
function XSmashBCoreManager.Init(activityId)
    Cores = {}
    CoresById = {}
    local coreCfgs = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Activity2CoreDic, activityId)
    local coreScript = require("XEntity/XSuperSmashBros/XSmashBCore")
    for modePriority, coreCfg in pairs(coreCfgs or {}) do
        local core = coreScript.New(coreCfg)
        Cores[modePriority] = core
        CoresById[coreCfg.Id] = core
    end
end
--=============
--刷新推送核心数据
--=============
function XSmashBCoreManager.RefreshNotifyCoreData(data)
    for _, coreData in pairs(data.SuperCoreDbList) do
        local core = CoresById[coreData.Id]
        if core then
            core:SetStar(coreData.Level)
            core:SetAtkLevel(coreData.StrongAttack or 0)
            core:SetLifeLevel(coreData.StrongHp or 0)
        end
    end
    for _, coreInfo in pairs(data.CharacterMountCoreList) do
        if coreInfo.CoreId > 0 then
            local chara = XDataCenter.SuperSmashBrosManager.GetRoleById(coreInfo.CharacterId)
            if chara then
                chara:SetCore(coreInfo.CoreId)
            end
        end
    end
end
--=============
--获取所有核心对象
--索引为所属的模式优先级
--=============
function XSmashBCoreManager.GetAllCores()
    return Cores or {}
end
--=============
--根据核心Id获取核心对象
--@param
--coreId : 核心Id - 配置表SuperSmashBrosCore Id
--=============
function XSmashBCoreManager.GetCoreById(coreId)
    return CoresById[coreId]
end
--=============
--根据模式优先度获取核心对象
--@param
--priority : 模式优先度 - 配置表SuperSmashBrosMode Priority
--=============
function XSmashBCoreManager.GetCoreByPriority(priority)
    return Cores[priority]
end
--=============
--检查是否有新的核心
--=============
function XSmashBCoreManager.CheckNewCoreFlag()
    for _, core in pairs(Cores) do
        if core:CheckNew() then
            return true
        end
    end
    return false
end

return XSmashBCoreManager