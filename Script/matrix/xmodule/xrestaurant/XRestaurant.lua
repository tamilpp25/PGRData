
local XRestaurantStaff = require("XModule/XRestaurant/XRestaurantStaff")
local XIngredient = require("XModule/XRestaurant/XProduct/XIngredient")
local XFood = require("XModule/XRestaurant/XProduct/XFood")
local XCashier = require("XModule/XRestaurant/XProduct/XCashier")

local XCookingWorkBench = require("XModule/XRestaurant/XWorkBench/XCookingWorkBench")
local XIngredientWorkBench = require("XModule/XRestaurant/XWorkBench/XIngredientWorkBench")
local XSalesWorkBench = require("XModule/XRestaurant/XWorkBench/XSalesWorkBench")
local XRestaurantOrder = require("XModule/XRestaurant/XRestaurantOrder")
local XRestaurantBuff = require("XModule/XRestaurant/XBuff/XRestaurantBuff")

local SimulationTimer
local SimulationDelay = XScheduleManager.SECOND
local LastSimulationTime = 0

local LuaMemoryLimit = 500 * 1024 --进入餐厅增加500M后会GC一次

---@class XRestaurant : XDataEntityBase 战双厨房玩法活动数据对象
---@field private _Id number 活动Id
---@field private _Level number 餐厅等级
---@field private _IsLevelUp boolean 餐厅是否升级
---@field private _CookingWorkBenches XCookingWorkBench[] 已解锁烹饪台
---@field private _IngredientWorkBenches XIngredientWorkBench[] 已解备菜台
---@field private _SalesWorkBenches XSalesWorkBench[] 已解锁售卖台
---@field private _StaffMap table<number, XRestaurantStaff> 员工列表
---@field private _FoodMap table<number, XFood> 食物列表
---@field private _IngredientMap table<number, XIngredient> 食材列表
---@field private _Cashier XCashier 收银台
---@field private _OfflineBill number 离线账单
---@field private _OfflineBillUpdateTime number 上次离开餐厅时间
---@field private _CurDay number 活动开放天数
---@field private _AccelerateUseTimes number 当天加速道具使用次数
---@field private _IsGetSignReward boolean 是否领取签到奖励
---@field private _EventLevelConditionChange number 升级所需条件改变事件
---@field private _UnlockIngredient table<number, boolean> 已解锁食材
---@field private _UnlockFood table<number, boolean> 已解锁食物
---@field private _EnterRoomMemory number 进入餐厅时的Lua内存
---@field private _OrderInfo XRestaurantOrder 订单数据
---@field private _BuffMap table<number, XRestaurantBuff> 已经解锁Buff
---@field private _AreaTypeBuff table<number, XRestaurantBuff> 每个区域对应的BuffId
---@field private _AreaSortMark table<number, boolean> 每个区域工作台排序标记
local XRestaurant = XClass(XDataEntityBase, "XRestaurant")

local default = {
    _Id = 0, --活动Id,
    _Level = 0,
    _IsLevelUp = false,
    _CookingWorkBenches = {},
    _IngredientWorkBenches = {},
    _SalesWorkBenches = {},
    _StaffMap = {},
    _FoodMap = {},
    _IngredientMap = {},
    _Cashier = nil,
    _UnlockIngredient = {},
    _UnlockFood = {},
    _OfflineBill = 0,
    _OfflineBillUpdateTime = 0,
    _CurDay = 0,
    _AccelerateUseTimes = 0,
    _IsGetSignReward = false,
    _EventLevelConditionChange = 0,
    _OrderInfo = nil,
    _AreaTypeBuff = {},
    _BuffMap = {},
    _AreaSortMark = {},
    _BuffRedPointMarkCount = 0,
    _MenuRedPointMarkCount = 0,
    
    _EnterRoomMemory = 0,
    _UiMainSorting = -1,
}

function XRestaurant:Ctor(id)
    self:Init(default, id)
end

--- 初始化持久数据
---@private
---@param id number 活动Id
---@return nil
--------------------------
function XRestaurant:InitData(id)
    self:SetProperty("_Id", id)
    self:_InitStaffList()
    self:_InitProductList()
    self._Cashier = XCashier.New()
end 

--- 获取商店Id
---@return number 商店Id
--------------------------
function XRestaurant:GetShopId()
    return XRestaurantConfigs.GetShopId(self._Id)
end

--- 活动名
---@return string 活动名
--------------------------
function XRestaurant:GetActivityName()
    return XRestaurantConfigs.GetActivityName(self._Id)
end

--- 获取结束时间
---@return number 结束时间
--------------------------
function XRestaurant:GetBusinessEndTime()
    return XRestaurantConfigs.GetActivityEndTime(self._Id)
end

--- 获取开始时间
---@return number 开始时间
--------------------------
function XRestaurant:GetBusinessStartTime()
    return XRestaurantConfigs.GetActivityStartTime(self._Id)
end

function XRestaurant:GetShopStartTime()
    return XRestaurantConfigs.GetShopStartTime(self._Id)
end

function XRestaurant:GetShopEndTime()
    return XRestaurantConfigs.GetShopEndTime(self._Id)
end

--- 获取任务组列表
---@return number[] 任务组Id列表
--------------------------
function XRestaurant:GetTimeLimitTaskIds()
    return XRestaurantConfigs.GetTimeLimitTaskIds(self._Id)
end

-- 食谱任务
function XRestaurant:GetRecipeTaskId()
    return XRestaurantConfigs.GetRecipeTaskId(self._Id)
end

--- 活动是否开启
---@return boolean 是否开启
--------------------------
function XRestaurant:IsOpen()
    if not XTool.IsNumberValid(self._Id) then
        return false
    end
    
    return self:IsInBusiness() or self:IsShopOpen()
end

--- 餐厅是否营业中
---@return boolean
--------------------------
function XRestaurant:IsInBusiness()
    return XRestaurantConfigs.CheckActivityInTime(self._Id)
end

--- 商店是否开放中
---@return boolean
--------------------------
function XRestaurant:IsShopOpen()
    return XRestaurantConfigs.CheckShopInTime(self._Id)
end

--- 活动账单结算时间
---@return number
--------------------------
function XRestaurant:GetOfflineBillTime()
    return XRestaurantConfigs.GetActivityOfflineBillTime(self._Id)
end

--- 是否展示离线账单
---@return boolean
--------------------------
function XRestaurant:IsShowOfflineBill()
    if self:IsFirstEnterRoom() then
        return false
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local billTime = self:GetOfflineBillTime()
    if nowTime - self._OfflineBillUpdateTime < billTime then
        return false
    end
    return true
end

--- 首次进入餐厅
---@return boolean
--------------------------
function XRestaurant:IsFirstEnterRoom()
    return not XTool.IsNumberValid(self._OfflineBillUpdateTime)
end

function XRestaurant:GetAccelerateUseLimit()
    return XRestaurantConfigs.GetActivityAccelerateUseLimit(self._Id)
end

function XRestaurant:GetAccelerateTime()
    return XRestaurantConfigs.GetActivityAccelerateTime(self._Id)
end

function XRestaurant:GetAccelerateCount()
    return XDataCenter.ItemManager.GetCount(XRestaurantConfigs.ItemId.RestaurantAccelerate)
end

function XRestaurant:IsAccelerateUpperLimit()
    return self._AccelerateUseTimes >= self:GetAccelerateUseLimit()
end

function XRestaurant:GetUrgentTime()
    return XRestaurantConfigs.GetActivityUrgentTime(self._Id)
end

--- 餐厅升级
---@param level number 升级后的等级
---@return void
--------------------------
function XRestaurant:LevelUp(level)
    level = math.max(XRestaurantConfigs.LevelRange.Min, level)
    local oldLevel = self._Level
    if level == oldLevel then
        return
    end
    
    self:SetProperty("_Level", level)
    self._UnlockIngredient = XRestaurantConfigs.GetUnlockProduct(level, XRestaurantConfigs.GetUnlockIngredient)
    self._UnlockFood = XRestaurantConfigs.GetUnlockProduct(level, XRestaurantConfigs.GetUnlockFood)
    self:_InitWorkBench()

    -- 先更新食材
    for _, ingredient in pairs(self._IngredientMap) do
        ingredient:OnRestaurantLevelUp(level)
    end
    -- 再更新食物
    for _, food in pairs(self._FoodMap) do
        food:OnRestaurantLevelUp(level)
    end
    
    self._Cashier:OnRestaurantLevelUp(level)

    if oldLevel ~= 0 and level > oldLevel then
        self:SetProperty("_IsLevelUp", true)
    end
end

--全部工作台停止工作
function XRestaurant:StopAll()
    for _, bench in pairs(self._IngredientWorkBenches) do
        bench:Stop()
    end

    for _, bench in pairs(self._CookingWorkBenches) do
        bench:Stop()
    end

    for _, bench in pairs(self._SalesWorkBenches) do
        bench:Stop()
    end
end

--- 更新员工信息
---@param staffList Server.XRestaurantCharacter[] 员工信息
---@return void
--------------------------
function XRestaurant:UpdateStaffInfo(staffList)
    for _, info in ipairs(staffList or {}) do
        local charId = info.CharacterId
        local staff = self._StaffMap[charId]
        if not staff then
            XLog.Warning("XRestaurant:UpdateStaffInfo: not found staff!!! staff Id = " .. tostring(charId))
            goto continue
        end
        staff:UpdateInfo(true, info.CharacterLv)
        ::continue::
    end
end

--- 更新仓库
---@param storageInfo Server.XRestaurantStorage
---@return void
--------------------------
function XRestaurant:UpdateStorageInfo(storageInfo)
    if not storageInfo then
        return
    end

    for _, info in ipairs(storageInfo or {}) do
        local areaType = info.SectionType
        local id = info.ProductId
        if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
            local ingredient = self._IngredientMap[id]
            if not ingredient then
                ingredient = XIngredient.New(id)
                self._IngredientMap[id] = ingredient
            end
            ingredient:SetProperty("_Count", info.Count)
        elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
            local food = self._FoodMap[id]
            if not food then
                food = XFood.New(id)
                self._FoodMap[id] = food
            end
            food:SetProperty("_Count", info.Count)
        elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
            self._Cashier:SetProperty("_Count", info.Count)
        end
    end
end

--- 更新工作台状态
---@param sectionInfos Server.XRestaurantSection[]
---@return void
--------------------------
function XRestaurant:UpdateWorkBench(sectionInfos)
    if not sectionInfos then
        return
    end
    for _, info in ipairs(sectionInfos or {}) do
        local areaType = info.SectionType
        local index = info.Index
        local list = self._AreaMap2Benches[areaType]
        if not XTool.IsTableEmpty(list) then
            local bench = list[index]
            bench:OnNotify(info)
        end
    end
end

--- 更新结算
---@param offlineBill number 离线账单
---@param offlineBillUpdateTime number 上次离开餐厅时间
--------------------------
function XRestaurant:UpdateSettle(offlineBill, offlineBillUpdateTime)
    self:SetProperty("_OfflineBill", offlineBill)
    self:SetProperty("_OfflineBillUpdateTime", offlineBillUpdateTime)
end

--- 更新热销
---@param currentDay number 当前活动天数
---@return void
--------------------------
function XRestaurant:UpdateHotSale(currentDay)
    self:SetProperty("_CurDay", currentDay or 1)
    for _, food in pairs(self._FoodMap or {}) do
        food:UpdateHotSale(false, 0)
    end
    local list = XRestaurantConfigs.GetHotSaleDataList(self._CurDay)
    for _, info in pairs(list or {}) do
        local id = info.Id
        if XTool.IsNumberValid(id) then
            local food = self._FoodMap[id]
            food:UpdateHotSale(true, info.Addition)
        end
    end
end

function XRestaurant:UpdateSignData(isGetSignReward, signActivityId)
    self:SetProperty("_IsGetSignReward", isGetSignReward)
    if XTool.IsNumberValid(signActivityId) then
        self:SetProperty("_SignActivityId", signActivityId)
    end
end

function XRestaurant:UpdateOrderInfo(orderActivityId, orderInfos)
    if not self._OrderInfo or self._OrderInfo:GetId() ~= orderActivityId then
        self._OrderInfo = XRestaurantOrder.New(self._Id)
    end
    self._OrderInfo:UpdateData(orderInfos)
end

function XRestaurant:UpdateBuff(areaTypeBuffInfo, unlockBuffs, defaultBuffs)
    local map = {}
    for _, info in ipairs(areaTypeBuffInfo) do
        map[info.SectionType] = info.BuffId
    end
    --TODO CodeMoon, 不知道这里需不需要
    for _, id in ipairs(defaultBuffs) do
        local sectionType = XRestaurantConfigs.GetBuffAreaType(id)
        if not map[sectionType] then
            map[sectionType] = id
        end 
    end
    self:SetProperty("_AreaTypeBuff", map)

    unlockBuffs = appendArray(unlockBuffs, defaultBuffs)
    for _, id in ipairs(unlockBuffs) do
        local buff = self._BuffMap[id]
        if not buff then
            buff = XRestaurantBuff.New(id)
            self._BuffMap[id] = buff
        end
        buff:Unlock()
    end
end

function XRestaurant:OnNotify(notifyData)
    self:SetProperty("_AccelerateUseTimes", notifyData.AccelerateUseTimes)
    --初始化/更新 员工数据
    self:UpdateStaffInfo(notifyData.CharacterList)
    --初始化/更新 产品信息
    self:UpdateStorageInfo(notifyData.StorageInfos)
    --更新餐厅等级
    self:LevelUp(notifyData.RestaurantLv)
    --更新Buff信息
    self:UpdateBuff(notifyData.SectionBuffInfos, notifyData.UnlockSectionBuffs, notifyData.DefaultBuffs)
    --更新订单信息
    self:UpdateOrderInfo(notifyData.OrderActivityId, notifyData.OrderInfos)
    --更新热销
    self:UpdateHotSale(notifyData.CurDay)
    --更新工作台信息
    self:UpdateWorkBench(notifyData.SectionInfos)
    --更新结算
    self:UpdateSettle(notifyData.OfflineBill, notifyData.LastSettleTime)
    --更新签到信息
    self:UpdateSignData(notifyData.IsGetSignReward, notifyData.SignActivityId)
end

function XRestaurant:UpdateLuaMemory()
    local memory = CS.XLuaEngine.Env.Memroy
    self:SetProperty("_EnterRoomMemory", memory)
end

--region   ------------------getter and setter start-------------------

--- 获取所有产品，包括数量为0以及未解锁
---@param areaType number
---@return XRestaurantProduct[]
--------------------------
function XRestaurant:GetAllProductList(areaType)
    local map = {}
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        map = self._IngredientMap
    else
        map = self._FoodMap
    end
    local list = {}
    for _, product in pairs(map or {}) do
        if product then
            table.insert(list, product)
        end
    end
    return list
end

--- 获取所有存货数量大于0产品
---@param areaType number
---@return XRestaurantProduct[]
--------------------------
function XRestaurant:GetNotZeroProductList(areaType)
    local map = {}
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        map = self._IngredientMap
    else
        map = self._FoodMap
    end
    local list = {}
    for _, product in pairs(map or {}) do
        if product and product:GetProperty("_Count") > 0 then
            table.insert(list, product)
        end
    end
    return list
end

--- 获取所有已解锁产品列表
---@param areaType number
---@return XRestaurantProduct[]
--------------------------
function XRestaurant:GetUnlockProductList(areaType)
    local map = {}
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        map = self._IngredientMap
    else
        map = self._FoodMap
    end
    local list = {}
    for _, product in pairs(map or {}) do
        if product and product:IsUnlock() then
            table.insert(list, product)
        end
    end
    return list
end

--- 已解锁产品个数
---@param areaType number
---@return number
--------------------------
function XRestaurant:GetUnlockProductCount(areaType)
    local count = 0
    local map = {}
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        map = self._IngredientMap
    else
        map = self._FoodMap
    end
    for _, product in pairs(map or {}) do
        if product and product:IsUnlock() then
            count = count + 1
        end
    end
    
    return count
end

--- 仓库产品列表
---@param areaType number
---@return XRestaurantProduct[]
--------------------------
function XRestaurant:GetSortStorageProductList(areaType)
    local list = self:GetUnlockProductList(areaType)
    if XTool.IsTableEmpty(list) then
        return list
    end
    local isSortByQuality = not XRestaurantConfigs.CheckIsIngredientArea(areaType)
    table.sort(list, function(a, b)
        if isSortByQuality then
            local qualityA = a:GetProperty("_Quality")
            local qualityB = b:GetProperty("_Quality")
            if qualityA ~= qualityB then
                return qualityA > qualityB
            end
        end
        return a:GetProperty("_Id") < b:GetProperty("_Id")
    end)
    
    return list
end

--- 获取产品
---@param areaType number
---@param id number
---@return XRestaurantProduct
--------------------------
function XRestaurant:GetProduct(areaType, id)
    local map = {}
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        map = self._IngredientMap
    else
        map = self._FoodMap
    end
    local product = map[id]
    if not product then
        XLog.Error("XRestaurant:GetProduct: not found product area type = "
                .. tostring(areaType) .. " Id = " .. tostring(id))
        return {}
    end
    return product
end

--- 获取已解锁留言信息
---@return XRestaurantOrderInfo[]
--------------------------
function XRestaurant:GetUnlockOrderInfoList()
    if not self._OrderInfo then
        return {}
    end
    return self._OrderInfo:GetUnlockInfoList()
end

--- 员工列表
---@return XRestaurantStaff[]
--------------------------
function XRestaurant:GetStaffList(areaType)
    local list = {}
    for _, staff in pairs(self._StaffMap or {}) do
        if areaType == 0 or staff:IsAdditionByAreaTypeWithMaxLevel(areaType) then
            table.insert(list, staff)
        end
    end
    return list
end

--- 已招募员工
---@return XRestaurantStaff[]
function XRestaurant:GetRecruitStaffList()
    ---@type XRestaurantStaff[]
    local list = {}
    for _, staff in pairs(self._StaffMap or {}) do
        local recruit = staff:GetProperty("_IsRecruit")
        if recruit then
            table.insert(list, staff)
        end
    end
    
    return list
end

--- 空闲员工
---@return XRestaurantStaff[]
--------------------------
function XRestaurant:GetFreeStaffList()
    local list = {}
    for _, staff in pairs(self._StaffMap or {}) do
        if staff:GetProperty("_IsRecruit") and not staff:IsWorking() then
            table.insert(list, staff)
        end
    end
    return list
end

--- 空闲人数
---@return number
--------------------------
function XRestaurant:GetFreeStaffCount()
    local count = 0
    for _, staff in pairs(self._StaffMap or {}) do
        if staff:GetProperty("_IsRecruit") and not staff:IsWorking() then
            count = count + 1
        end
    end
    return count
end

--- 在工作台上的人数
---@return number
--------------------------
function XRestaurant:GetOnBenchStaffCount()
    local count = 0
    for _, staff in pairs(self._StaffMap or {}) do
        if staff:GetProperty("_IsRecruit") and not staff:IsFree() then
            count = count + 1
        end
    end
    return count
end

--- 获取大于等级当前等级的员工
---@param level number
---@return XRestaurantStaff[]
--------------------------
function XRestaurant:GetStaffListByMinLevel(level)
    ---@type XRestaurantStaff[]
    local list = {}

    for _, staff in pairs(self._StaffMap or {}) do
        local recruit = staff:GetProperty("_IsRecruit")
        local lv = staff:GetProperty("_Level")
        if recruit and lv >= level then
            table.insert(list, staff)
        end
    end
    return list
end

--- 已招募员工并排序
---@return XRestaurantStaff[]
function XRestaurant:GetSortRecruitStaffList(areaType, productId)
    ---@type XRestaurantStaff[]
    local list = self:GetRecruitStaffList()
    
    local buff = self:GetAreaBuff(areaType)
    table.sort(list, function(a, b) 
        local isWorkingA = not a:IsFree()
        local isWorkingB = not b:IsFree()
        if isWorkingA ~= isWorkingB then
            return isWorkingB
        end
        
        local idA = a:GetProperty("_Id") 
        local idB = b:GetProperty("_Id")
        
        local buffAdditionA = buff and buff:GetEffectAddition(areaType, a:GetProperty("_Id"), productId) or 0
        local buffAdditionB = buff and buff:GetEffectAddition(areaType, b:GetProperty("_Id"), productId) or 0

        local additionA = a:GetSkillAddition(areaType, productId)
        local additionB = b:GetSkillAddition(areaType, productId)
        
        local totalA = buffAdditionA + additionA
        local totalB = buffAdditionB + additionB

        if totalA ~= totalB then
            return totalA > totalB
        end
        
        if additionA ~= additionB then
            return additionA > additionB
        end

        if buffAdditionA ~= buffAdditionB then
            return buffAdditionA > buffAdditionB
        end
        
        local levelA = a:GetProperty("_Level")
        local levelB = b:GetProperty("_Level")
        if levelA ~= levelB then
            return levelA > levelB
        end
        
        return idA < idB
    end)
    return list
end

--- 员工视图数据
---@param characterId number 员工Id
---@return XRestaurantStaff
--------------------------
function XRestaurant:GetStaffViewModel(characterId)
    local staff = self._StaffMap[characterId]
    if not staff then
        XLog.Error("XRestaurant:UpdateStaffInfo: not found staff!!! staff Id = " .. tostring(characterId))
        return {}
    end
    return staff
end

--- 获取当前区域正在工作的员工列表
---@param areaType number
---@return XRestaurantStaff[]
--------------------------
function XRestaurant:GetWorkingStaff(areaType)
    local map
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        map = self._IngredientWorkBenches
    elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
        map = self._CookingWorkBenches
    elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
        map = self._SalesWorkBenches
    end
    if not map then
        return {}
    end
    local list = {}
    for _, bench in pairs(map) do
        if not bench:IsFree() then
            table.insert(list, bench:GetCharacter())
        end
    end
    return list
end

--- 获取工作台视图数据
---@param areaType number
---@param index number
---@return XRestaurantWorkBench
--------------------------
function XRestaurant:GetWorkBenchViewModel(areaType, index, ignoreTip)
    local list = self._AreaMap2Benches[areaType]
    if not list then
        XLog.Error("XRestaurant:GetWorkBenchViewModel: not found work bench area type = " .. tostring(areaType))
        return {}
    end
    local bench = list[index]
    if not bench and not ignoreTip then
        XLog.Error("XRestaurant:GetWorkBenchViewModel: not found work bench area type = " 
                .. tostring(areaType) .. " Index = " .. tostring(index))
        return {}
    end
    return bench
end

function XRestaurant:GetUnlockWorkBenchList(areaType)
    return self._AreaMap2Benches[areaType]
end

function XRestaurant:CheckFoodUnlock(id)
    return self._UnlockFood[id] and true or false
end

function XRestaurant:CheckIngredientUnlock(id)
    return self._UnlockIngredient[id] and true or false
end

function XRestaurant:IsUrgentProduct(areaType, id)
    if not XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        return false
    end
    
    local produceSpeed = self:GetProduceTotalSpeed(areaType, id)
    local consumeSpeed = self:GetConsumeTotalSpeed(areaType, id)
    --未生产，未消耗
    if produceSpeed == 0 and consumeSpeed == 0 then
        return false
    end
    --生产速度大于等于消耗速度
    if produceSpeed >= consumeSpeed then
        return false
    end
    local urgentTime = self:GetUrgentTime()
    local product = self:GetProduct(areaType, id)
    local count = product:GetProperty("_Count")
    local second = (count / (consumeSpeed - produceSpeed)) * 3600
    
    return second <= urgentTime
end

--- 获取产品的生产总速
---@param areaType number 产品类型
---@param productId number
---@param timeUnit number
---@return number
--------------------------
function XRestaurant:GetProduceTotalSpeed(areaType, productId, timeUnit) 
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        return self:_GetIngredientProduceTotalSpeed(productId, timeUnit)
    elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
        return self:_GetFoodProduceTotalSpeed(productId, timeUnit)
    elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
        return self:_GetSaleProduceTotalSpeed(productId, timeUnit)
    end
    return 0
end

--- 获取产品的消耗总体速度
---@param areaType number 产品类型
---@param productId number
---@param timeUnit number
---@return number
--------------------------
function XRestaurant:GetConsumeTotalSpeed(areaType, productId, timeUnit)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    timeUnit = timeUnit or XRestaurantConfigs.TimeUnit.Hour
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        return self:_GetIngredientConsumeTotalSpeed(productId, timeUnit)
    elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
        return self:_GetFoodConsumeTotalSpeed(productId, timeUnit)
    elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
        return self:_GetSaleConsumeTotalSpeed(productId, timeUnit)
    end
    return 0
end

function XRestaurant:GetWorkBenchPreviewTip(areaType, productId, timeUnit)
    local produce = self:GetProduceTotalSpeed(areaType, productId, timeUnit)
    local consume = self:GetConsumeTotalSpeed(areaType, productId, timeUnit)
    if produce == 0 and consume == 0 then
        return true, ""
    end
    local product = self:GetProduct(areaType, productId)
    local subSpeed = produce - consume
    local freeCount = subSpeed > 0 and product:GetFreeCapacity() or product:GetProperty("_Count")
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        return subSpeed > 0, XRestaurantConfigs.GetIngredientStoragePreviewTip(produce, consume, freeCount)
    elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
        --消耗完毕或者满仓速度
        local stop = freeCount / math.abs(produce - consume)
        if not product then
            return stop
        end
        local list = product:GetProperty("_Ingredients") or {}
        local cStop = stop
        for _, consume in pairs(list) do
            local ingredientId = consume:GetId()
            local ingredient = self:GetProduct(XRestaurantConfigs.AreaType.IngredientArea, ingredientId)
            local cSpeed = ingredient:GetProperty("_Count") / self:_GetIngredientConsumeTotalSpeed(ingredientId, timeUnit)
            cStop = math.min(cStop, cSpeed)
        end
        local increase = subSpeed > 0 and stop <= cStop
        local isZero = cStop <= XRestaurantConfigs.Inaccurate and math.abs(subSpeed) <= XRestaurantConfigs.Inaccurate
        return increase, XRestaurantConfigs.GetCookStoragePreviewTip(increase, stop > cStop, isZero, cStop)
        
    elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
        local price = self:GetCashierTotalPrice(timeUnit)
        freeCount = self._Cashier:GetFreeCapacity()
        --收银台满
        local fullTime = freeCount / price
        --售卖完毕
        local consumeTime = product:GetProperty("_Count") / consume
        
        return fullTime < consumeTime, XRestaurantConfigs.GetSaleStoragePreviewTip(fullTime, consumeTime)
    end
end

--- 收银台总收益
---@param timeUnit number 单位时间，默认小时
---@return number
--------------------------
function XRestaurant:GetCashierTotalPrice(timeUnit)
    local price = 0
    
    for _, bench in pairs(self._SalesWorkBenches or {}) do
        local state = bench:GetProperty("_State")
        if state == XRestaurantConfigs.WorkState.Free then
            goto continue
        end
        price = price + bench:GetFoodFinalPrice(timeUnit)
        ::continue::
    end
    return math.ceil(price)
end

--- 获取签到开始时间
---@return number|nil
--------------------------
function XRestaurant:GetSignActivityStartTime()
    return XRestaurantConfigs.GetSignActivityStartTime(self._Id)
end

--- 获取签到结束时间
---@return number
--------------------------
function XRestaurant:GetSignActivityEndTime()
    return XRestaurantConfigs.GetSignActivityEndTime(self._Id)
end

--- 判断是否在签到时间内
---@param defaultOpen boolean
---@return boolean
--------------------------
function XRestaurant:CheckSignActivityInTime(defaultOpen)
    return XRestaurantConfigs.CheckSignActivityInTime(self._Id, defaultOpen)
end

--- 获取签到活动名称
---@return number
--------------------------
function XRestaurant:GetSignActivityName()
    return XRestaurantConfigs.GetSignActivityName(self._Id)
end

--- 获取今天是否能进行签到
---@return boolean
--------------------------
function XRestaurant:GetIsGetSignReward()
    return self._IsGetSignReward
end

--- 获取第X天签到的npcId
---@return number
function XRestaurant:GetSignCurDay()
    if not self:CheckSignActivityInTime(false) then
        return 0
    end
    local day = XTime.GetDayCountUntilTime(XRestaurantConfigs.GetSignActivityStartTime(self._Id), true)
    return day + 1
end

--- 获取第X天签到的奖励
---@return number
--------------------------
function XRestaurant:GetSignActivityRewardId()
    return XRestaurantConfigs.GetSignActivityRewardId(self._Id, self:GetSignCurDay())
end

--- 获取第X天签到的npc立绘Url
---@return string
--------------------------
function XRestaurant:GetSignActivityNpcImgUrl()
    return XRestaurantConfigs.GetSignActivityNpcImgUrl(self._Id, self:GetSignCurDay())
end

--- 获取第X天签到的奖励
---@return string
--------------------------
function XRestaurant:GetSignActivitySignDesc()
    return XUiHelper.ConvertLineBreakSymbol(XRestaurantConfigs.GetSignActivitySignDesc(self._Id, self:GetSignCurDay()))
end

--- 获取第X天签到的回复文本
---@return string
--------------------------
function XRestaurant:GetSignActivityReplyBtnDesc()
    return XRestaurantConfigs.GetSignActivityReplyBtnDesc(self._Id, self:GetSignCurDay())
end

--- 获取当前订单信息
---@return XRestaurantOrderInfo
--------------------------
function XRestaurant:GetTodayOrderInfo()
    if not self._OrderInfo then
        return
    end
    return self._OrderInfo:GetTodayOrderInfo()
end

function XRestaurant:CheckOrderFinish()
    local orderInfo = self:GetTodayOrderInfo()
    if not orderInfo then
        return false
    end
    local infos = XRestaurantConfigs.GetOrderFoodInfos(orderInfo:GetId())
    local finish = true
    for _, info in ipairs(infos) do
        local food = self:GetProduct(XRestaurantConfigs.AreaType.FoodArea, info.Id)
        local hasCount = food and food:GetProperty("_Count") or 0
        if hasCount < info.Count then
            finish = false
            break
        end
    end
    return finish
end

function XRestaurant:GetOrderActivityId()
    if not self._OrderInfo then
        return 0
    end
    return self._OrderInfo:GetId()
end

function XRestaurant:GetBuff(buffId)
    local buff = self._BuffMap[buffId]
    if not buff then
        buff = XRestaurantBuff.New(buffId)
        self._BuffMap[buffId] = buff
    end
    return buff
end

function XRestaurant:GetAreaBuffId(areaType)
    if not areaType then
        return
    end
    return self._AreaTypeBuff[areaType]
end

function XRestaurant:GetAreaBuff(areaType)
    local buffId = self:GetAreaBuffId(areaType)
    if not XTool.IsNumberValid(buffId) then
        return
    end
    return self:GetBuff(buffId)
end

function XRestaurant:SetAreaBuffId(areaType, buffId)
    local map = self._AreaTypeBuff
    map[areaType] = buffId    
    self:SetProperty("_AreaTypeBuff", map)
end

function XRestaurant:CheckAreaBuffUnlock(areaType)
    local minLevel = XRestaurantConfigs.GetAreaBuffUnlockMinLevel(areaType)
    return self._Level >= minLevel
end

--endregion------------------getter and setter finish------------------

--region   ------------------private start-------------------

---@private
function XRestaurant:_InitStaffList()
    local characters = XRestaurantConfigs.GetCharacters()
    local staffMap = {}
    for id, _ in pairs(characters or {}) do
        ---@type XRestaurantStaff
        local staff = XRestaurantStaff.New(id)
        staff:UpdateInfo(XRestaurantConfigs.IsFreeCharacter(id), 1)
        staffMap[id] = staff
    end 
    self:SetProperty("_StaffMap", staffMap)
end

function XRestaurant:_InitProductList()
    local ingredients = XRestaurantConfigs.GetIngredients()

    local ingredientMap = {}
    for id, _ in pairs(ingredients or {}) do
        local ingredient = XIngredient.New(id)
        ingredientMap[id] = ingredient
    end

    local foods = XRestaurantConfigs.GetFoods()
    local foodMap = {}
    for id, _ in pairs(foods or {}) do
        local food = XFood.New(id)
        foodMap[id] = food
    end
    
    self:SetProperty("_IngredientMap", ingredientMap)
    self:SetProperty("_FoodMap", foodMap)
end

function XRestaurant:_InitWorkBench()
    local level = self._Level

    local ingredientCount = XRestaurantConfigs.GetIngredientCounterNum(level)
    local foodCount = XRestaurantConfigs.GetFoodCounterNum(level)
    local saleCount = XRestaurantConfigs.GetSaleCounterNum(level)
    
    local initBench = function(count, class, list)
        for i = 1, count do
            local bench = list[i] or class.New(i)
            list[i] = bench
        end
    end

    initBench(ingredientCount, XIngredientWorkBench, self._IngredientWorkBenches)
    initBench(foodCount, XCookingWorkBench, self._CookingWorkBenches)
    initBench(saleCount, XSalesWorkBench, self._SalesWorkBenches)

    ---@type table<number, XRestaurantWorkBench[]>
    self._AreaMap2Benches = {
        [XRestaurantConfigs.AreaType.IngredientArea] = self._IngredientWorkBenches,
        [XRestaurantConfigs.AreaType.FoodArea] = self._CookingWorkBenches,
        [XRestaurantConfigs.AreaType.SaleArea] = self._SalesWorkBenches,
    }
end

--- 材料生产速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurant:_GetIngredientProduceTotalSpeed(productId, timeUnit)
    local speed = 0
    --生产无需原材料
    for _, bench in pairs(self._IngredientWorkBenches) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end

        --未生产目标物品
        if bench:GetProperty("_ProductId") ~= productId then
            goto continue
        end
        
        speed = speed + bench:GetProductiveness(timeUnit)
        
        ::continue::
    end
    
    return speed
end

--- 材料消耗速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurant:_GetIngredientConsumeTotalSpeed(productId, timeUnit)
    local speed = 0
    for _, bench in pairs(self._CookingWorkBenches) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end
        speed = speed + bench:GetConsumption(productId, timeUnit)
        
        ::continue::
    end
    
    return speed
end

--- 食物生产速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurant:_GetFoodProduceTotalSpeed(productId, timeUnit)
    local speed = 0
    for _, bench in pairs(self._CookingWorkBenches) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end

        --未生产目标物品
        if bench:GetProperty("_ProductId") ~= productId then
            goto continue
        end
        speed = speed + bench:GetProductiveness(timeUnit)

        ::continue::
    end
    return speed
end

function XRestaurant:_GetFoodConsumeTotalSpeed(productId, timeUnit)
    local speed = 0
    for _, bench in pairs(self._SalesWorkBenches) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end
        
        speed = speed + bench:GetConsumption(productId, timeUnit)
        ::continue::
    end
    
    return speed
end

function XRestaurant:_GetSaleProduceTotalSpeed(productId, timeUnit)
    return 0
end

function XRestaurant:_GetSaleConsumeTotalSpeed(productId, timeUnit)
    return self:_GetFoodConsumeTotalSpeed(productId, timeUnit)
end

--endregion------------------private finish------------------

--region   ------------------simulation start-------------------

function XRestaurant:StartSimulation()
    if not SimulationTimer then
        LastSimulationTime = XTime.GetServerNowTimestamp()
        SimulationTimer = XScheduleManager.ScheduleForever(function()
            self:Simulation()
        end, XScheduleManager.SECOND, SimulationDelay)
    end
end

function XRestaurant:StopSimulation()
    if SimulationTimer then
        XScheduleManager.UnSchedule(SimulationTimer)
        SimulationTimer = nil
    end
end

function XRestaurant:Simulation()
    --每秒执行一次
    local now = XTime.GetServerNowTimestamp()
    local second = now - LastSimulationTime
    
    local room = XDataCenter.RestaurantManager.GetRoom()
    if room then
        room:Simulation(now)
    end
    
    local sort = self:SortSimulationWorkBench(self._IngredientWorkBenches, XRestaurantConfigs.AreaType.IngredientArea)
    for _, ingredient in pairs(sort) do
        ingredient:Simulation(second)
    end

    sort = self:SortSimulationWorkBench(self._CookingWorkBenches, XRestaurantConfigs.AreaType.FoodArea)
    for _, food in pairs(sort) do
        food:Simulation(second)
    end

    sort = self:SortSimulationWorkBench(self._SalesWorkBenches, XRestaurantConfigs.AreaType.SaleArea)
    for _, sale in pairs(sort) do
        sale:Simulation(second)
    end
    
    --避免长时间待着场景内，内存炸了
    if CS.XLuaEngine.Env.Memroy - self._EnterRoomMemory > LuaMemoryLimit then
        LuaGC()
        self:UpdateLuaMemory()
    end
    
    LastSimulationTime = now
end

---@param benchList XRestaurantWorkBench[]
function XRestaurant:SortSimulationWorkBench(benchList, areaType)
    if XTool.IsTableEmpty(benchList) then
        return {}
    end
    if not self:CheckNewSort(areaType) then
        return benchList
    end
    local tmpList = {}
    for _, bench in pairs(benchList) do
        if bench:IsRunning() then
            table.insert(tmpList, bench)
        end
    end
    table.sort(tmpList, function(a, b) 
        local runningA = a:IsRunning()
        local runningB = b:IsRunning()
        if runningA ~= runningB then
            return runningA
        end
        local priorityA = a:GetWorkPriority()
        local priorityB = b:GetWorkPriority()
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        local updateTimeA = a:GetProperty("_UpdateTime")
        local updateTimeB = b:GetProperty("_UpdateTime")

        if updateTimeA ~= updateTimeB then
            return updateTimeA < updateTimeB
        end

        return a:GetProperty("_Id") < b:GetProperty("_Id")
    end)

    return tmpList
end

--- 检查当前趋于工作台是否需要重新排序
---@param areaType number 区域类型
---@return boolean
--------------------------
function XRestaurant:CheckNewSort(areaType)
    local value = self._AreaSortMark[areaType]
    return not value
end

--- 标记当前区域需要排序
---@param areaType number 区域类型
---@return void
--------------------------
function XRestaurant:MarkNewSort(areaType)
    self._AreaSortMark[areaType] = true
end

--endregion------------------Simulation finish------------------

function XRestaurant:NotifyLevelConditionEventChange()
    self:SetProperty("_EventLevelConditionChange", self._EventLevelConditionChange + 1)
end

function XRestaurant:NotifyBuffRedPointChange()
    self:SetProperty("_BuffRedPointMarkCount", self._BuffRedPointMarkCount + 1)
end

function XRestaurant:NotifyMenuRedPointChange()
    self:SetProperty("_MenuRedPointMarkCount", self._MenuRedPointMarkCount + 1)
end

function XRestaurant:OnActivityEnd()
    for key, value in pairs(default) do
        self[key] = value
    end
end

return XRestaurant