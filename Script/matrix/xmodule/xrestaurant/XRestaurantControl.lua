---@class XRestaurantControl : XEntityControl
---@field private _Model XRestaurantModel
---@field private _AreaWorkbenchDict table<number, XBenchViewModel[]>
---@field private _SortBenches table<number, XBenchViewModel[]>
---@field private _StaffDict table<number, XRestaurantStaffVM>
---@field private _IngredientDict table<number, XRestaurantIngredientVM>
---@field private _FoodDict table<number, XRestaurantFoodVM>
---@field private _BuffDict table<number, XRestaurantBuffVM>
---@field private _PerformDict table<number, XRestaurantPerformVM>
---@field private _Cashier XRestaurantCashierVM
---@field private _ExitRoomRequest XNetworkCallCd
---@field private _StopRequest XNetworkCallCd
---@field private _Business XRestaurantBusinessVM
---@field private _Loader XLoaderUtil
local XRestaurantControl = XClass(XEntityControl, "XRestaurantControl")

local XIngredientVM, XCookingVM, XSalesVM
local XRestaurantStaffVM
local XRestaurantIngredientVM, XRestaurantFoodVM, XRestaurantCashierVM
local XRestaurantBuffVM
local XRestaurantPerformVM
local XRestaurantRoom
local XRestaurantBusinessVM
local XNetworkCallCd

function XRestaurantControl:OnInit()
    XMVCA.XRestaurant:SetInActivity(true)
    XMVCA.XRestaurant:ClearShotComplete()
    self._AreaSortMark = {}
    self._SortBenches = {}
    self._PerformDict = {}
    self._EventFunc = {}
    self._IsCreatingPerform = false
    self._NeedRequestWhenRelease = false
    self._UiMainSortingOrder = 0
    self:InitRequire()
    self:InitStaff()
    self:InitProduct()
    self:InitBuff()
end

function XRestaurantControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_RESTAURANT_ENTER_ROOM, self.EnterRoom, self)
end

function XRestaurantControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_RESTAURANT_ENTER_ROOM, self.EnterRoom, self)
end

function XRestaurantControl:OnRelease()
    self._AreaSortMark = nil
    self._Cashier = nil
    self._AreaWorkbenchDict = nil
    self._StaffDict = nil
    self._IngredientDict = nil
    self._FoodDict = nil
    self._UnlockFoodIdDict = nil
    self._UnlockIngredientIdDict = nil
    self._BuffDict = nil
    self._PerformDict = nil
    self._SortBenches = nil
    self._Room = nil
    self._IsCreatingPerform = nil
    self._EventFunc = nil

    if self._NeedRequestWhenRelease then
        self:RequestExitRestaurant()
    end

    self:ClearRequest()
    self:UnloadAll()

    XMVCA.XRestaurant:SetInActivity(false)
end

function XRestaurantControl:InitRequire()
    --带Cd的请求
    XNetworkCallCd = require("XCommon/XNetworkCallCd")
    --工作台
    XIngredientVM = require("XModule/XRestaurant/XViewModel/XBenchViewModel/XIngredientVM")
    XCookingVM = require("XModule/XRestaurant/XViewModel/XBenchViewModel/XCookingVM")
    XSalesVM = require("XModule/XRestaurant/XViewModel/XBenchViewModel/XSalesVM")
    --员工
    XRestaurantStaffVM = require("XModule/XRestaurant/XViewModel/XRestaurantStaffVM")
    --产品
    XRestaurantIngredientVM = require("XModule/XRestaurant/XViewModel/XRestaurantIngredientVM")
    XRestaurantFoodVM = require("XModule/XRestaurant/XViewModel/XRestaurantFoodVM")
    XRestaurantCashierVM = require("XModule/XRestaurant/XViewModel/XRestaurantCashierVM")
    --Buff
    XRestaurantBuffVM = require("XModule/XRestaurant/XViewModel/XRestaurantBuffVM")
    --订单
    XRestaurantPerformVM = require("XModule/XRestaurant/XViewModel/XRestaurantPerformVM")
    --房间
    XRestaurantRoom = require("XModule/XRestaurant/XGameObject/XRestaurantRoom")
    --商业管理
    XRestaurantBusinessVM = require("XModule/XRestaurant/XViewModel/XRestaurantBusinessVM")
    self._Business = self:AddEntity(XRestaurantBusinessVM, self._Model:GetBusinessData())
end

function XRestaurantControl:InitStaff()
    self._StaffDict = self._StaffDict or {}
    
    local allCharIds = self._Model:GetAllCharacterIds()
    for _, charId in pairs(allCharIds) do
        local staff = self._StaffDict[charId] or self:AddEntity(XRestaurantStaffVM, self._Model:GetStaffData(charId))
        self._StaffDict[charId] = staff
    end
end

function XRestaurantControl:InitProduct()
    self._IngredientDict = self._IngredientDict or {}
    self._FoodDict = self._FoodDict or {}
    
    local allIngredientIds = self._Model:GetAllIngredientIds()
    for _, id in ipairs(allIngredientIds) do
        local ingredient = self._IngredientDict[id] or self:AddEntity(XRestaurantIngredientVM, self
                ._Model:GetProductData(XMVCA.XRestaurant.AreaType.IngredientArea, id))

        self._IngredientDict[id] = ingredient
    end
    
    local allFoodIds = self:GetAllFoodIds()
    for _, id in ipairs(allFoodIds) do
        local food = self._FoodDict[id] or self:AddEntity(XRestaurantFoodVM, self
                ._Model:GetProductData(XMVCA.XRestaurant.AreaType.FoodArea, id))

        self._FoodDict[id] = food
    end
    --服务端写死的Id
    local cashierId = XMVCA.XRestaurant.CashierId
    self._Cashier = self._Cashier or self:AddEntity(XRestaurantCashierVM, self
            ._Model:GetProductData(XMVCA.XRestaurant.AreaType.SaleArea, cashierId))
end

function XRestaurantControl:InitWorkbench()
    local level = self:GetRestaurantLv()
    local template = self._Model:GetRestaurantLvTemplate(level)
    local dict = {
        [XMVCA.XRestaurant.AreaType.IngredientArea] = {
            Count = template.IngredientCounterNum,
            Cls = XIngredientVM,
        },
        [XMVCA.XRestaurant.AreaType.FoodArea] =
        {
            Count = template.FoodCounterNum,
            Cls = XCookingVM,
        },
        [XMVCA.XRestaurant.AreaType.SaleArea] = {
            Count = template.SaleCounterNum,
            Cls = XSalesVM,
        }
    }
    self._AreaWorkbenchDict = self._AreaWorkbenchDict or {}
    
    local init = function(count, cls, areaType, list)
        for i = 1, count do
            local bench = list[i] or self:AddEntity(cls, self._Model:GetWorkbenchData(areaType, i))
            list[i] = bench
        end
    end

    for _, value in pairs(XMVCA.XRestaurant.AreaType) do
        if value == XMVCA.XRestaurant.AreaType.None then
            goto continue
        end
        local list = self._AreaWorkbenchDict[value] or {}
        init(dict[value].Count, dict[value].Cls, value, list)
        self._AreaWorkbenchDict[value] = list
        
        ::continue::
    end
end

function XRestaurantControl:InitBuff()
    self._BuffDict = self._BuffDict or {}
    
    local allBuffIds = self._Model:GetAllBuffIds()
    for _, buffId in ipairs(allBuffIds) do
        local buff = self._BuffDict[buffId] or self:AddEntity(XRestaurantBuffVM, self._Model:GetBuffData(buffId))
        self._BuffDict[buffId] = buff
    end
end

--- 获取收银台
---@return XRestaurantCashierVM
--------------------------
function XRestaurantControl:GetCashier()
    return self._Cashier
end

function XRestaurantControl:GetCashierLimit(level)
    return self._Model:GetCashierLimit(level)
end

--- 商业管理
---@return XRestaurantBusinessVM
--------------------------
function XRestaurantControl:GetBusiness()
    return self._Business
end

--- 获取工作台
---@param areaType number
---@param index number
---@return XBenchViewModel
--------------------------
function XRestaurantControl:GetWorkbench(areaType, index, noTip)
    local list = self._AreaWorkbenchDict[areaType]
    if not list then
        XLog.Error("不存在工作台, 区域类型 = " .. areaType)
        return
    end
    local bench = list[index]
    if not bench then
        if not noTip then
            XLog.Error("在区域" .. areaType .. ", 不存在" .. index .. "号工作台")
        end
        return
    end
    return bench
end

--- 获取餐厅所有工作台
---@return table<number, XBenchViewModel[]>
--------------------------
function XRestaurantControl:GetAllWorkbenchDict()
    return self._AreaWorkbenchDict
end

--- 获取区域已经解锁的工作台
---@param areaType number
---@return XBenchViewModel[]
--------------------------
function XRestaurantControl:GetUnlockWorkbenches(areaType)
    return self._AreaWorkbenchDict[areaType]
end

--- 获取餐厅场景
---@return XRestaurantRoom
--------------------------
function XRestaurantControl:GetRoom()
    if not self._Room then
        self._Room = self:AddEntity(XRestaurantRoom)
    end
    return self._Room
end

--- 进入场景
--------------------------
function XRestaurantControl:EnterRoom()
    --初始化工作台
    self:InitWorkbench()
    --设置全局光
    XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
    --更新食谱任务
    self._Model:UpdateRecipeTaskMap()
    --加载行为树
    XLuaBehaviorManager.LoadBehaviorTree(CS.BehaviorTree.XGamePlayType.Restaurant)
    --进入场景
    self:GetRoom():SetGameObject(XMVCA.XRestaurant:GetSceneObj())
    --永动机，启动！
    self:StartSimulation()
end

--- 退出场景
--------------------------
function XRestaurantControl:ExitRoom()
    --永动机，关闭！
    self:StopSimulation()
    if self._Model:IsInBusiness() then
        self._NeedRequestWhenRelease = true
    end
    --场景释放
    self:GetRoom():Release()

    local uiList = { "UiRestaurantCommon", "UiRestaurantMain" }
    --避免界面非正常关闭时，资源未被销毁
    for _, uiName in ipairs(uiList) do
        if XLuaUiManager.IsUiLoad(uiName) then
            XLuaUiManager.Remove(uiName)
        end
    end
    XMVCA.XRestaurant:ResetSceneObj()
    self._Room = nil

    --卸载行为树
    XLuaBehaviorManager.UnloadBehaviorTree(CS.BehaviorTree.XGamePlayType.Restaurant)
end

--- 停止营业
--------------------------
function XRestaurantControl:StopBusiness()
    self:GetRoom():StopBusiness()
end

--- 开始营业
--------------------------
function XRestaurantControl:StartBusiness()
    self:GetRoom():StartBusiness()
end

--- 获取员工
---@param charId number
---@return XRestaurantStaffVM
--------------------------
function XRestaurantControl:GetCharacter(charId)
    local staff = self._StaffDict[charId]
    if not staff then
        XLog.Error("不存在员工， 员工Id = " .. charId)
        return
    end
    return staff
end

--- 获取有区域增益的角色列表
---@param areaType number 区域类型
---@return XRestaurantStaffVM[]
--------------------------
function XRestaurantControl:GetCharactersWithAreaTypeAddition(areaType)
    local list = {}
    local isAll = areaType == 0 or areaType == nil

    for _, char in pairs(self._StaffDict) do
        if isAll or char:IsAdditionByAreaTypeWithMaxLevel(areaType) then
            table.insert(list, char)
        end
    end
    return list
end

--- 获取当前区域工作台上的角色列表
---@param areaType number 区域类型
---@return XRestaurantStaffVM[]
--------------------------
function XRestaurantControl:GetCharactersWithAreaType(areaType)
    local dict = self._AreaWorkbenchDict[areaType]
    if XTool.IsTableEmpty(dict) then
        return {}
    end
    
    local list = {}

    for _, bench in pairs(dict) do
        if not bench:IsFree() then
            table.insert(list, bench:GetCharacter())
        end
    end
    
    return list
end

--- 获取已经招募的员工
---@return XRestaurantStaffVM[]
--------------------------
function XRestaurantControl:GetRecruitCharacters()
    local list = {}
    for _, char in pairs(self._StaffDict) do
        if char:IsRecruit() then
            table.insert(list, char)
        end
    end
    return list
end

--- 获取已经招募的员工Id
---@return number[]
--------------------------
function XRestaurantControl:GetRecruitCharacterIds()
    local list = {}
    for _, char in pairs(self._StaffDict) do
        if char:IsRecruit() then
            table.insert(list, char:GetCharacterId())
        end
    end
    return list
end

function XRestaurantControl:GetRecruitCharacterCount()
    local count = 0
    for _, char in pairs(self._StaffDict) do
        if char:IsRecruit() then
            count = count + 1
        end
    end
    return count
end

function XRestaurantControl:GetCharacterLimit(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self._Model:GetRestaurantLvTemplate(level)
    return template.CharacterLimit or 0
end

--- 空闲员工人数
---@return number
--------------------------
function XRestaurantControl:GetFreeCharacterCount()
    local count = 0
    for _, char in pairs(self._StaffDict) do
        if char:IsFree() and char:IsRecruit() then
            count = count + 1
        end
    end
    return count
end

--- 安排工作的人数
---@return number
--------------------------
function XRestaurantControl:GetWorkingCharacterCount(areaType)
    local count = 0
    local checkArea = areaType ~= nil
    for _, char in pairs(self._StaffDict) do
        --未招募
        if not char:IsRecruit() then
            goto continue
        end
        --未安排工作
        if char:IsFree() then
            goto continue
        end
        --需要检测区域-但是区域不同
        if checkArea and char:GetAreaType() ~= areaType then
            goto continue
        end
        
        count = count + 1
        ::continue::
    end
    return count
end

--- 获取大于目标等级的员工人数
---@param level number 目标等级
---@return number
--------------------------
function XRestaurantControl:GetGreaterLevelCharacterCount(level)
    return self._Model:GetGreaterLevelCharacterCount(level)
end

function XRestaurantControl:GetAllFoodIds()
    return self._Model:GetAllFoodIds()
end

function XRestaurantControl:GetFoodTemplateByItemId(itemId)
    return self._Model:GetFoodTemplateByItemId(itemId)
end

--- 获取产品, 只获取（食材或者食物）
---@param areaType number
---@param productId number
---@return XRestaurantProductVM
--------------------------
function XRestaurantControl:GetProduct(areaType, productId)
    if self:IsIngredientArea(areaType) then
        return self._IngredientDict[productId]
    end
    if self:IsSaleArea(areaType) and productId == XMVCA.XRestaurant.CashierId then
        return self._Cashier
    end
    return self._FoodDict[productId]
end

function XRestaurantControl:UpdateProduct()
    for _, product in pairs(self._IngredientDict) do
        product:UpdateViewModel()
    end

    for _, product in pairs(self._FoodDict) do
        product:UpdateViewModel()
    end

    self._Cashier:UpdateViewModel()
end

--- 获取当前等级开放的产品Id
---@param areaType number
---@param level number
---@return number[]
--------------------------
function XRestaurantControl:GetUnlockProductIdsByLevel(areaType, level)
    if self:IsIngredientArea(areaType) then
        return self._Model:GetUnlockIngredient(level)
    end
    return self._Model:GetUnlockFood(level)
end

--- 获取当前区域已经解锁的产品列表
---@param areaType number
---@param isSort boolean 是否排序
---@return XRestaurantProductVM[]
--------------------------
function XRestaurantControl:GetUnlockProductList(areaType, isSort)
    ---@type table<number, XRestaurantProductVM>
    local dict
    local isSortByQuality
    if self:IsIngredientArea(areaType) then
        dict = self._IngredientDict
        isSortByQuality = false
    else
        dict = self._FoodDict
        isSortByQuality = true
    end
    ---@type XRestaurantProductVM[]
    local list = {}
    for _, product in pairs(dict) do
        if product and product:IsUnlock() then
            table.insert(list, product)
        end
    end

    if isSort and not XTool.IsTableEmpty(list) then
        table.sort(list, function(a, b)
            if isSortByQuality then
                local qA = a:GetQuality()
                local qB = b:GetQuality()
                if qA ~= qB then
                    return qA > qB
                end
            end
            
            return a:GetProductId() < b:GetProductId()
        end)
    end
    
    return list
end

--- 已解锁产品个数
---@param areaType number
---@return number
--------------------------
function XRestaurantControl:GetUnlockProductListCount(areaType)
    ---@type table<number, XRestaurantProductVM>
    local dict
    if self:IsIngredientArea(areaType) then
        dict = self._IngredientDict
    else
        dict = self._FoodDict
    end
    local count = 0
    for _, product in pairs(dict) do
        if product and product:IsUnlock() then
            count = count + 1
        end
    end
    return count
end

--- 是否是急需食材
---@param areaType number
---@param productId number
---@return boolean
--------------------------
function XRestaurantControl:IsUrgentProduct(areaType, productId)
    --非食材区
    if not self:IsIngredientArea(areaType) then
        return false
    end
    local produceSpeed = self:GetProduceTotalSpeed(areaType, productId)
    local consumeSpeed = self:GetConsumeTotalSpeed(areaType, productId)
    --未生产，未消耗
    if produceSpeed == 0 and consumeSpeed == 0 then
        return false
    end
    --生产速度大于等于消耗速度
    if produceSpeed >= consumeSpeed then
        return false
    end
    local urgentTime = self._Model:GetUrgentTime()
    local product = self:GetProduct(areaType, productId)
    local count = product and product:GetCount() or 0
    local second = (count / (consumeSpeed - produceSpeed)) * XMVCA.XRestaurant.TimeUnit.Hour
    
    return second <= urgentTime
end

--- 获取产品的生产总速
---@param areaType number 产品类型
---@param productId number
---@param timeUnit number
---@return number
--------------------------
function XRestaurantControl:GetProduceTotalSpeed(areaType, productId, timeUnit)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour

    if self:IsIngredientArea(areaType) then
        return self:_GetIngredientProduceTotalSpeed(productId, timeUnit)
    elseif self:IsCookArea(areaType) then
        return self:_GetFoodProduceTotalSpeed(productId, timeUnit)
    elseif self:IsSaleArea(areaType) then
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
function XRestaurantControl:GetConsumeTotalSpeed(areaType, productId, timeUnit)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XRestaurant.TimeUnit.Hour
    if self:IsIngredientArea(areaType) then
        return self:_GetIngredientConsumeTotalSpeed(productId, timeUnit)
    elseif self:IsCookArea(areaType) then
        return self:_GetFoodConsumeTotalSpeed(productId, timeUnit)
    elseif self:IsSaleArea(areaType) then
        return self:_GetSaleConsumeTotalSpeed(productId, timeUnit)
    end
    return 0
end

--- 材料生产速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurantControl:_GetIngredientProduceTotalSpeed(productId, timeUnit)
    local speed = 0
    local dict = self._AreaWorkbenchDict[XMVCA.XRestaurant.AreaType.IngredientArea]
    for _, bench in pairs(dict) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end

        --未生产目标物品
        if bench:GetProductId() ~= productId then
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
function XRestaurantControl:_GetIngredientConsumeTotalSpeed(productId, timeUnit)
    local speed = 0
    local dict = self._AreaWorkbenchDict[XMVCA.XRestaurant.AreaType.FoodArea]
    for _, bench in pairs(dict) do
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
function XRestaurantControl:_GetFoodProduceTotalSpeed(productId, timeUnit)
    local speed = 0
    local dict = self._AreaWorkbenchDict[XMVCA.XRestaurant.AreaType.FoodArea]
    for _, bench in pairs(dict) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end

        --未生产目标物品
        if bench:GetProductId() ~= productId then
            goto continue
        end
        speed = speed + bench:GetProductiveness(timeUnit)

        ::continue::
    end
    return speed
end

--- 食物消耗速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurantControl:_GetFoodConsumeTotalSpeed(productId, timeUnit)
    local speed = 0
    local dict = self._AreaWorkbenchDict[XMVCA.XRestaurant.AreaType.SaleArea]
    for _, bench in pairs(dict) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end

        speed = speed + bench:GetConsumption(productId, timeUnit)
        ::continue::
    end

    return speed
end

--- 售卖区生产速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurantControl:_GetSaleProduceTotalSpeed(productId, timeUnit)
    return 0
end

--- 售卖区消耗速度
---@param productId number 材料Id
---@param timeUnit number 单位时间
---@return number
--------------------------
function XRestaurantControl:_GetSaleConsumeTotalSpeed(productId, timeUnit)
    return self:_GetFoodConsumeTotalSpeed(productId, timeUnit)
end

--- 收银台总收益
---@param timeUnit number 单位时间，默认小时
---@return number
--------------------------
function XRestaurantControl:GetCashierTotalPrice(timeUnit)
    local price = 0
    local dict = self._AreaWorkbenchDict[XMVCA.XRestaurant.AreaType.SaleArea]
    for _, bench in pairs(dict) do
        --空闲状态
        if bench:IsFree() then
            goto continue
        end
        price = price + bench:GetFoodFinalPrice(timeUnit)
        ::continue::
    end
    return math.ceil(price)
end

--- 工作台预览提示
---@param areaType number
---@param productId number
---@param timeUnit number
---@return boolean, string
--------------------------
function XRestaurantControl:GetWorkBenchPreviewTip(areaType, productId, timeUnit)
    local produce = self:GetProduceTotalSpeed(areaType, productId, timeUnit)
    local consume = self:GetConsumeTotalSpeed(areaType, productId, timeUnit)
    if produce == 0 and consume == 0 then
        return true, ""
    end
    local tip
    local product = self:GetProduct(areaType, productId)
    local subSpeed = produce - consume
    local freeCount = subSpeed > 0 and product:GetFreeCapacity() or product:GetCount()
    if self:IsIngredientArea(areaType) then
        if self:IsZero(subSpeed) and not self:IsZero(produce) then
            tip = self._Model:GetClientConfigValue("StoragePreviewTip1", 1)
        else
            local index = subSpeed > 0 and 1 or 2
            local desc = self._Model:GetClientConfigValue("StoragePreviewTip1", index)
            local time = math.abs(freeCount / subSpeed)
            tip = string.format(desc, self:GetAroundValue(time, XMVCA.XRestaurant.Digital.One))
        end
        return subSpeed > 0, tip
    elseif self:IsCookArea(areaType) then
        --消耗完毕或者满仓速度
        local stop = freeCount / math.abs(produce - consume)
        if not product then
            return stop
        end
        local list = product:GetIngredients()
        local cStop = stop
        for _, consume in ipairs(list) do
            local ingredientId = consume.Id()
            local ingredient = self:GetProduct(XMVCA.XRestaurant.AreaType.IngredientArea, ingredientId)
            local cSpeed = ingredient:GetCount() / self:_GetIngredientConsumeTotalSpeed(ingredientId, timeUnit)
            cStop = math.min(cStop, cSpeed)
        end
        local increase = subSpeed > 0 and stop <= cStop
        local isZero = self:IsZero(cStop) and self:IsZero(subSpeed)
        if isZero then
            tip = self._Model:GetClientConfigValue("StoragePreviewTip2", 4)
        else
            local index
            --生产速度 > 消耗速度 && 食材库存足够
            if increase then
                index = 1
            elseif stop > cStop then --食材消耗 > 售卖 
                index = 3
            else --食材消耗 < 售卖
                index = 2
            end
            local desc = self._Model:GetClientConfigValue("StoragePreviewTip2", index)
            tip = string.format(desc, self:GetAroundValue(cStop, XMVCA.XRestaurant.Digital.One))
        end
        return increase, tip

    elseif self:IsSaleArea(areaType) then
        local price = self:GetCashierTotalPrice(timeUnit)
        freeCount = self._Cashier:GetFreeCapacity()
        --收银台满
        local fullTime = freeCount / price
        --售卖完毕
        local consumeTime = product:GetCount() / consume

        if self:IsZero(fullTime - consumeTime) then
            tip = self._Model:GetClientConfigValue("StoragePreviewTip3", 3)
        else
            local index, time
            if fullTime > consumeTime then
                index = 2
                time = consumeTime
            else
                index = 1
                time = fullTime
            end
            local desc = self._Model:GetClientConfigValue("StoragePreviewTip3", index)
            tip = string.format(desc, self:GetAroundValue(time, XMVCA.XRestaurant.Digital.One))
        end
        return fullTime < consumeTime, tip
    end
end

--- 对应区域的BuffId
---@param areaType number
---@return number
--------------------------
function XRestaurantControl:GetAreaBuffId(areaType)
    return self._Business:GetAreaBuffId(areaType)
end

--- 获取当前区域生效的Buff
---@param areaType number
---@return XRestaurantBuffVM
--------------------------
function XRestaurantControl:GetAreaBuff(areaType)
    local buffId = self:GetAreaBuffId(areaType)
    if not XTool.IsNumberValid(buffId) then
        return
    end
    return self:GetBuff(buffId)
end

--- 获取Buff
---@param buffId number
---@return XRestaurantBuffVM
--------------------------
function XRestaurantControl:GetBuff(buffId)
    return self._BuffDict[buffId]
end

--- 增益玩法解锁最低等级
---@return number
--------------------------
function XRestaurantControl:GetBuffUnlockMinLevel()
    local level = XMVCA.XRestaurant.RestLevelRange.Max
    for _, areaType in pairs(XMVCA.XRestaurant.AreaType) do
        if areaType ~= XMVCA.XRestaurant.AreaType.None then
            level = math.min(level, self._Model:GetMinLevelAreaTypeBuff(areaType))
        end
    end
    return level
end

--- 检测这个区域的Buff是否能开启
---@param areaType number
---@return boolean
--------------------------
function XRestaurantControl:CheckAreaBuffUnlock(areaType)
    return self:GetRestaurantLv() >= self._Model:GetMinLevelAreaTypeBuff(areaType)
end

function XRestaurantControl:GetBuffIdList(areaType)
    return self._Model:GetBuffIdList(areaType)
end

function XRestaurantControl:GetBuffCount()
    local allIds = self._Model:GetAllBuffIds()
    local unlockCount = 0
    for _, buffId in ipairs(allIds) do
        local buff = self:GetBuff(buffId)
        if buff and buff:IsUnlock() then
            unlockCount = unlockCount + 1
        end
    end
    return unlockCount, #allIds
end

function XRestaurantControl:GetBuffCharacterIds(buffId)
    local template = self._Model:GetSectionBuffTemplate(buffId)
    return template and template.CharacterIds or {}
end

function XRestaurantControl:GetUnlockIndentCount()
    return self._Model:GetUnlockIndentCount()
end

function XRestaurantControl:GetUnlockPerformCount()
    return self._Model:GetUnlockPerformCount()
end

--- 获取进行中的订单
---@return XRestaurantPerformVM
--------------------------
function XRestaurantControl:GetRunningIndent()
    local performData = self._Model:GetRunningIndentData()
    if not performData then
        return
    end
    return self:GetPerform(performData:GetPerformId())
end

--- 获取进行中的演出
---@return XRestaurantPerformVM
--------------------------
function XRestaurantControl:GetRunningPerform()
    local performData = self._Model:GetRunningPerformData()
    if not performData then
        return
    end
    return self:GetPerform(performData:GetPerformId())
end

--- 检测当天订单是否完成
---@return boolean
--------------------------
function XRestaurantControl:CheckRunningIndentFinish()
    local indent = self:GetRunningIndent()
    if not indent then
        return false
    end
    return indent:CheckPerformFinish()
end

--- 当前执行的订单的NPC的Id
---@return number
--------------------------
function XRestaurantControl:GetRunningIndentNpcId()
    if not self._Model:IsOpen() then
        return
    end
    local indent = self:GetRunningIndent()
    if not indent or indent:IsFinish() then
        return
    end
    return indent:GetIndentNpcId()
end

--- 获取演出数据
---@param performId number
---@return XRestaurantPerformVM
--------------------------
function XRestaurantControl:GetPerform(performId)
    local perform = self._PerformDict[performId]
    if not perform then
        if self._IsCreatingPerform then
            return
        end
        self._IsCreatingPerform = true
        local performData = self._Model:GetPerformData(performId)
        perform = self:AddEntity(XRestaurantPerformVM, performData)
        self._PerformDict[performId] = perform
        self._IsCreatingPerform = false
    end
    return perform
end

function XRestaurantControl:CheckRunningPerformFinish()
    local perform = self:GetRunningPerform()
    if not perform then
        return false
    end
    return perform:CheckPerformFinish()
end

function XRestaurantControl:CheckPerformFinish(performId)
    local perform = self:GetPerform(performId)
    if not perform then
        return false
    end
    return perform:CheckPerformFinish()
end

function XRestaurantControl:UpdateConditionWhenProductChange(areaType, productId, characterId, count, isHot)
    local indent = self:GetRunningIndent()
    if indent then
        indent:UpdateConditionWhenProductChange(areaType, productId, characterId, count, isHot)
    end
    
    local perform = self:GetRunningPerform()
    if perform then
        perform:UpdateConditionWhenProductChange(areaType, productId, characterId, count, isHot)
    end
end

--- 标记当前区域需要排序
---@param areaType number 区域类型
function XRestaurantControl:SetAreaSort(areaType, value)
    self._AreaSortMark[areaType] = value
end

--- 检查当前区域工作台是否需要重新排序
---@param areaType number 区域类型
---@return boolean
--------------------------
function XRestaurantControl:CheckNewSort(areaType)
    local value = self._AreaSortMark[areaType]
    if value == nil then
        return true
    end
    return value
end

function XRestaurantControl:GetRestaurantLv()
    return self._Model:GetRestaurantLv()
end

function XRestaurantControl:GetLvUpRewardId(level)
    local template = self._Model:GetRestaurantLvTemplate(level)
    return (template and template.RewardId ~= nil) and template.RewardId or 0
end

function XRestaurantControl:GetLvUpPerformIds(level)
    local template = self._Model:GetRestaurantLvTemplate(level)
    return template and template.PerformIds or {}
end

--- 餐厅升级解锁的效果
---@param targetLevel number 升级到目标等级
--------------------------
function XRestaurantControl:GetRestaurantUnlockEffectList(targetLevel)
    if targetLevel <= 0 then
        return {}
    end

    local list = {}
    local lastLevel = targetLevel - 1
    local func = function(type, cb)
        local targetValue = cb(targetLevel)
        local lastValue = lastLevel <= 0 and 0 or cb(lastLevel)
        if targetValue ~= 0 then
            table.insert(list, {
                Type = type, Count = targetValue, SubCount = targetValue - lastValue
            })
        end
    end
    func(XMVCA.XRestaurant.EffectType.IngredientCount, function(level) 
        return self:GetWorkbenchCountWithAreaType(level, XMVCA.XRestaurant.AreaType.IngredientArea)
    end)
    func(XMVCA.XRestaurant.EffectType.FoodCount, function(level)
        return self:GetWorkbenchCountWithAreaType(level, XMVCA.XRestaurant.AreaType.FoodArea)
    end)
    func(XMVCA.XRestaurant.EffectType.SaleCount, function(level)
        return self:GetWorkbenchCountWithAreaType(level, XMVCA.XRestaurant.AreaType.SaleArea)
    end)
    func(XMVCA.XRestaurant.EffectType.CharacterLimit, function(level)
        return self:GetCharacterLimit(level)
    end)
    func(XMVCA.XRestaurant.EffectType.CashierLimit, function(level)
        return self:GetCashierLimit(level)
    end)
    func(XMVCA.XRestaurant.EffectType.HotSaleAddition, function(level)
        return self._Model:GetHotSaleAdditionByRestaurantLevel(level)
    end)

    return list
end

--- 升级条件列表
---@return string[]
--------------------------
function XRestaurantControl:GetRestaurantUnlockConditionList(data)
    local list = {}
    
    local staffNumber = data.TotalStaffNumber
    if staffNumber > 0 then
        local text = string.format(self:GetRestaurantLvUpConditionText(1), staffNumber)
        local recruitCount = self:GetRecruitCharacterCount()
        local finish = recruitCount >= staffNumber
        table.insert(list, {
            Text = text,
            Finish = finish,
            Type = 1,
        })
    end

    local level, count = data.SeniorCharacterLv, data.TotalSeniorCharacter
    if level > 0 and count > 0 then
        local text = string.format(self:GetRestaurantLvUpConditionText(2), count, self._Model:GetCharacterLevelStr(level))
        local greaterCount = self:GetGreaterLevelCharacterCount(level)
        local finish = greaterCount >= count
        table.insert(list, {
            Text = text,
            Finish = finish,
            Type = 1,
        })
    end

    for _, consume in ipairs(data.ConsumeData) do
        local need = consume.Count
        local has = XDataCenter.ItemManager.GetCount(consume.ItemId)
        table.insert(list, {
            Text = has .. "/" .. need,
            Finish = has >= need,
            Type = 2
        })
    end

    return list
end

function XRestaurantControl:GetRestaurantTitleIcon(level)
    return self._Model:GetRestaurantTitleIcon(level)
end

function XRestaurantControl:GetRestaurantDecorationIcon(level)
    return self._Model:GetRestaurantDecorationIcon(level)
end

function XRestaurantControl:GetUpgradeCondition(level)
    return self._Model:GetUpgradeCondition(level)
end

function XRestaurantControl:GetUpgradeConsume(level)
    return self._Model:GetUpgradeConsume(level)
end

function XRestaurantControl:GetShopEndTime()
    return self._Model:GetShopEndTime()
end

function XRestaurantControl:GetShopTimeTxt(timeStr)
    return string.format(self._Model:GetClientConfigValue("ShopTimeTxt", 1), timeStr)
end

function XRestaurantControl:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

function XRestaurantControl:GetWorkbenchCount(level)
    if not level or level <= 0 or level > XMVCA.XRestaurant.RestLevelRange.Max then
        level = self:GetRestaurantLv()
    end
    local template = self._Model:GetRestaurantLvTemplate(level)
    return template.IngredientCounterNum, template.FoodCounterNum, template.SaleCounterNum
end

function XRestaurantControl:GetWorkbenchCountWithAreaType(level, areaType)
    local c1, c2, c3 = self:GetWorkbenchCount(level)
    if self:IsIngredientArea(areaType) then
        return c1
    elseif self:IsCookArea(areaType) then
        return c2
    elseif self:IsSaleArea(areaType) then
        return c3
    end
    return 0
end

function XRestaurantControl:GetCommonQualityIcon(is3d)
    return self._Model:GetCommonQualityIcon(is3d)
end

function XRestaurantControl:GetCharacterSkillName(skillId)
    local template = self._Model:GetCharacterSkillTemplate(skillId)
    return template and template.Name or ""
end

function XRestaurantControl:GetTimeLimitTaskIds()
    return self._Model:GetTimeLimitTaskIds()
end

function XRestaurantControl:GetRecipeTaskId()
    return self._Model:GetRecipeTaskId()
end

--region   ------------------餐厅操作接口 start-------------------

--- 全部停工
--------------------------
function XRestaurantControl:StopAllByArea(areaType)
    if not self._AreaWorkbenchDict then
        return
    end
    local list = self._AreaWorkbenchDict[areaType]
    for _, bench in pairs(list) do
        bench:Stop()
    end
end

--- 厨房开始模拟
--------------------------
function XRestaurantControl:StartSimulation()
    if self._SimulationTimer then
        self:StopSimulation()
    end
    --上次模拟时间
    self._LastSimulationTime = XTime.GetServerNowTimestamp()
    local delay = XScheduleManager.SECOND
    self._SimulationTimer = XScheduleManager.ScheduleForever(function() 
        self:Simulation()
    end, XScheduleManager.SECOND, delay)
end

--- 停止模拟
--------------------------
function XRestaurantControl:StopSimulation()
    if not self._SimulationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._SimulationTimer)
    self._SimulationTimer = nil
end

--- 厨房模拟运行
---@return 
--------------------------
function XRestaurantControl:Simulation()
    local nowTime = XTime.GetServerNowTimestamp()
    local simulationTime = nowTime - self._LastSimulationTime
    
    local room = self:GetRoom()
    if room then
        room:Simulation(nowTime)
    end
    for areaType, dict in pairs(self._AreaWorkbenchDict) do
        local list = self._SortBenches[areaType]
        if not list then
            self:SetAreaSort(areaType, true)
            list = dict
        end
        list = self:GetSortWorkbenches(areaType, list)
        for _, bench in ipairs(list) do
            bench:Simulation(simulationTime)
        end
        self._SortBenches[areaType] = list
    end
    
    self._LastSimulationTime = nowTime
end

--- 获取排序后的工作台
---@param areaType number
---@param benches XBenchViewModel[]
---@return XBenchViewModel[]
--------------------------
function XRestaurantControl:GetSortWorkbenches(areaType, benches)
    if not self:CheckNewSort(areaType) then
        return benches
    end

    --需要排序时
    benches = self._AreaWorkbenchDict[areaType]
    if XTool.IsTableEmpty(benches) then
        return {}
    end
    ---@type XBenchViewModel[]
    local tmpList = {}
    for _, bench in pairs(benches) do
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

        local updateTimeA = a:GetUpdateTime()
        local updateTimeB = b:GetUpdateTime()

        if updateTimeA ~= updateTimeB then
            return updateTimeA < updateTimeB
        end
        
        return a:GetWorkbenchId() < b:GetWorkbenchId()
    end)
    --标记已经排序
    self:SetAreaSort(areaType, false)
    return tmpList
end

function XRestaurantControl:OnActivityEnd()
    self._Model:ResetActivity()
end

--endregion------------------餐厅操作接口 finish------------------



--region   ------------------提示文本 start-------------------

function XRestaurantControl:GetRestaurantNotInBusinessText()
    return self._Model:GetClientConfigValue("RestaurantNotInBusiness", 1)
end

function XRestaurantControl:GetCommonUnlockText(index)
    return self._Model:GetClientConfigValue("CommonUnlockText", index)
end

function XRestaurantControl:GetNoStaffWorkText()
    return self._Model:GetClientConfigValue("NoStaffWorkText", 1)
end

function XRestaurantControl:GetStopAllProductText()
    local template = self._Model:GetClientConfig("StopAllProductText")
    return template.Values[1], template.Values[2]
end

function XRestaurantControl:GetSignNotInTimeTxt()
    return self._Model:GetClientConfigValue("SignNotInTimeTxt", 1)
end

function XRestaurantControl:GetSignedTxt()
    return self._Model:GetClientConfigValue("SignedTxt", 1)
end

function XRestaurantControl:GetUpOrDownArrowIcon(index)
    return self._Model:GetClientConfigValue("RImgUpgradeIcon", index)
end

function XRestaurantControl:GetWorkRImgTitle(index)
    return self._Model:GetClientConfigValue("WorkRImgTitle", index)
end

function XRestaurantControl:GetBuffAdditionText(areaType)
    return self._Model:GetClientConfigValue("BuffAdditionText", areaType)
end

function XRestaurantControl:GetBuffAreaUnlockTip(areaType)
    local minLevel = self._Model:GetMinLevelAreaTypeBuff(areaType)
    return string.format(self:GetCommonUnlockText(2), minLevel)
end

function XRestaurantControl:GetBuffUnlockLvTip(buffId)
    local minLevel = self:GetBuff(buffId):GetUnlockLv()
    return string.format(self:GetCommonUnlockText(2), minLevel)
end

function XRestaurantControl:GetBuffUnlockedTip(buffId)
    local desc = self._Model:GetClientConfigValue("BuffUpdateText", 1)
    return string.format(desc, self:GetBuff(buffId):GetName())
end

function XRestaurantControl:GetBuffSwitchTip(areaType, buffId)
    local desc = self._Model:GetClientConfigValue("BuffUpdateText", 2)
    return string.format(desc, self:GetAreaTypeName(areaType), self:GetBuff(buffId):GetName())
end

function XRestaurantControl:GetAreaTypeName(areaType)
    return self._Model:GetAreaTypeName(areaType)
end

function XRestaurantControl:GetAreaTypeTitleIcon(areaType)
    return self._Model:GetAreaTypeTitleIcon(areaType)
end

function XRestaurantControl:GetAdditionIcon(isBuff)
    local index = isBuff and 1 or 2
    return self._Model:GetClientConfigValue("AdditionIcon", index)
end

function XRestaurantControl:GetSkillAdditionUnit(areaType)
    local index = self:IsSaleArea(areaType) and 2 or 1
    return self._Model:GetClientConfigValue("ProduceTimeUnit", index)
end

function XRestaurantControl:GetWorkPauseReason(index)
    return self._Model:GetClientConfigValue("WorkPauseReason", index)
end

function XRestaurantControl:GetStaffWorkTip(index)
    return self._Model:GetClientConfigValue("StaffWorkTip", index)
end

function XRestaurantControl:GetProduceDesc(index)
    return self._Model:GetClientConfigValue("ProduceDesc", index)
end

function XRestaurantControl:GetProduceSpeedDesc(index, speed)
    local desc = self._Model:GetClientConfigValue("ProduceSpeedDesc", index)
    return string.format(desc, XMVCA.XRestaurant:TransProduceTime(speed))
end

function XRestaurantControl:GetAccelerateTip(index)
    return self._Model:GetAccelerateTip(index)
end

function XRestaurantControl:GetTaskDescText(index)
    return self._Model:GetClientConfigValue("TaskDescText", index)
end

function XRestaurantControl:GetStatisticsUnit(index)
    return self._Model:GetClientConfigValue("StatisticsUnit", index)
end

function XRestaurantControl:GetStatisticsTip(areaType, index)
    local key = self:IsIngredientArea(areaType)
            and "IngredientStatisticsTip" or "FoodStatisticsTip"
    return self._Model:GetClientConfigValue(key, index)
end

function XRestaurantControl:GetStaffTabText(index)
    return self._Model:GetClientConfigValue("StaffTabText", index)
end

function XRestaurantControl:GetStaffStateBtnText(index)
    return self._Model:GetClientConfigValue("StaffStateBtnText", index)
end

function XRestaurantControl:GetBoardCastTips(index)
    return self._Model:GetClientConfigValue("BoardCastTips", index)
end

function XRestaurantControl:GetRestaurantLvUpEffectText(index)
    return self._Model:GetClientConfigValue("RestaurantLvUpEffectText", index)
end

function XRestaurantControl:GetRestaurantLvUpConditionText(index)
    return self._Model:GetClientConfigValue("RestaurantLvUpConditionText", index)
end

function XRestaurantControl:GetRestaurantLvUpPopupTip()
    local key = "RestaurantLvUpPopupTip"
    local template = self._Model:GetClientConfig(key)
    return template.Values[1], template.Values[2]
end

function XRestaurantControl:GetShopBuyLimitColor(index)
    return self._Model:GetClientConfigValue("ShopBuyLimitColor", index)
end

function XRestaurantControl:GetShopBuyTxtColor(index)
    return self._Model:GetClientConfigValue("ShopBuyTxtColor", index)
end

function XRestaurantControl:GetPhotoScrollTip()
    local index = XDataCenter.UiPcManager.IsPc() and 1 or 2
    return self._Model:GetClientConfigValue("PhotoScrollTip", index)
end

function XRestaurantControl:GetPhotoTaskContainTip(count)
    local index = count == 0 and 1 or 2
    return self._Model:GetClientConfigValue("PhotoTaskContainTip", index)
end

function XRestaurantControl:GetShopRewardId()
    local value = self._Model:GetClientConfigValue("ShopRewardId", 1)
    if string.IsNilOrEmpty(value) then
        return 0
    end
    return tonumber(value)
end

function XRestaurantControl:GetRestaurantInfoText(index)
    return self._Model:GetClientConfigValue("RestaurantInfo", index)
end

function XRestaurantControl:GetSwitchStaffContent(staffName, areaType)
    local template = self._Model:GetClientConfig("SwitchStaffContent")
    local title, content = template.Values[1], template.Values[2]
    content = XUiHelper.ReplaceTextNewLine(string.format(content, staffName, self:GetAreaTypeName(areaType)))
    return title, content
end

function XRestaurantControl:GetBubbleProperty()
    return tonumber(self._Model:GetClientConfigValue("BubbleProperty", 1))
end

--endregion------------------提示文本 finish------------------



--region   ------------------工具接口 start-------------------

function XRestaurantControl:GetAroundValue(value, digital)
    local decimal = math.pow(10, digital)
    return CS.UnityEngine.Mathf.Floor(value * decimal + 0.5) / decimal
end

function XRestaurantControl:IsIngredientArea(areaType)
    return areaType == XMVCA.XRestaurant.AreaType.IngredientArea
end

function XRestaurantControl:IsCookArea(areaType)
    return areaType == XMVCA.XRestaurant.AreaType.FoodArea
end

function XRestaurantControl:IsSaleArea(areaType)
    return areaType == XMVCA.XRestaurant.AreaType.SaleArea
end

function XRestaurantControl:IsZero(num)
    return math.abs(num) <= XMVCA.XRestaurant.Inaccurate
end

function XRestaurantControl:OpenSign()
    if not self._Model:IsOpen() then
        return
    end
    if not self._Business:IsSignOpen() then
        XUiManager.TipError(self:GetSignNotInTimeTxt())
        return
    end

    if self._Business:IsGetSignReward() then
        XUiManager.TipError(self:GetSignedTxt())
        return
    end

    XLuaUiManager.Open("UiRestaurantSignIn")
end

function XRestaurantControl:OpenShop()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    local shopId = self._Model:GetShopId()
    if not XTool.IsNumberValid(shopId) then
        return
    end
    XLuaUiManager.Open("UiRestaurantShop", shopId)
end

function XRestaurantControl:OpenBuff(isAreaBuff, ...)
    local level = self:GetRestaurantLv()
    local minLevel = self:GetBuffUnlockMinLevel()
    if minLevel > level then
        XUiManager.TipMsg(string.format(self:GetCommonUnlockText(2), minLevel))
        return
    end
    local uiName = isAreaBuff and "UiRestaurantBuff" or "UiRestaurantBuffChange"
    XLuaUiManager.Open(uiName, ...)
end

function XRestaurantControl:OpenTask(ignoreRequest)
    if ignoreRequest then
        XLuaUiManager.Open("UiRestaurantTask")
        return
    end
    local onResponse = function ()
        XLuaUiManager.Open("UiRestaurantTask")
    end
    self:RequestExitRestaurant(nil, onResponse)
end

--解锁食谱
function XRestaurantControl:OpenUnlockFood(rewardGoodsList, cb)
    if XUiManager.IsTableAsyncLoading() then
        XUiManager.WaitTableLoadComplete(function()
            XLuaUiManager.Open("UiRestaurantUnlockFood", rewardGoodsList, cb)
        end)
        return
    end
    XLuaUiManager.Open("UiRestaurantUnlockFood", rewardGoodsList, cb)
end

function XRestaurantControl:OpenMenu(tabId, ...)
    if not self._Model:IsOpen() then
        return
    end
    XLuaUiManager.Open("UiRestaurantMenu", tabId, ...)
end

function XRestaurantControl:OpenStatistics(areaType, firstProductId)
    local uiName = "UiRestaurantExamine"
    if XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end
    XLuaUiManager.Open(uiName, areaType, firstProductId)
end

function XRestaurantControl:OpenPopup(title, content, itemData, cancelCb, confirmCb)
    local uiName = "UiRestaurantPopup"
    if XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end
    XLuaUiManager.Open(uiName, title, content, itemData, cancelCb, confirmCb)
end

function XRestaurantControl:OpenIndent(indentId, isNotStart, isOnGoing)
    if XMain.IsEditorDebug then
        XLog.Error("此函数已经废弃")
    end
    --local openFunc = function()
    --    XLuaUiManager.Open("UiRestaurantIndent")
    --
    --end
    --if isNotStart then
    --    self:RequestCollectOrder(indentId, openFunc)
    --elseif isOnGoing then
    --    self:RequestExitRestaurant(nil, openFunc)
    --else
    --    openFunc()
    --end
end

--厨房通用奖励弹窗
function XRestaurantControl:OpenCommonObtain(rewardGoodsList, title, closeCallback, sureCallback)
    if XUiManager.IsTableAsyncLoading() then
        XUiManager.WaitTableLoadComplete(function()
            XLuaUiManager.Open("UiRestaurantObtain", rewardGoodsList, title, closeCallback, sureCallback)
        end)
        return
    end
    XLuaUiManager.Open("UiRestaurantObtain", rewardGoodsList, title, closeCallback, sureCallback)
end

function XRestaurantControl:OpenPerformUi(performId)
    local perform = self:GetPerform(performId)
    local isFirstOpen = perform:IsNotStart()
    if isFirstOpen then
        if perform:IsPerform() then
            XLuaUiManager.Open("UiRestaurantPopupChat", performId)
        else
            self:RequestTakePerform(performId, nil, function()
                XLuaUiManager.Open("UiRestaurantPopupStory", performId)
            end)
        end
        return
    end
    XLuaUiManager.Open("UiRestaurantPopupStory", performId)
end

function XRestaurantControl:DoClickLockPerform(performId, onGoingCb)
    if not XTool.IsNumberValid(performId) then
        return
    end
    local perform = self:GetPerform(performId)
    if perform:IsNotStart() then
        XUiManager.TipMsg(perform:GetUnlockConditionDesc())
    elseif perform:IsFinish() then
        -- 2 ： 选中订单界面
        self:OpenMenu(perform:GetPerformType(), performId)
    elseif perform:IsOnGoing() then

        local cameraMd = self:GetRoom():GetCameraModel()
        local areaType = cameraMd:GetAreaType()
        if self:IsSaleArea(areaType) then
            if onGoingCb then onGoingCb() end
            self:SendEvent(XMVCA.XRestaurant.EventId.OnShowPerformTip, performId)
            return
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_CHANGE_MAIN_VIEW_CAMERA_AREA_TYPE,
                XMVCA.XRestaurant.AreaType.SaleArea)
        if onGoingCb then onGoingCb() end
        self:SendEvent(XMVCA.XRestaurant.EventId.OnShowPerformTip, performId)
    end
end

function XRestaurantControl:Broadcast(txtTip)
    local uiName = "UiRestaurantRadio"
    if XLuaUiManager.IsUiShow(uiName) then
        XLuaUiManager.Close(uiName)
    end
    XLuaUiManager.Open(uiName, txtTip)
end

function XRestaurantControl:PopRecipeTaskTip()
    self._Model:PopRecipeTaskTip()
end

function XRestaurantControl:Get3DGridOffset(index)
    local value = self._Model:GetClientConfigValue("Ui3DOffset", index)
    if string.IsNilOrEmpty(value) then
        return Vector3.zero
    end
    return XMVCA.XRestaurant:StrPos2Vector3(value)
end

function XRestaurantControl:GetWorkbenchPosInfo(areaType, index)
    return self._Model:GetWorkbenchPosInfo(areaType, index)
end

function XRestaurantControl:GetMainSortingOrder()
    return self._UiMainSortingOrder
end

function XRestaurantControl:SetMainSortingOrder(value)
    self._UiMainSortingOrder = value
end

function XRestaurantControl:GetCharacterSkillPercentAddition(addition, areaType, productId)
    local product = self:GetProduct(areaType, productId)
    local percent
    if self:IsSaleArea(areaType) then
        local baseSpeed = product:GetFoodBaseSellPrice()
        percent = addition / baseSpeed
    else
        local produceNeedTime = product:GetSpeed()
        percent = addition / produceNeedTime
    end
    percent = math.floor(percent * 100)
    local param = addition > 0 and "+%s%%" or "%s%%"

    return string.format(param, percent)
end

--- 获取产品单位时间内基础产量，增加产量，单位
---@param base number
---@param addition number
---@return number, number, string
--------------------------
function XRestaurantControl:GetAddCountAndUnit(base, addition, areaType)
    local baseCount, addSpeed, addCount
    if self:IsSaleArea(areaType) then
        baseCount = base
        addSpeed = base + addition
        addCount = addSpeed
    else
        local Hour = XMVCA.XRestaurant.TimeUnit.Hour
        --保留小数位数
        local Digital = XMVCA.XRestaurant.Digital.One

        baseCount = self:GetAroundValue(Hour / base, Digital)
        addSpeed = math.max(1, base - addition)
        addCount = self:GetAroundValue(Hour / addSpeed, Digital)
    end

    local add = addCount - baseCount
    return baseCount, add, add > 0 and "+" or ""
end

--- 日志全收集
---@return boolean
--------------------------
function XRestaurantControl:IsAllLogCollect()
    
    local allFoodIds = self:GetAllFoodIds()
    for _, foodId in ipairs(allFoodIds) do
        local food = self:GetProduct(XMVCA.XRestaurant.AreaType.FoodArea, foodId)
        --食物还未解锁
        if not food:IsUnlock() then
            return false
        end
    end

    local allIndentIds = self:GetAllIndentIds()
    for _, performId in ipairs(allIndentIds) do
        local performData = self._Model:GetPerformData(performId)
        --订单还未完成
        if not performData:IsFinish() then
            return false
        end
    end
    
    local allPerformIds = self:GetAllPerformIds()
    for _, performId in ipairs(allPerformIds) do
        local performData = self._Model:GetPerformData(performId)
        --事件还未完成
        if not performData:IsFinish() then
            return false
        end
    end
    
    return true
end

function XRestaurantControl:GetAllPerformIds()
    if not self._AllPerformIds then
        self._AllPerformIds = self._Model:GetAllPerformIds()
    end
    return self._AllPerformIds
end

function XRestaurantControl:GetAllIndentIds()
    if not self._AllIndentIds then
        self._AllIndentIds = self._Model:GetAllIndentIds()
    end
    return self._AllIndentIds
end

function XRestaurantControl:SendEvent(eventId, ...)
    local func = self._EventFunc[eventId]
    if not func then
        XLog.Error("eventId = " .. eventId .. " is unregistered!")
        return
    end
    func(...)
end

function XRestaurantControl:SubscribeEvent(eventId, func)
    if not self._EventFunc then
        self._EventFunc = {}
    end
    self._EventFunc[eventId] = func
end

function XRestaurantControl:UnsubscribeEvent(eventId)
    if not self._EventFunc then
        return
    end
    self._EventFunc[eventId] = nil
end

function XRestaurantControl:GetLoader()
    if self._Loader then
        return self._Loader
    end
    self._Loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XRestaurant)
    
    return self._Loader
end

function XRestaurantControl:UnloadAll()
    if not self._Loader then
        return
    end
    self._Loader:UnloadAll()
    self._Loader = nil
end

--endregion------------------工具接口 finish------------------




--region   ------------------红点 start-------------------

function XRestaurantControl:CheckTaskRedPoint()
    return XMVCA.XRestaurant:CheckTaskRedPoint()
end

function XRestaurantControl:IsAllTaskFinished()
    return self._Model:IsAllTaskFinished()
end

function XRestaurantControl:CheckPhotoRedPoint()
    local perform = self:GetRunningPerform()
    if not perform or not perform:IsOnGoing() then
        return false
    end

    local taskIds = perform:GetPerformTaskIds()
    for _, taskId in ipairs(taskIds) do
        --包含拍照任务且任务未完成
        if perform:IsContainPhoto(taskId) 
                and not perform:CheckTaskFinsh(taskId) then
            return true
        end
    end
    return false
end

function XRestaurantControl:CheckMenuSingTabRedPoint(tabId)
    if not self._Business:CheckMenuTabInTime(tabId) then
        return false
    end
    local key = self._Model:GetCookiesKey("MenuTab_" .. tostring(tabId))
    local recordCount = XSaveTool.GetData(key) or 0
    local count = 0
    if tabId == XMVCA.XRestaurant.MenuTabType.Perform then
        count = self:GetUnlockPerformCount()
    elseif tabId == XMVCA.XRestaurant.MenuTabType.Indent then
        count = self:GetUnlockIndentCount()
    elseif tabId == XMVCA.XRestaurant.MenuTabType.Food then
        count = self:GetUnlockProductListCount(XMVCA.XRestaurant.AreaType.FoodArea)
    end
    
    return recordCount ~= count
end

function XRestaurantControl:CheckMenuRedPoint(tabId)
    if XTool.IsNumberValid(tabId) then
        return self:CheckMenuSingTabRedPoint(tabId)
    end
    
    local menuIds = self._Model:GetMenuTabList()
    for _, menuId in ipairs(menuIds) do
        if self:CheckMenuSingTabRedPoint(menuId) then
            return true
        end
    end
    return false
end

function XRestaurantControl:MarkMenuRedPoint(tabId)
    local key = self._Model:GetCookiesKey("MenuTab_" .. tostring(tabId))
    local recordCount = XSaveTool.GetData(key) or 0
    local count = 0
    if tabId == XMVCA.XRestaurant.MenuTabType.Perform then
        count = self:GetUnlockPerformCount()
    elseif tabId == XMVCA.XRestaurant.MenuTabType.Indent then
        count = self:GetUnlockIndentCount()
    elseif tabId == XMVCA.XRestaurant.MenuTabType.Food then
        count = self:GetUnlockProductListCount(XMVCA.XRestaurant.AreaType.FoodArea)
    end
    if recordCount == count then
        return
    end
    XSaveTool.SaveData(key, count)
    self._Business:UpdateMenuRedPointMarkCount()
end

function XRestaurantControl:CheckPerformRedPoint(performId)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    local perform = self:GetPerform(performId)
    if not perform or not perform:IsFinish() then
        return false
    end
    local key = self._Model:GetCookiesKey("Perform_" .. tostring(performId))
    if not XSaveTool.GetData(key) then
        return true
    end
    return false
end

function XRestaurantControl:MarkPerformRedPoint(performId)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    local perform = self:GetPerform(performId)
    if not perform or not perform:IsFinish() then
        return false
    end
    local key = self._Model:GetCookiesKey("Perform_" .. tostring(performId))
    if XSaveTool.GetData(key) then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XRestaurantControl:MarkPerformListRedPoint(performIds)
    for _, id in ipairs(performIds) do
        self:MarkPerformRedPoint(id)
    end
end

function XRestaurantControl:CheckHotSaleRedPoint()
    local openDay = self._Model:GetOpenDays()
    local key = self._Model:GetCookiesKey("HotSaleRedPoint" .. openDay)
    if not XSaveTool.GetData(key) then
        return true
    end
    return false
end

function XRestaurantControl:MarkHotSaleRedPoint()
    local openDay = self._Model:GetOpenDays()
    local key = self._Model:GetCookiesKey("HotSaleRedPoint" .. openDay)
    if XSaveTool.GetData(key) then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XRestaurantControl:CheckSingleLevelUpgradeRedPoint(level)
    level = XMVCA.XRestaurant:GetSafeRestLevel(level)
    local curLv = self:GetRestaurantLv()

    if curLv >= level or level <= 0 then
        return false
    end

    local levelUpgrade = self:GetUpgradeCondition(level - 1)
    local conditionList = self:GetRestaurantUnlockConditionList(levelUpgrade)
    if XTool.IsTableEmpty(conditionList) then
        return true
    end
    for _, condition in pairs(conditionList) do
        if not condition.Finish then
            return false
        end
    end
    return true
end

function XRestaurantControl:CheckRestaurantUpgradeRedPoint(level)
    if not self._Business:IsInBusiness() then
        return false
    end
    if XTool.IsNumberValid(level) then
        return self:CheckSingleLevelUpgradeRedPoint(level)
    end
    local curLv = self:GetRestaurantLv()
    --for lv = curLv + 1, XMVCA.XRestaurant.RestLevelRange.Max do
    --    if self:CheckSingleLevelUpgradeRedPoint(lv) then
    --        return true
    --    end
    --end
    
    return self:CheckSingleLevelUpgradeRedPoint(curLv + 1)
end

function XRestaurantControl:CheckSingleBuffRedPoint(buffId)
    local buff = self:GetBuff(buffId)
    --等级不足时不检查
    if not buff or not buff:IsReachLevel() then
        return false
    end
    local key = self._Model:GetCookiesKey("Unlock_Buff_" .. tostring(buffId))
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    return false
end

function XRestaurantControl:CheckBuffRedPoint(areaType, buffId)
    if not areaType and not buffId then
        for _, aType in pairs(XMVCA.XRestaurant.AreaType) do
            if aType ~= XMVCA.XRestaurant.AreaType.None then
                local buffIds = self:GetBuffIdList(aType)
                for _, bId in ipairs(buffIds) do
                    if self:CheckSingleBuffRedPoint(bId) then
                        return true
                    end
                end
            end
        end
    elseif not buffId then
        local buffIds = self:GetBuffIdList(areaType)
        for _, bId in ipairs(buffIds) do
            if self:CheckSingleBuffRedPoint(bId) then
                return true
            end
        end
    end
    return self:CheckSingleBuffRedPoint(buffId)
end

function XRestaurantControl:MarkBuffRedPoint(buffId)
    local buff = self:GetBuff(buffId)
    --等级不足时不检查
    if not buff or not buff:IsReachLevel() then
        return false
    end
    local key = self._Model:GetCookiesKey("Unlock_Buff_" .. tostring(buffId))
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
    self._Business:UpdateBuffRedPointMarkCount()
end

function XRestaurantControl:CheckCashierLimitRedPoint()
    return XMVCA.XRestaurant:CheckCashierLimitRedPoint()
end

function XRestaurantControl:MarkCashierLimitRedPoint()
    --未达到上限无需标记
    if not self:CheckCashierLimitRedPoint() then
        return
    end
    local timeStamp = XTime.GetSeverNextRefreshTime()
    local key = self._Model:GetCookiesKey("CashierLimitNextRefresh_" .. timeStamp)
    --已经更新了
    if XSaveTool.GetData(key) then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XRestaurantControl:CheckWorkBenchRedPoint(areaType, benchId)
    -- 空闲人数小于0
    local freeCount = self:GetFreeCharacterCount()
    if freeCount <= 0 then
        return false
    end
    --食谱任务全部完成
    --local recipeId = self:GetRecipeTaskId()
    --local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)
    --
    --local isFinishAll = true
    --for _, taskId in ipairs(taskCfg.TaskId) do
    --    if not XDataCenter.TaskManager.CheckTaskFinished(taskId) then
    --        isFinishAll = false
    --        break
    --    end
    --end
    --
    --if isFinishAll then
    --    return false
    --end

    if XTool.IsNumberValid(benchId) then
        local workBench = self:GetWorkbench(areaType, benchId)
        return workBench:IsFree()
    else
        local list = self:GetUnlockWorkbenches(areaType)
        for _, bench in pairs(list) do
            if bench:IsFree() then
                return true
            end
        end
    end
    return false
end

function XRestaurantControl:CheckRecipeTaskRedPoint()
    return XMVCA.XRestaurant:CheckRecipeTaskRedPoint()
end

function XRestaurantControl:CheckAchievementTaskRedPoint()
    return XMVCA.XRestaurant:CheckAchievementTaskRedPoint()
end

function XRestaurantControl:CheckDailyTaskRedPoint()
    return XMVCA.XRestaurant:CheckDailyTaskRedPoint()
end

function XRestaurantControl:UpdateOfflineRecord()
    self._OfflineRecord = self._Business:IsShowOfflineBill()
    self._OfflineTimeNow = XTime.GetServerNowTimestamp()
end

function XRestaurantControl:IsShowOfflineBill()
    return self._OfflineRecord and true or false
end

function XRestaurantControl:GetOfflineTimeNow()
    return self._OfflineTimeNow
end

--endregion------------------红点 finish------------------



--region   ------------------协议请求 start-------------------

function XRestaurantControl:ClearRequest()
    self._ExitRoomRequest = nil
    self._StopRequest = nil
    self._SwitchBuffRequest = nil
    self._CollectCashierRequest = nil
    self._AssignRequest = nil
    self._AccelerateRequest = nil
    self._LevelUpRequest = nil
    self._OfflineBillRequest = nil
end

function XRestaurantControl:OnPerformFinish(performId, func)
    local perform = self:GetPerform(performId)
    local finish = XMVCA.XRestaurant.PerformState.Finish
    perform:SetState(finish)
    if perform:IsIndent() then
        self:GetRoom():ChangeIndentNpcState(finish)
    elseif perform:IsPerform() then
        self:GetRoom():StopPerformance()
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)

    if func then func() end
    
    self._Business:UpdateMenuRedPointMarkCount()
    
    self._Model:UpdateHotSale(true)
end

function XRestaurantControl:OnLevelUp(level, goodsList, cb)
    local syncOpenUi = asynTask(XLuaUiManager.Open)
    RunAsyn(function()
        --升级弹窗
        syncOpenUi("UiRestaurantPopupUpgrade", level)
        --奖励弹窗
        if not XTool.IsTableEmpty(goodsList) then
            local syncOpenObtain = asynTask(function(rewardGoodsList, cb)
                self:OpenCommonObtain(rewardGoodsList, nil, cb, cb)
            end)
            syncOpenObtain(goodsList)
        end
        --按照顺序移除对应UI栈
        local uiList = { "UiRestaurantHire" }
        for _, uiName in ipairs(uiList) do
            XLuaUiManager.Remove(uiName)
        end
        --升级
        self._Business:LevelUp(level)
        --标记为升级
        self._Model:MarkLevelUp(true)
        
        --关闭场景
        self:ExitRoom()

        --进入新场景
        XMVCA.XRestaurant:ExOpenMainUi()

        --更新红点
        self._Business:UpdateBuffRedPointMarkCount()

        if cb then
            cb()
        end
    end)
end

--- 请求离开房间
---@param func function 协议返回成功回调
---@param cb function 协议返回成功/协议在Cd内 回调
--------------------------
function XRestaurantControl:RequestExitRestaurant(func, cb)
    if not XLoginManager.IsLogin() then
        return
    end
    if not self._ExitRoomRequest then
        self._ExitRoomRequest = XNetworkCallCd.New("RestaurantExitRequest", 1)
    end

    --避免多次发送
    if self._IsRequestExitRoom then
        if func then func() end
        return
    end
    self._IsRequestExitRoom = true
    
    local responseCb = function()
        self._IsRequestExitRoom = false
        if func then func() end
    end
    
    self._ExitRoomRequest:Call(nil, responseCb, cb)
end

function XRestaurantControl:RequestStopAllByArea(areaType, func)
    if not self._StopRequest then
        self._StopRequest = XNetworkCallCd.New("RestaurantAllStopRequest", 1)
    end
    local requestCb = function()

        self:StopAllByArea(areaType)

        if func then func() end
    end
    self._StopRequest:Call({ SectionType = areaType }, requestCb)
end

function XRestaurantControl:RequestCollectOrder(orderId, func)
    if XMain.IsEditorDebug then
        XLog.Error("该方法已废弃")
    end
    --XNetwork.Call("RestaurantTakeOrderRequest", { OrderId = orderId }, function(res)
    --    if res.Code ~= XCode.Success then
    --        XUiManager.TipCode(res.Code)
    --        return
    --    end
    --    self._Business:UpdatePerformInfo(res.OrderInfos)
    --    
    --    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)
    --
    --    if func then func() end
    --end)
end

function XRestaurantControl:RequestFinishOrder(orderId, func)
    if XMain.IsEditorDebug then
        XLog.Error("该方法已废弃")
    end
    --XNetwork.Call("RestaurantFinishOrderRequest", { OrderId = orderId }, function(res)
    --    if res.Code ~= XCode.Success then
    --        XUiManager.TipCode(res.Code)
    --        return
    --    end
    --    local indent = self:GetRunningIndent()
    --    if indent then
    --        indent:SetState(XMVCA.XRestaurant.PerformState.Finish)
    --    end
    --
    --    self:GetRoom():ChangeIndentNpcState(XMVCA.XRestaurant.PerformState.Finish)
    --
    --    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)
    --
    --    if func then func(res.RewardGoodsList) end
    --
    --    self._Business:UpdateMenuRedPointMarkCount()
    --end)
end

function XRestaurantControl:RequestUnlockBuff(buffId, cb)
    XNetwork.Call("RestaurantUnlockSectionBuffRequest", { BuffId = buffId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local buff = self:GetBuff(buffId)
        buff:Unlock()

        --触发更新
        self._Business:UpdateBuffRedPointMarkCount()
        if cb then cb() end
    end)
end

function XRestaurantControl:RequestSwitchBuff(areaType, buffId, cb)
    if not self._SwitchBuffRequest then
        self._SwitchBuffRequest = XNetworkCallCd.New("RestaurantSwitchSectionBuffRequest", 1)
    end
    local req = {
        BuffId = buffId
    }

    local responseCb = function(res)

        --触发更新
        self._Business:UpdateBuffRedPointMarkCount()
        if cb then cb() end
    end
    
    self._SwitchBuffRequest:Call(req, responseCb)
end

function XRestaurantControl:RequestCollectCashier(func)
    if not self._CollectCashierRequest then
        self._CollectCashierRequest = XNetworkCallCd.New("RestaurantCashierRewardRequest", 5)
    end
    local responseCb = function(res)
        local cashier = self:GetCashier()
        cashier:UpdateCount(0)
        if func then
            func(res.RewardGoodsList)
        end
    end
    self._CollectCashierRequest:Call(nil, responseCb)
end

function XRestaurantControl:RequestAssignWork(areaType, characterId, index, productId, cb)
    if not self._AssignRequest then
        self._AssignRequest = XNetworkCallCd.New("RestaurantDispatchWorkRequest", 1)
    end

    local benchModel = self:GetWorkbench(areaType, index)
    local proId = benchModel:GetProductId()
    local isSameProduct = proId == productId and proId ~= 0
    local isSameRole = false
    if XTool.IsNumberValid(characterId) then
        local character = self:GetCharacter(characterId)
        local aType, bId = character:GetAreaType(), character:GetWorkBenchId()
        if aType == areaType and bId == index then
            isSameRole = true
        end
    end
    
    if isSameProduct and isSameRole then
        XUiManager.TipMsg(self:GetStaffWorkTip(2))
        return
    end

    local responseCb = function(res)
        local desc
        if characterId > 0 then
            desc = string.format(self:GetProduceDesc(areaType), benchModel:GetStaffName(), benchModel:GetProductName())
        else
            local title
            title, desc = benchModel:GetStopTipTitleAndContent()
        end

        if cb then cb() end
        
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, desc)
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_WORK_BENCH_CHANGE_STAFF)
    end

    local req = {
        SectionType = areaType,
        CharacterId = characterId,
        Index = index,
        ProductId = productId
    }

    self._AssignRequest:Call(req, responseCb)
end

function XRestaurantControl:RequestAccelerate(areaType, index, count, cb)
    if not self._AccelerateRequest then
        self._AccelerateRequest = XNetworkCallCd.New("RestaurantAccelerateRequest", 1)
    end
    local hasCount = XDataCenter.ItemManager.GetCount(XMVCA.XRestaurant.ItemId.RestaurantAccelerate)
    if hasCount < count then
        return
    end

    local responseCb = function(res)
        local list = res.RewardGoodsList
        if not XTool.IsTableEmpty(list) then
            self:OpenCommonObtain(list)
        end
        if cb then cb() end
    end

    local req = {
        SectionType = areaType,
        Index = index,
        Count = count
    }

    self._AccelerateRequest:Call(req, responseCb)
end

function XRestaurantControl:RequestRestaurantSign(cb)
    XNetwork.Call("RestaurantSignRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Business:UpdateSignData(true)
        if table.nums(res.RewardGoodsList) > 0 then
            self:OpenCommonObtain(res.RewardGoodsList)
        end

        self:GetRoom():ChangeSignNpcState(XMVCA.XRestaurant.SignState.Complete)

        if cb then cb() end
    end)
end

--- 招募员工
--------------------------
function XRestaurantControl:RequestEmployStaff(characterId, cb)
    local character = self:GetCharacter(characterId)
    if character:IsRecruit() then
        return
    end
    local count = self:GetRecruitCharacterCount()
    local limit = self:GetCharacterLimit()
    if limit <= count then
        XUiManager.TipMsg(self._Model:GetClientConfigValue("StaffRecruitTip", 1))
        return
    end
    local consumeData = character:GetCharacterEmployConsume()
    for _, data in ipairs(consumeData) do
        local count = XDataCenter.ItemManager.GetCount(data.ItemId)
        if count < data.Count then
            XUiManager.TipText("CommonCoinNotEnough")
            return
        end
    end
    local req = {
        CharacterId = characterId
    }
    XNetwork.Call("RestaurantEmployRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        character:Recruit()
        self:Broadcast(string.format(self:GetBoardCastTips(1), character:GetName()))
        self._Business:UpdateLevelConditionEventChange()
        if cb then cb() end
        
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_EMPLOY_STAFF)
    end)
end

--- 升级员工
--------------------------
function XRestaurantControl:RequestLevelUpStaff(characterId, cb)
    local character = self:GetCharacter(characterId)
    if not character then
        return
    end
    if not character:IsRecruit() then
        return
    end
    local level = character:GetLevel()
    if level >= XMVCA.XRestaurant.StaffLevelRange.Max then
        return
    end
    local consumeData = character:GetCharacterLevelUpConsume(level)
    for _, data in pairs(consumeData) do
        local count = XDataCenter.ItemManager.GetCount(data.ItemId)
        if count < data.Count then
            XUiManager.TipText("CommonCoinNotEnough")
            return
        end
    end

    local responseCb = function(res)
        local tip = string.format(self:GetBoardCastTips(2), character:GetName(), character:GetLevelStr())
        self:Broadcast(tip)
        self._Business:UpdateLevelConditionEventChange()
        if cb then cb(character) end
    end

    local req = {
        CharacterId = characterId
    }
    if not self._LevelUpRequest then
        self._LevelUpRequest = XNetworkCallCd.New("RestaurantCharacterUpgradeRequest", 1)
    end
    self._LevelUpRequest:Call(req, responseCb)
end

function XRestaurantControl:RequestReceiveOfflineBill(cb)
    if not self._OfflineBillRequest then
        self._OfflineBillRequest = XNetworkCallCd.New("RestaurantOfflineBillRewardRequest", 1)
    end
    local responseCb = function(res)
        self._Business:UpdateAccount(0, XTime.GetServerNowTimestamp())
        self:UpdateOfflineRecord()
        if cb then cb(res.RewardGoodsList) end
    end

    self._OfflineBillRequest:Call(nil, responseCb)
end

function XRestaurantControl:RequestLevelUpRestaurant(cb)
    local level = self:GetRestaurantLv()
    if level >= XMVCA.XRestaurant.RestLevelRange.Max then
        return
    end
    local upgradeCondition = self:GetUpgradeCondition(level)
    for _, consume in pairs(upgradeCondition.ConsumeData or {}) do
        local count = XDataCenter.ItemManager.GetCount(consume.ItemId)
        if count < consume.Count then
            XUiManager.TipText("CommonCoinNotEnough")
            return
        end
    end

    XNetwork.Call("RestaurantUpgradeRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:OnLevelUp(res.RestaurantLv, res.RewardGoodsList, cb)
    end)
end

--请求接取演出
function XRestaurantControl:RequestTakePerform(performId, record, func)
    local perform = self:GetPerform(performId)
    if not perform or not perform:IsNotStart() then
        return
    end
    if not XTool.IsTableEmpty(record) then
        XMessagePack.MarkAsTable(record)
    end
    local req = {
        PerformId = performId,
        PerformStoryInfo = record
    }
    XNetwork.Call("RestaurantTakePerformRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Business:UpdatePerformInfo(res.PerformInfos)

        self._Business:UpdateMenuRedPointMarkCount()
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)
        if func then func() end
    end)
end

function XRestaurantControl:RequestFinishPerform(performId, func)
    local perform = self:GetPerform(performId)
    if not perform or perform:IsNotStart() then
        return
    end
    if not perform:CheckPerformFinish() then
        return
    end
    local req = {
        PerformId = performId,
    }
    XNetwork.Call("RestaurantFinishPerformRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            local perform = self:GetPerform(performId)
            local syncOpen = asynTask(function(goodsList, cb)
                if perform:IsIndent() then
                    self:OpenUnlockFood(goodsList, cb)
                else
                    self:OpenCommonObtain(goodsList, nil, cb, cb)
                end
            end)
            RunAsyn(function()
                syncOpen(res.RewardGoodsList)
                self:OnPerformFinish(performId, func)
            end)
        else
            self:OnPerformFinish(performId, func)
        end
    end)
end

--请求截图 - 只有截图任务完成 performId 才会为有效值
function XRestaurantControl:RequestDoScreenShot(performId, taskId, func)
    XNetwork.Call("RestaurantPhotoRequest", { PerformId = performId, TaskId = taskId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Business:UpdatePerformInfo(res.PerformInfos)

        if func then func() end
    end)
end

--endregion------------------协议请求 finish------------------

return XRestaurantControl