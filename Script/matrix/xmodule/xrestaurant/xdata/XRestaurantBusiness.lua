
local XRestaurantData = require("XModule/XRestaurant/XData/XRestaurantData")
local XRestaurantStaffMgt = require("XModule/XRestaurant/XData/XRestaurantStaffMgt")
local XRestaurantStorage = require("XModule/XRestaurant/XData/XRestaurantStorage")
local XRestaurantWorkbenchMgt = require("XModule/XRestaurant/XData/XRestaurantWorkbenchMgt")
local XRestaurantBuffMgt = require("XModule/XRestaurant/XData/XRestaurantBuffMgt")
local XRestaurantPerformMgt = require("XModule/XRestaurant/XData/XRestaurantPerformMgt")

-- Properties
--[[
    CurDay 当前经营天数
    RestaurantLv 餐厅等级
    OfflineBill  离线账单
    LastSettleTime  上次结算时间
    OfflineBillUpdateTime  账单更新时间
    AccelerateUseTimes 使用加速道具次数
    IsGetSignReward 是否领取签到奖励
    SignActivityId 签到活动id
    IsLevelUp 是否是升级
    
    LevelConditionChange 餐厅等级升级条件
    BuffRedPointMarkCount Buff红点
    MenuRedPointMarkCount 菜单红点
]]

---@class XRestaurantBusinessProperty
local Properties = {
    CurDay = "CurDay",
    RestaurantLv = "RestaurantLv",
    OfflineBill = "OfflineBill",
    LastSettleTime = "LastSettleTime",
    OfflineBillUpdateTime = "OfflineBillUpdateTime",
    AccelerateUseTimes = "AccelerateUseTimes",
    IsGetSignReward = "IsGetSignReward",
    SignActivityId = "SignActivityId",
    IsLevelUp = "IsLevelUp",
    LevelConditionChange = "LevelConditionChange",
    BuffRedPointMarkCount = "BuffRedPointMarkCount",
    MenuRedPointMarkCount = "MenuRedPointMarkCount",
    
    RunningPerformId = "RunningPerformId",
    RunningIndentId = "RunningIndentId",
    NotStartPerformId = "NotStartPerformId",
    NotStartIndentId = "NotStartIndentId",
}

---@class XRestaurantBusiness : XRestaurantData 餐厅活动数据
---@field StaffMgt XRestaurantStaffMgt
---@field Storage XRestaurantStorage
---@field WorkbenchMgt XRestaurantWorkbenchMgt
---@field BuffMgt XRestaurantBuffMgt
---@field PerformMgt XRestaurantPerformMgt
local XRestaurantBusiness = XClass(XRestaurantData, "XRestaurantBusiness")

function XRestaurantBusiness:InitData()
    self.Data = {
        CurDay = 0,
        RestaurantLv = 0,
        OfflineBill = 0,
        LastSettleTime = 0,
        OfflineBillUpdateTime = 0,
        AccelerateUseTimes = 0,
        SignActivityId = 0,
        IsGetSignReward = false,
        IsLevelUp = false,
        LevelConditionChange = 0,
        BuffRedPointMarkCount = 0,
        MenuRedPointMarkCount = 0,
        RunningPerformId = 0,
        RunningIndentId = 0,
        NotStartPerformId = 0,
        NotStartIndentId = 0,
    }
    self.StaffMgt = XRestaurantStaffMgt.New()
    self.Storage = XRestaurantStorage.New()
    self.WorkbenchMgt = XRestaurantWorkbenchMgt.New()
    self.BuffMgt = XRestaurantBuffMgt.New()
    self.PerformMgt = XRestaurantPerformMgt.New()
    
    self.NotifyPerformCb = function(notStartIndentId, runningIndentId, notStartPerformId, runningPerformId)
        self:SetProperty(Properties.NotStartIndentId, notStartIndentId)
        self:SetProperty(Properties.RunningIndentId, runningIndentId)
        self:SetProperty(Properties.NotStartPerformId, notStartPerformId)
        self:SetProperty(Properties.RunningPerformId, runningPerformId)
    end
end

function XRestaurantBusiness:ClearAll()
    self.Data = {
        CurDay = 0,
        RestaurantLv = 0,
        OfflineBill = 0,
        LastSettleTime = 0,
        OfflineBillUpdateTime = 0,
        AccelerateUseTimes = 0,
        SignActivityId = 0,
        IsGetSignReward = false,
        IsLevelUp = false,
        LevelConditionChange = 0,
        BuffRedPointMarkCount = 0,
        MenuRedPointMarkCount = 0,
        RunningPerformId = 0,
        RunningIndentId = 0,
        NotStartPerformId = 0,
        NotStartIndentId = 0,
    }
    self.StaffMgt = nil
    self.Storage = nil
    self.WorkbenchMgt = nil
    self.BuffMgt = nil
    self.PerformMgt = nil

    self.NotifyPerformCb = nil
end

function XRestaurantBusiness:GetPropertyNameDict()
    return Properties
end

function XRestaurantBusiness:UpdateData(notifyData)
    --更新天数
    self:UpdateOpenDays(notifyData.CurDay)
    --更新加速道具使用次数
    self:SetProperty(Properties.AccelerateUseTimes, notifyData.AccelerateUseTimes)
    --员工数据
    self.StaffMgt:UpdateData(notifyData.CharacterList)
    --仓库数据
    self.Storage:UpdateData(notifyData.StorageInfos)
    --更新等级
    self:UpdateLevel(notifyData.RestaurantLv)
    --更新Buff信息
    self.BuffMgt:UpdateData(notifyData.SectionBuffInfos, notifyData.UnlockSectionBuffs, notifyData.DefaultBuffs)
    --更新演出信息
    self:UpdatePerformInfos(notifyData.PerformInfos)
    --更新工作台
    self.WorkbenchMgt:UpdateData(notifyData.SectionInfos)
    --更新上次结算时间
    self:SetProperty(Properties.LastSettleTime, notifyData.LastSettleTime)
    --更新签到信息
    self:UpdateSignData(notifyData.IsGetSignReward, notifyData.SignActivityId)

    if self.ViewModel then
         self.ViewModel:UpdateViewModel()
    end
end

function XRestaurantBusiness:UpdateSettle(notifyData)
    --更新加速道具使用次数
    self:SetProperty(Properties.AccelerateUseTimes, notifyData.AccelerateUseTimes)
    --仓库数据
    self.Storage:UpdateData(notifyData.StorageInfos)
    --更新演出信息
    self:UpdatePerformInfos(notifyData.PerformInfos)
    --更新工作台
    self.WorkbenchMgt:UpdateData(notifyData.SectionInfos)
    --更新上次结算时间
    self:SetProperty(Properties.LastSettleTime, notifyData.LastSettleTime)
    if self.ViewModel then
        self.ViewModel:UpdateViewModel()
    end
end

function XRestaurantBusiness:UpdateAccount(offlineBill, offlineBillUpdateTime)
    --离线账单
    self:SetProperty(Properties.OfflineBill, offlineBill)
    --设置账单更新
    self:SetProperty(Properties.OfflineBillUpdateTime, offlineBillUpdateTime)
end

function XRestaurantBusiness:UpdateLevel(level)
    level = XMVCA.XRestaurant:GetSafeRestLevel(level)
    local oldLevel = self:GetLevel()
    
    if level == oldLevel then
        return
    end
    
    self:SetProperty(Properties.RestaurantLv, level)
end

function XRestaurantBusiness:UpdateOpenDays(curDay)
    curDay = curDay or 1
    self:SetProperty(Properties.CurDay, curDay)
end

function XRestaurantBusiness:UpdateSignData(isGetSignReward, signActivityId)
    self:SetProperty(Properties.IsGetSignReward, isGetSignReward)
    if XTool.IsNumberValid(signActivityId) then
        self:SetProperty(Properties.SignActivityId, signActivityId)
    end
end

function XRestaurantBusiness:UpdatePerformInfos(infos)
    self.PerformMgt:UpdateData(infos, self.NotifyPerformCb)
end

function XRestaurantBusiness:GetOpenDays()
    return self:GetProperty(Properties.CurDay)
end

function XRestaurantBusiness:GetLevel()
    return self:GetProperty(Properties.RestaurantLv)
end

function XRestaurantBusiness:GetAccelerateUseTimes()
    return self:GetProperty(Properties.AccelerateUseTimes)
end

function XRestaurantBusiness:GetOfflineBillUpdateTime()
    return self:GetProperty(Properties.OfflineBillUpdateTime)
end

function XRestaurantBusiness:GetOfflineBill()
    return self:GetProperty(Properties.OfflineBill)
end

function XRestaurantBusiness:GetWorkbenchData(areaType, index)
    return self.WorkbenchMgt:GetWorkbenchData(areaType, index)
end

function XRestaurantBusiness:GetProductData(areaType, productId)
    return self.Storage:GetProductData(areaType, productId)
end

function XRestaurantBusiness:GetStaffData(charId)
    return self.StaffMgt:GetStaffData(charId)
end

function XRestaurantBusiness:GetBuffData(buffId)
    return self.BuffMgt:GetBuffData(buffId)
end

function XRestaurantBusiness:CheckBuffUnlock(buffId)
    return self.BuffMgt:CheckBuffUnlok(buffId)
end

function XRestaurantBusiness:GetPerformData(performId)
    return self.PerformMgt:TryGetPerform(performId)
end

function XRestaurantBusiness:GetOrderActivityId()
    return self.PerformMgt:GetOrderActivityId()
end

function XRestaurantBusiness:GetUnlockIndentCount()
    return self.PerformMgt:GetUnlockCount(XMVCA.XRestaurant.PerformType.Indent)
end

function XRestaurantBusiness:GetUnlockPerformCount()
    return self.PerformMgt:GetUnlockCount(XMVCA.XRestaurant.PerformType.Perform)
end

function XRestaurantBusiness:GetSignActivityId()
    return self:GetProperty(Properties.SignActivityId)
end

function XRestaurantBusiness:IsGetSignReward()
    return self:GetProperty(Properties.IsGetSignReward)
end

function XRestaurantBusiness:UpdateLevelConditionEventChange()
    self:SetProperty(Properties.LevelConditionChange, self:GetProperty(Properties.LevelConditionChange) + 1)
end

function XRestaurantBusiness:UpdateBuffRedPointMarkCount()
    self:SetProperty(Properties.BuffRedPointMarkCount, self:GetProperty(Properties.BuffRedPointMarkCount) + 1)
end

function XRestaurantBusiness:UpdateMenuRedPointMarkCount()
    self:SetProperty(Properties.MenuRedPointMarkCount, self:GetProperty(Properties.MenuRedPointMarkCount) + 1)
end

function XRestaurantBusiness:IsLevelUp()
    return self:GetProperty(Properties.IsLevelUp)
end

function XRestaurantBusiness:MarkLevelUp(value)
    self:SetProperty(Properties.IsLevelUp, value)
end

function XRestaurantBusiness:GetGreaterLevelCharacterCount(level)
    return self.StaffMgt:GetGreaterLevelCharacterCount(level)
end

function XRestaurantBusiness:GetRunningIndent()
    local runId = self:GetProperty(Properties.RunningIndentId)
    if runId <= 0 then
        runId = self:GetProperty(Properties.NotStartIndentId)
    end
    if runId <= 0 then
        return
    end
    return self.PerformMgt:TryGetPerform(runId)
end

function XRestaurantBusiness:GetRunningPerform()
    local runId = self:GetProperty(Properties.RunningPerformId)
    if runId <= 0 then
        runId = self:GetProperty(Properties.NotStartPerformId)
    end
    if runId <= 0 then
        return
    end
    return self.PerformMgt:TryGetPerform(runId)
end

function XRestaurantBusiness:CheckPerformFinish(performId)
    local info = self.PerformMgt:TryGetPerform(performId)
    return info:IsFinish()
end

return XRestaurantBusiness