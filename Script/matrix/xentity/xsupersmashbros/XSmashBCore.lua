--===========================
--超限乱斗核心对象
--模块负责：吕天元
--===========================
---@class XSmashBCore
local XSmashBCore = XClass(nil, "XSmashBCore")

function XSmashBCore:Ctor(cfg)
    self:Reset()
    self.CoreCfg = cfg
end

function XSmashBCore:Reset()
    self.AtkLevel = 0
    self.LifeLevel = 0
    self.Star = 0
    self.CoreCfg = nil
end
--===============
--获取核心Id(SuperSmashBrosCore Id)
--===============
function XSmashBCore:GetId()
    return self.CoreCfg and self.CoreCfg.Id
end
--===============
--获取核心对应模式Id(SuperSmashBrosCore ModeId)
--===============
function XSmashBCore:GetModeId()
    return self.CoreCfg and self.CoreCfg.ModeId
end
--===============
--获取核心名称(SuperSmashBrosCore Name)
--===============
function XSmashBCore:GetName()
    return self.CoreCfg and self.CoreCfg.Name
end
--===============
--获取核心图标途径(SuperSmashBrosCore Icon)
--===============
function XSmashBCore:GetIcon()
    return self.CoreCfg and self.CoreCfg.Icon
end
--===============
--获取核心星级上限(SuperSmashBrosCore StarLimit)
--===============
function XSmashBCore:GetStarLimit()
    return self.CoreCfg and self.CoreCfg.StarLimit
end
--===============
--获取核心增幅上限(SuperSmashBrosCore StrongAttrLimit)
--===============
function XSmashBCore:GetStrongAttrLimit()
    return self.CoreCfg and self.CoreCfg.StrongAttrLimit
end
--===============
--获取解锁条件描述(SuperSmashBrosCore UnlockTips)
--===============
function XSmashBCore:GetUnlockTips()
    return self.CoreCfg and self.CoreCfg.UnlockTips
end
--===============
--获取核心攻击力增幅等级
--===============
function XSmashBCore:GetAtkLevel()
    return self.AtkLevel
end
--===============
--设置核心攻击力增幅等级
--===============
function XSmashBCore:SetAtkLevel(value)
    if not value or value < 0 then
        value = 0
    end
    self.AtkLevel = value
end
--===============
--获取核心生命值增幅等级
--===============
function XSmashBCore:GetLifeLevel()
    return self.LifeLevel
end
--===============
--设置核心生命值增幅等级
--===============
function XSmashBCore:SetLifeLevel(value)
    if not value or value < 0 then
        value = 0
    end
    self.LifeLevel = value
end
--===============
--检查属性增幅是否满值
--===============
function XSmashBCore:CheckAttrIsMax()
    return (self:GetAtkLevel() + self:GetLifeLevel()) >= self:GetStrongAttrLimit()
end
--===============
--获取核心星级
--===============
function XSmashBCore:GetStar()
    return self.Star + 1
end
--===============
--设置核心星级
--===============
function XSmashBCore:SetStar(value)
    if not value or value < XDataCenter.SuperSmashBrosManager.GetCoreStartLevel() then
        value = XDataCenter.SuperSmashBrosManager.GetCoreStartLevel()
    end
    self.Star = value
end
--===============
--获取核心是否上锁
--===============
function XSmashBCore:CheckIsLock()
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(self:GetModeId())
    return mode and not mode:CheckUnlock()
end
--===============
--获取核心所有技能配置列表(以技能星级排序)
--===============
function XSmashBCore:GetSkillCfgs()
    return XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Core2CoreLevelDic, self:GetId())
end
--===============
--获取核心当前星级技能配置
--===============
function XSmashBCore:GetCurrentSkillCfg()
    return self:GetSkillCfgByStar(self:GetStar())
end
--===============
--获取核心当前星级技能描述
--===============
function XSmashBCore:GetSkillDescription()
    local cfg = self:GetCurrentSkillCfg()
    return cfg and cfg.Description
end
--===============
--获取核心当前星级技能的升级描述
--===============
function XSmashBCore:GetSkillUpgradeDescription()
    local cfg = self:GetCurrentSkillCfg()
    return cfg and cfg.UpgradeDescription
end
--===============
--获取核心给定星级技能配置
--@param
--star : 要获取的技能的星级
--===============
function XSmashBCore:GetSkillCfgByStar(star)
    local skills = self:GetSkillCfgs()
    if skills then return skills[star - 1] end --这里减1是因为配置星数是从0开始的，而展示是从1开始的，这里统一使用展示用的从1开始的星数
    return {}
end
--===============
--检查核心是否满级
--===============
function XSmashBCore:CheckSkillIsMax()
    return self:GetStar() >= self:GetStarLimit()
end
function XSmashBCore:GetCostSkillConfig()
    return self:GetSkillCfgByStar(self:GetStar() + 1)
end
--===============
--获取核心消耗道具Id
--===============
function XSmashBCore:GetSkillCostItemId()
    local cfg = self:GetCostSkillConfig()
    return cfg and cfg.SpendMaterialId
end
--===============
--获取核心消耗道具数量
--===============
function XSmashBCore:GetSkillCostCount()
    local cfg = self:GetCostSkillConfig()
    return cfg and cfg.SpendMaterialCount
end
--===============
--获取核心消耗道具图标
--===============
function XSmashBCore:GetSkillCostItemIcon()
    local itemId = self:GetSkillCostItemId()
    return XDataCenter.ItemManager.GetItemIcon(itemId)
end
--===============
--检查是否是新核心
--===============
function XSmashBCore:CheckNew()
    local isLock = self:CheckIsLock()
    if isLock then return false end
    local isNew = XSaveTool.GetData(
        "SuperSmashBrosLocalData_NewCore_Id_" .. self:GetId() .. 
        "_Player_" .. XPlayer.Id .. 
        "_Activity_" .. XDataCenter.SuperSmashBrosManager.GetActivityId()
        ) == nil
    return isNew
end

return XSmashBCore