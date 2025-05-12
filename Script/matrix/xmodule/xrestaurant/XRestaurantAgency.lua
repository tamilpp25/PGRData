local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

--region   ------------------C#函数 start-------------------
local CsClamp = CS.UnityEngine.Mathf.Clamp
local CsFloor = CS.UnityEngine.Mathf.Floor
--endregion------------------C#函数 finish------------------
---@class XRestaurantAgency : XFubenActivityAgency
---@field private _Model XRestaurantModel
---@field private _SceneObj UnityEngine.GameObject
local XRestaurantAgency = XClass(XFubenActivityAgency, "XRestaurantAgency")

local STR_SECOND, STR_MINUTE

local IsShopComplete = nil
local IsEnterActivity


function XRestaurantAgency:OnInit()
    self:RegisterActivityAgency()
    self.IsInitOnce = false --只会初始化一次
    self._InActivity = false --是否处于活动玩法中
    self._SceneObj = nil
    IsShopComplete = nil
    IsEnterActivity = nil
end

function XRestaurantAgency:OnLoginOut()
    IsShopComplete = nil
    IsEnterActivity = nil
end

function XRestaurantAgency:InitRpc()
    XRpc.NotifyRestaurantData = handler(self, self.NotifyRestaurantData)
    XRpc.NotifyRestaurantSettleUpdate = handler(self, self.NotifyRestaurantSettleUpdate)
end

function XRestaurantAgency:InitEvent()
end

--初始化餐厅枚举，只有活动开启才会分配内存
function XRestaurantAgency:InitEnum()
    --餐厅等级范围
    self.RestLevelRange = {
        Min = 1,
        Max = 12
    }
    --员工等级范围
    self.StaffLevelRange = {
        Low = 1,
        Medium = 2,
        High = 3,
        Max = 3
    }
    --区域类型
    self.AreaType = {
        --未工作
        None = 0,
        -- 备菜
        IngredientArea = 1,
        -- 做菜
        FoodArea = 2,
        -- 售卖
        SaleArea = 3
    }
    --工作状态
    self.WorkState = {
        -- 空闲
        Free = 1,
        -- 工作中
        Working = 2,
        -- 工作暂停
        Pause = 3,
    }
    --订单状态
    self.PerformState = {
        NotStart = 0,
        OnGoing  = 1,
        Finish   = 2,
    }
    --道具Id
    self.ItemId = {
        --升级货币
        RestaurantUpgradeCoin = 63407,
        --商店货币
        RestaurantShopCoin = 63408,
        --加速道具
        RestaurantAccelerate = 63409,
    }
    --时间单位
    self.TimeUnit = {
        Second = 1,
        Minute = 60,
        Hour = 3600
    }
    --保留小数位数
    self.Digital = {
        One = 1,
        Two = 2,
    }
    --签到状态
    self.SignState = {
        Incomplete = 1, --签到未完成
        Complete   = 2, --签到已完成
    }
    --埋点按钮
    self.BuryingButton = {
        BtnShop = 1,
        BtnTask = 2,
        BtnMenu = 3,
        BtnGo = 4,
        BtnHot = 5,
        BtnStatistics = 6,
    }
    --任务类型
    self.TaskType = {
        Daily       = 1, --每日任务
        Recipe      = 2, --食谱任务
        Activity    = 3, --活动任务
    }
    --餐厅升级效果类型
    self.EffectType = {
        IngredientCount = 1,
        FoodCount = 2,
        SaleCount = 3,
        CharacterLimit = 4,
        CashierLimit = 5,
        HotSaleAddition = 6,
    }
    --餐厅日志页签类型
    self.MenuTabType = {
        Perform = 1, --事件
        Indent  = 2, --订单
        Food = 2, --食谱
    }
    --对话类型
    self.MessageType = {
        Auto = 1,
        Select = 2,
    }
    --演出类型
    self.PerformType = {
        --演出
        Perform = 1,
        --订单
        Indent = 2,
    }
    --ConditionType
    self.ConditionType = {
        --获得收银台奖励
        CashierReward = 1,
        --交付产品
        SubmitProduct = 2,
        --拍照
        Photo = 3,
        --制作产品
        ProductAdd = 4,
        --消耗产品
        ProductConsume = 5,
        --使用增益
        SectionBuff = 6,
        --制作热销产品
        HotSaleProductAdd = 7,
        --消耗热销产品
        HotSaleProductConsume = 8,
    }
    self.EventId = {
        OnShopUiClose = 1,
        OnShowPerformTip = 2,
    }
    --用于消除误差
    self.Inaccurate = 0.0000001
    --收银台产品Ud
    self.CashierId = 999

    STR_MINUTE = CS.XTextManager.GetText("Minute")
    STR_SECOND = CS.XTextManager.GetText("Second")
end

function XRestaurantAgency:InitOnce()
    if self.IsInitOnce then
        return
    end
    self:InitEnum()

    self.IsInitOnce = true
end

function XRestaurantAgency:IsOpen()
    return self._Model:IsOpen()
end

function XRestaurantAgency:ExOpenMainUi()
    --功能未开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Restaurant) then
        return
    end
    --时间未开启
    if not self:IsOpen() then
        XUiManager.TipText("CommonActivityNotStart")
        return
    end
    XLuaUiManager.Open("UiLoading", LoadingType.Restaurant)
    local isLevelUp = self._Model:IsLevelUp()
    if isLevelUp then
        self:LoadScene(isLevelUp)
    else
        self:RestaurantEnterRequest(function()
            self:LoadScene(isLevelUp)
        end, function() XLuaUiManager.Close("UiLoading") end)
    end
end

function XRestaurantAgency:LoadScene(isLevelUp)
    local sceneUrl = self._Model:GetRestaurantSceneUrl()
    if string.IsNilOrEmpty(sceneUrl) then
        return
    end
    ---@type XLoaderUtil
    local loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XRestaurant)
    loader:LoadAsync(sceneUrl, function(asset)
        if not asset then
            XLog.Error("restaurant load resource error: asset path = " .. sceneUrl)
            return
        end
        self._SceneAsset = sceneUrl
        self._SceneObj = XUiHelper.Instantiate(asset)

        if isLevelUp then
            XLuaUiManager.OpenWithCallback("UiRestaurantMain", function()
                XLuaUiManager.Remove("UiLoading")
            end)
        else
            --释放无用资源
            CS.UnityEngine.Resources.UnloadUnusedAssets()
            --手动GC
            LuaGC()

            XLuaUiManager.OpenWithCallback("UiRestaurantEntrance", function()
                XLuaUiManager.Remove("UiLoading")
            end)
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_ENTER_ROOM)
    end)
end

function XRestaurantAgency:GetSceneObj()
    return self._SceneObj
end

function XRestaurantAgency:ResetSceneObj()
    ---@type XLoaderUtil
    local loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XRestaurant)
    loader:Unload(self._SceneAsset)
    self._SceneObj = nil
end

function XRestaurantAgency:ExCheckInTime()
    return XFubenActivityAgency.ExCheckInTime(self)
end

function XRestaurantAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    return self.ExConfig
end

function XRestaurantAgency:ExGetProgressTip()
    local level = self._Model:GetRestaurantLv()
    return XUiHelper.GetText("RestaurantLevelText", level)
end

function XRestaurantAgency:ExGetRunningTimeStr()
    if not self._Model:IsOpen() then
        return ""
    end
    local endTime, str
    local nowTime = XTime.GetServerNowTimestamp()
    if self._Model:IsInBusiness() then
        endTime = self._Model:GetActivityEndTime()
        local timeStr = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        str = XUiHelper.GetText("RemainingBusinessTime", timeStr)
    else
        endTime = self._Model:GetShopEndTime()
        local timeStr = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        str = XUiHelper.GetText("RemainingRedemptionTime", timeStr)
    end
    
    return str
end

function XRestaurantAgency:GetSafeRestLevel(level)
    if not self.IsInitOnce then
        return level
    end
    return math.floor(CsClamp(level, self.RestLevelRange.Min, self.RestLevelRange.Max))
end

function XRestaurantAgency:IsMaxLevel()
    return self:GetRestaurantLv() >= self.RestLevelRange.Max
end

function XRestaurantAgency:GetSafeStaffLevel(level)
    if not self.IsInitOnce then
        return level
    end
    return math.floor(CsClamp(level, self.StaffLevelRange.Low, self.StaffLevelRange.Max))
end

function XRestaurantAgency:GetRestaurantLv()
    return self._Model:GetRestaurantLv()
end

function XRestaurantAgency:GetGreaterLevelCharacterCount(level)
    return self._Model:GetGreaterLevelCharacterCount(level)
end

function XRestaurantAgency:IsSamePerformState(performId, state)
    local performData = self._Model:GetPerformData(performId)
    if not performData then
        return false
    end
    return performData:GetState() == state
end

--region   ------------------工具接口 start-------------------

function XRestaurantAgency:StrPos2Vector3(str, separator)
    if string.IsNilOrEmpty(str) then
        return Vector3.zero
    end
     local tmp = string.Split(str, separator)
    local num = {}
    for i = 1, 3 do
        local value = tmp[i]
        num[i] = str and tonumber(value) or 0
    end
    return Vector3(num[1], num[2], num[3])
end

function XRestaurantAgency:TransProduceTime(speed)
    local min = math.floor(speed / 60)
    local sec = speed - min * 60
    if sec == 0 then
        return string.format("%d%s0%s ", min, STR_MINUTE, STR_SECOND)
    elseif min == 0 then
        return string.format("%d%s", sec, STR_SECOND)
    end
    return string.format("%d%s%02d%s", min, STR_MINUTE, sec, STR_SECOND)
end

function XRestaurantAgency:Burying(btnId, uiName)
    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    dict["update_time"] = XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp())
    dict["ui_name"] = uiName
    dict["btn_id"] = btnId

    CS.XRecord.Record(dict, "900002", "RestaurantRecord")
end

function XRestaurantAgency:BuryingTakePhoto()
    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "900004", "RestaurantTakePhotoRecord")
end

function XRestaurantAgency:BuryingSavePhoto()
    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "900005", "RestaurantSavePhotoRecord")
end

function XRestaurantAgency:CheckBaseOpen()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Restaurant) then
        return false
    end
    if not self:IsOpen() then
        return false
    end
    return true
end

--每日任务红点
function XRestaurantAgency:CheckDailyTaskRedPoint()
    local timeLimitTaskIds = self._Model:GetTimeLimitTaskIds()

    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
    end

    return false
end

--成就任务红点
function XRestaurantAgency:CheckAchievementTaskRedPoint()
    local timeLimitTaskIds = self._Model:GetTimeLimitTaskIds()

    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
    end

    return false
end

--食谱任务红点
function XRestaurantAgency:CheckRecipeTaskRedPoint()
    --3期厨房，不配置食谱任务
    --if not self:CheckBaseOpen() then
    --    return false
    --end
    --local recipeId = self._Model:GetRecipeTaskId()
    --local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)
    --
    --for _, taskId in ipairs(taskCfg.TaskId) do
    --    if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
    --        return true
    --    end
    --end
    return false
end

--任务入口
function XRestaurantAgency:CheckTaskRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if self:CheckDailyTaskRedPoint() then
        return true
    end
    if self:CheckAchievementTaskRedPoint() then
        return true
    end
    if self:CheckRecipeTaskRedPoint() then
        return true
    end
    return false
end

function XRestaurantAgency:CheckIndentRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end
    local running = self._Model:GetRunningIndentData()
    if not running then
        return false
    end
    return self._Model:CheckPerformFinish(running:GetPerformId())
end

function XRestaurantAgency:CheckPerformRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end
    local running = self._Model:GetRunningPerformData()
    if not running then
        return false
    end
    return self._Model:CheckPerformFinish(running:GetPerformId())
end

function XRestaurantAgency:CheckCashierLimitRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end
    return self._Model:CheckCashierLimit()
end

function XRestaurantAgency:CheckEntranceRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if IsShopComplete == nil 
            and self:CheckShopOpen() then
        self:CheckShopComplete()
        return false
    end

    --策划要求-商店购买完成后，外部红点全部关闭
    if IsShopComplete then
        return false
    end

    if not self._Model:IsInBusiness() then
        return false
    end

    if self:CheckIsFirstEnter() then
        return true
    end

    if self:CheckTaskRedPoint() then
        return true
    end

    if self:CheckIndentRedPoint() then
        return true
    end

    if self:CheckPerformRedPoint() then
        return true
    end

    --每天只展示一次
    local timeStamp = XTime.GetSeverNextRefreshTime()
    local key = self._Model:GetCookiesKey("CashierLimitNextRefresh_" .. timeStamp)

    if not XSaveTool.GetData(key) and self:CheckCashierLimitRedPoint() then
        return true
    end
    
    return false
end

function XRestaurantAgency:CheckIsFirstEnter()
    if IsEnterActivity then
        return false
    end
    local key = self._Model:GetCookiesKey("EnterActivity")
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    IsEnterActivity = true
    return false
end

function XRestaurantAgency:MarkFirstEnterActivity()
    if IsEnterActivity then
        return
    end
    local key = self._Model:GetCookiesKey("EnterActivity")
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    
    XSaveTool.SaveData(key, true)
    IsEnterActivity = true
end

function XRestaurantAgency:CheckShopOpen()
    local functionId = XFunctionManager.FunctionName.ShopCommon
    return XFunctionManager.JudgeCanOpen(functionId) and XFunctionManager.JudgeOpen(functionId)
end

function XRestaurantAgency:CheckShopComplete(cb)
    if IsShopComplete ~= nil then
        if cb then cb(IsShopComplete) end
    end
    if not self:CheckShopOpen() then
        if cb then cb(false) end
        return
    end
    local shopId = self._Model:GetShopId()
    if not XTool.IsNumberValid(shopId) then
        if cb then cb(false) end
        return
    end

    IsShopComplete = false
    XShopManager.GetShopInfo(shopId, function()
        local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)
        local complete = true
        for _, goods in ipairs(goodsList) do
            --不限制次数, 商店无法购买完成 || 购买次数小于上线
            if goods.BuyTimesLimit <= 0 or (goods.TotalBuyTimes < goods.BuyTimesLimit) then
                complete = false
                break
            end
        end
        IsShopComplete = complete
        if cb then cb(complete) end
    end, true)
end

function XRestaurantAgency:ClearShotComplete()
    --如果已经完成了，就不需要清除了
    if IsShopComplete then
        return
    end
    IsShopComplete = nil
end

function XRestaurantAgency:OnActivityEnd()
    --只有处于活动玩法内部，才提出玩家
    if self._InActivity then
        XLuaUiManager.RunMain()
        XUiManager.TipText("CommonActivityEnd")
    end
end

function XRestaurantAgency:SetInActivity(inActivity)
    self._InActivity = inActivity
end

function XRestaurantAgency:IsPhotoCondition(conditionType)
    return conditionType == self.ConditionType.Photo
end

function XRestaurantAgency:IsIndentCondition(conditionType)
    return  conditionType == self.ConditionType.SubmitProduct
            --or conditionType == self.ConditionType.ProductAdd
            --or conditionType == self.ConditionType.ProductConsume
end

function XRestaurantAgency:GetCookiesKey(key)
    return self._Model:GetCookiesKey(key)
end

function XRestaurantAgency:GetCharacterCodeStr(characterId)
    local template = XMVCA.XCharacter:GetCharacterTemplate(characterId, true)
    return template and template.Code or ""
end

--endregion------------------工具接口 finish------------------



--region   ------------------协议 start-------------------

function XRestaurantAgency:NotifyRestaurantData(notifyData)
    if not notifyData then
        return
    end
    self._Model:UpdateNotifyData(notifyData)
end

function XRestaurantAgency:NotifyRestaurantSettleUpdate(notifyData)
    if not notifyData then
        return
    end
    self._Model:UpdateSettleNotifyData(notifyData)
end

function XRestaurantAgency:RestaurantEnterRequest(responseCb, failCb)
    XNetwork.Call("RestaurantEnterRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if failCb then failCb() end
            return
        end
        self:MarkFirstEnterActivity()
        self._Model:GetBusinessData():UpdateAccount(res.OfflineBill, res.OfflineBillUpdateTime)
        if responseCb then responseCb() end
    end)
end

--endregion------------------协议 finish------------------

return XRestaurantAgency