---@class XRestaurantModel : XModel
---@field BusinessData XRestaurantBusiness
---@field _SkillAddDict table<number, table<number, number>>
---@field _StaffLevelTemplate table<number, table<number, XTableRestaurantCharacterLv>>
---@field _StorageAreaTypeTemplate table<number, table<number, XTableRestaurantStorage>>
---@field _HotSaleDict table<number, number>
---@field _Condition XRestaurantCondition
local XRestaurantModel = XClass(XModel, "XRestaurantModel")

local TableKey = {
    -- 活动总控
    RestaurantActivity = { CacheType = XConfigUtil.CacheType.Normal },
    -- 活动配置
    RestaurantConfig = {},
    -- 餐厅等级
    RestaurantLv = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "Lv" },
    -- 员工信息
    RestaurantCharacter = {},
    -- 员工技能
    RestaurantCharacterSkill = { },
    -- 技能类型
    RestaurantSkillType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type" },
    -- 员工等级
    RestaurantCharacterLv = { CacheType = XConfigUtil.CacheType.Temp },
    -- 仓库配置
    RestaurantStorage = { CacheType = XConfigUtil.CacheType.Temp },
    -- 客户端配置
    RestaurantClientConfig = { DirPath = XConfigUtil.DirectoryType.Client,
                               ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    -- 摄像机配置
    RestaurantCameraAuxiliary = { DirPath = XConfigUtil.DirectoryType.Client,
                                  ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Type" },
    -- 食材配置
    RestaurantIngredient = {},
    -- 食物配置
    RestaurantFood = {},
    -- 热销配置
    RestaurantDailyHotSale = { CacheType = XConfigUtil.CacheType.Temp, Identifier = "DayId" },
    -- Buff配置
    RestaurantBuffEffect = {},
    -- 区域Buff
    RestaurantSectionBuff = {},
    -- 签到信息
    SignActivity = {},
    -- 签到奖励
    SignAward = { CacheType = XConfigUtil.CacheType.Temp },
    -- 签到模型
    RestaurantSignModel = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SignDay" },
    -- 订单角色模型
    RestaurantOrderModel = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 顾客信息
    RestaurantCustomer = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 员工模型
    RestaurantCharacterModel = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "CharacterId" },
    -- 工作台位置
    RestaurantWorkPos = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Temp },
    -- 菜单页签
    RestaurantIllustrated = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 餐厅特效
    RestaurantEffect = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 餐厅角色
    RestaurantNpc = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 气泡对话
    RestaurantDialog = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 聊天对话
    RestaurantTalk = {},
    -- 聊天剧情
    RestaurantStory = {},
    -- 聊天演出
    RestaurantPerform = { CacheType = XConfigUtil.CacheType.Normal },
    -- 演出任务
    RestaurantPerformTask = { CacheType = XConfigUtil.CacheType.Normal },
    -- 厨房玩法内部条件表
    RestaurantCondition = { CacheType = XConfigUtil.CacheType.Normal },
    -- 场景预制
    RestaurantPhotoElement = {},
    -- 演员信息
    RestaurantPerformer = { DirPath = XConfigUtil.DirectoryType.Client },
}

local GuideGroupIds = {}

function XRestaurantModel:OnInit()
    self._ActivityId = 0

    self._ConfigUtil:InitConfigByTableKey("Restaurant", TableKey)

    if XMain.IsWindowsEditor then
        self._ConfigUtil:AddCheckerByTableKey(TableKey.RestaurantStory, function(_, templates)
            self:CheckStoryTalkRepeat(templates)
        end)
    end

    self._StaffLevelTemplate = {}
    self._SkillAddDict = {}
    self._StorageAreaTypeTemplate = {}
    self._HotSaleDict = {}
    self._AreaBuffDict = {}
    self._SignAwardTemplate = {}
end

function XRestaurantModel:ClearPrivate()
    self._StaffLevelTemplate = {}
    self._SkillAddDict = {}
    self._StorageAreaTypeTemplate = {}
    self._HotSaleDict = {}
    self._SignAwardTemplate = {}
    self._IndentFoodInfo = nil
    self._MinLevelAreaTypeBuff = nil
    self._TabMenuList = nil
    self._AllBuffIds = nil
    self._AllPerformIds = nil
    self._AllIndentIds = nil
    self._LastUpdateDay = nil
end

function XRestaurantModel:ResetAll()
    XMVCA.XRestaurant:OnLoginOut()
    self:ClearPrivate()
    if self.BusinessData then
        self.BusinessData:ClearAll()
    end
    if self._Condition then
        self._Condition:Release()
    end
    self._Condition = nil
    self.BusinessData = nil
    self._ActivityId = 0
end

function XRestaurantModel:UpdateNotifyData(notifyData)
    self:UpdateActivityId(notifyData.ActivityId)
    self:GetBusinessData():UpdateData(notifyData)
end

function XRestaurantModel:UpdateSettleNotifyData(notifyData)
    self:UpdateActivityId(notifyData.ActivityId)
    self:GetBusinessData():UpdateSettle(notifyData)
end

function XRestaurantModel:UpdateActivityId(activityId)
    if activityId > 0 then
        XMVCA.XRestaurant:InitOnce()
    end
    if self._ActivityId > 0 and self._ActivityId ~= activityId then
        self:DoActivityChanged(activityId)
        return
    end
    self._ActivityId = activityId
end

function XRestaurantModel:DoActivityChanged(activityId)
    if XMain.IsEditorDebug then
        local logs = string.format("活动Id由%s变成了%s", self._ActivityId, activityId)
        XLog.Error(logs)
    end
    self._ActivityId = activityId
    if self.BusinessData then
        self.BusinessData:ClearAll()
    end
    self.BusinessData = nil

    XMVCA.XRestaurant:OnActivityEnd()
end



--region   ------------------商业数据 start-------------------

function XRestaurantModel:ResetActivity()
    self:DoActivityChanged(0)
end

function XRestaurantModel:GetBusinessData()
    if not self.BusinessData then
        self.BusinessData = require("XModule/XRestaurant/XData/XRestaurantBusiness").New()
    end
    return self.BusinessData
end

function XRestaurantModel:GetRestaurantLv()
    local level = self:GetBusinessData():GetLevel()
    return XMVCA.XRestaurant:GetSafeRestLevel(level)
end

function XRestaurantModel:GetSignActivityId()
    return self:GetBusinessData():GetSignActivityId()
end

function XRestaurantModel:GetOpenDays()
    return self:GetBusinessData():GetOpenDays()
end

function XRestaurantModel:IsGetSignReward()
    return self:GetBusinessData():IsGetSignReward()
end

function XRestaurantModel:IsAccelerateUpperLimit()
    return self:GetBusinessData():GetAccelerateUseTimes() >= self:GetAccelerateUseLimit()
end

function XRestaurantModel:GetAccelerateCount()
    return XDataCenter.ItemManager.GetCount(XMVCA.XRestaurant.ItemId.RestaurantAccelerate)
end

function XRestaurantModel:GetAccelerateTime()
    local template = self:GetActivityConfigTemplate()
    return template and template.AccelerateTime or 0
end

function XRestaurantModel:GetWorkbenchData(areaType, index)
    return self:GetBusinessData():GetWorkbenchData(areaType, index)
end

function XRestaurantModel:GetStaffData(charId)
    return self:GetBusinessData():GetStaffData(charId)
end

function XRestaurantModel:GetProductData(areaType, productId)
    return self:GetBusinessData():GetProductData(areaType, productId)
end

function XRestaurantModel:GetBuffData(buffId)
    return self:GetBusinessData():GetBuffData(buffId)
end

function XRestaurantModel:GetUnlockBuffIdDict()
    return self:GetBusinessData():GetUnlockBuffIdDict()
end

function XRestaurantModel:GetAllIndentIds()
    if self._AllIndentIds then
        return self._AllIndentIds
    end
    self:InitPerformIds()
    return self._AllIndentIds
end

function XRestaurantModel:UpdateHotSale(isForce)
    local curDay = self:GetOpenDays()
    if not isForce and self._LastUpdateDay == curDay then
        return
    end
    --清除热销材料
    local allIds = self:GetAllIngredientIds()
    for _, id in ipairs(allIds) do
        local productData = self:GetProductData(XMVCA.XRestaurant.AreaType.IngredientArea, id)
        productData:UpdateHotSale(false)
    end
    --更新食材
    local dict = self:GetHotSaleDataDict(curDay)
    local allIds = self:GetAllFoodIds()
    for _, foodId in ipairs(allIds) do
        local hotValue = (dict[foodId] or 0)
        local isHotSale = hotValue ~= 0
        local productData = self:GetProductData(XMVCA.XRestaurant.AreaType.FoodArea, foodId)

        productData:UpdateHotSale(isHotSale)
        productData:UpdateHotSaleAddition(hotValue)

        if isHotSale and self:CheckFoodUnlock(foodId) then
            local template = self:GetFoodTemplate(foodId)
            for _, ingredientId in ipairs(template.ConsumeIngredientIds) do
                local ingredientData = self:GetProductData(XMVCA.XRestaurant.AreaType.IngredientArea, ingredientId)
                ingredientData:UpdateHotSale(true)
            end
        end
    end
    self._LastUpdateDay = curDay
end

function XRestaurantModel:InitPerformIds()
    ---@type table<number, XTableRestaurantPerform>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantPerform)
    local indentList, performList = {}, {}
    for id, template in pairs(templates) do
        if template.Type == XMVCA.XRestaurant.PerformType.Perform then
            table.insert(performList, id)
        elseif template.Type == XMVCA.XRestaurant.PerformType.Indent then
            table.insert(indentList, id)
        end
    end

    self._AllIndentIds = indentList
    self._AllPerformIds = performList
end

function XRestaurantModel:GetPerformData(performId)
    return self:GetBusinessData():GetPerformData(performId)
end


--- 更新已经解锁的产品, 游戏初始化/升级时调用
--------------------------
function XRestaurantModel:UpdateUnlockProduct()
    local level = self:GetRestaurantLv()

    self._UnlockIngredientIdDict = self:GetUnlockProductDict(level, handler(self, self.GetUnlockIngredient))
    self._UnlockFoodIdDict = self:GetUnlockProductDict(level, handler(self, self.GetUnlockFood))
    
    self:UpdateHotSale(true)
end

function XRestaurantModel:GetUnlockProductDict(level, func)
    local dict = {}
    for lv = XMVCA.XRestaurant.RestLevelRange.Min, level do
        local list = func(lv)
        for _, id in ipairs(list) do
            dict[id] = true
        end
    end

    return dict
end

function XRestaurantModel:IsDefaultFood(foodId)
    local template = self:GetFoodTemplate(foodId)
    if not template.IsDefault then
        local unlockItemIds = template.UnlockItemIds
        if XTool.IsTableEmpty(unlockItemIds) then
            return true
        end
        for index, unlockItemId in ipairs(unlockItemIds) do
            local need = template.UnlockItemCounts[index] or 0
            if XDataCenter.ItemManager.GetCount(unlockItemId) < need then
                return false
            end
        end
    end
    return true
end

function XRestaurantModel:CheckFoodUnlock(foodId)
    local unlockByLv = self:CheckFoodUnlockLv(foodId)
    if not unlockByLv then
        return false
    end
    if not self:IsDefaultFood(foodId) then
        return false
    end
    local template = self:GetFoodTemplate(foodId)
    local consumeIds = template.ConsumeIngredientIds
    if not XTool.IsTableEmpty(consumeIds) then
        for _, ingredientId in ipairs(consumeIds) do
            --对应的食材未解锁
            if not self:CheckIngredientUnlock(ingredientId) then
                return false
            end
        end
    end
    
    return true
end

function XRestaurantModel:CheckFoodUnlockLv(foodId)
    if not self._UnlockFoodIdDict then
        return false
    end
    return self._UnlockFoodIdDict[foodId]
end

function XRestaurantModel:CheckIngredientUnlock(ingredientId)
    if not self._UnlockIngredientIdDict then
        return false
    end
    return self._UnlockIngredientIdDict[ingredientId]
end

function XRestaurantModel:IsLevelUp()
    return self:GetBusinessData():IsLevelUp()
end

function XRestaurantModel:MarkLevelUp(value)
    return self:GetBusinessData():MarkLevelUp(value)
end

--- 记录食谱任务中进度为0的任务Id
--------------------------
function XRestaurantModel:UpdateRecipeTaskMap()
    --3期厨房没有食谱任务
    --local dict = {}
    --local taskTimeLimitId = self:GetRecipeTaskId()
    --local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
    --for _, taskId in ipairs(taskCfg.TaskId) do
    --    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    --    if taskData then
    --        local isZero = true
    --        local schedule = taskData.Schedule or {}
    --        for _, pair in pairs(schedule) do
    --            if pair.Value > 0 then
    --                isZero = false
    --                break
    --            end
    --        end
    --
    --        if isZero then
    --            dict[taskId] = taskId
    --        end
    --    end
    --end
    --self._RecipeTaskDict = dict
end

function XRestaurantModel:CheckUnlockHideRecipe(taskId)
    --3期厨房没有食谱任务
    --if not self._RecipeTaskDict[taskId] then
    --    return false
    --end
    --local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    --if not taskData then
    --    return false
    --end
    --local biggerThanOne = true
    --for _, pair in pairs(taskData.Schedule) do
    --    if pair.Value <= 0 then
    --        biggerThanOne = false
    --        break
    --    end
    --end
    --return biggerThanOne
end

function XRestaurantModel:PopRecipeTaskTip()
    --3期厨房没有食谱任务
    --local recipeId = self:GetRecipeTaskId()
    --local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)
    --local taskIds = taskCfg.TaskId or {}
    --local list = {}
    --
    --for _, taskId in ipairs(taskIds) do
    --    if self:CheckUnlockHideRecipe(taskId) then
    --        table.insert(list, taskId)
    --    end
    --end
    --
    --if not XTool.IsTableEmpty(list) then
    --    local baseTxt = self:GetClientConfigValue("RecipeTaskTriggerTip", 1)
    --    for _, taskId in ipairs(list) do
    --        local template = XTaskConfig.GetTaskCfgById(taskId)
    --        local txt = string.format(baseTxt, template.Title)
    --        XUiManager.TipMsgEnqueue(txt)
    --        self._RecipeTaskDict[taskId] = nil
    --    end
    --end
end

function XRestaurantModel:GetGreaterLevelCharacterCount(level)
    return self:GetBusinessData():GetGreaterLevelCharacterCount(level)
end

function XRestaurantModel:CheckCashierLimit()
    local productData = self:GetProductData(XMVCA.XRestaurant.AreaType.SaleArea, XMVCA.XRestaurant.CashierId)
    if not productData then
        return false
    end
    return productData:GetCount() >= self:GetCashierLimit()
end

--endregion------------------商业数据 finish------------------



--region   ------------------活动数据 start-------------------

---@return XTableRestaurantActivity
function XRestaurantModel:GetActivityTemplate()
    if not XTool.IsNumberValid(self._ActivityId) then
        return
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantActivity, self._ActivityId)
end

---@return XTableRestaurantConfig
function XRestaurantModel:GetActivityConfigTemplate()
    if not XTool.IsNumberValid(self._ActivityId) then
        return
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantConfig, self._ActivityId)
end

---@return XTableSignActivity
function XRestaurantModel:GetSignTemplate()
    local signId = self:GetSignActivityId()
    if not XTool.IsNumberValid(signId) then
        return
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SignActivity, signId)
end

---@return XTableSignAward
function XRestaurantModel:GetSignRewardTemplate(day)
    if XTool.IsTableEmpty(self._SignAwardTemplate) then
        ---@type table<number, XTableSignAward>
        local templates = self._ConfigUtil:GetByTableKey(TableKey.SignAward)
        for _, template in pairs(templates) do
            if not self._SignAwardTemplate[template.SignActivityId] then
                self._SignAwardTemplate[template.SignActivityId] = {}
            end
            self._SignAwardTemplate[template.SignActivityId][template.DayId] = template
        end
    end
    local signId = self:GetSignActivityId()
    if signId <= 0 then
        return
    end
    local dict = self._SignAwardTemplate[signId]
    if not dict then
        XLog.Error("获取签到奖励异常, SignActivityId = " .. signId)
        return
    end
    return dict[day]
end

function XRestaurantModel:GetAccelerateUseLimit()
    local template = self:GetActivityConfigTemplate()
    if not template then
        return 0
    end
    return template.AccelerateUseLimit
end

function XRestaurantModel:GetShopId()
    local template = self:GetActivityTemplate()
    return template and template.ShopId or 0
end

function XRestaurantModel:IsInBusiness()
    local template = self:GetActivityTemplate()
    if not template then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(template.TimeId)
end

function XRestaurantModel:GetActivityEndTime()
    local template = self:GetActivityTemplate()
    if not template then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(template.TimeId)
end

function XRestaurantModel:GetActivityBeginTime()
    local template = self:GetActivityTemplate()
    if not template then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(template.TimeId)
end

function XRestaurantModel:IsShopOpen()
    local template = self:GetActivityTemplate()
    if not template then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(template.ShopTimeId)
end

function XRestaurantModel:GetShopEndTime()
    local template = self:GetActivityTemplate()
    if not template then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(template.ShopTimeId)
end

function XRestaurantModel:GetSignBeginTime()
    local template = self:GetSignTemplate()
    if not template then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(template.TimeId)
end

function XRestaurantModel:GetTimeLimitTaskIds()
    local template = self:GetActivityTemplate()
    if not template then
        return {}
    end
    return template.TimeLimitTaskIds
end

--食谱任务
function XRestaurantModel:GetRecipeTaskId()
    local template = self:GetActivityTemplate()
    if not template then
        return 0
    end
    return template.RecipeTaskId
end

function XRestaurantModel:IsAllTaskFinished()
    local timeLimitTaskIds = self:GetTimeLimitTaskIds()
    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            ----每日任务
            --for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
            --    --任务未完成
            --    if not XDataCenter.TaskManager.CheckTaskFinished(taskId) then
            --        return false
            --    end
            --end
            --成就任务
            for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                if not XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                    return false
                end
            end
        end
    end

    --local recipeId = self:GetRecipeTaskId()
    --local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)
    --
    --for _, taskId in ipairs(taskCfg.TaskId) do
    --    --食谱任务
    --    if not XDataCenter.TaskManager.CheckTaskFinished(taskId) then
    --        return false
    --    end
    --end
    return true
end

function XRestaurantModel:IsOpen()
    if not XTool.IsNumberValid(self._ActivityId) then
        return false
    end

    return self:IsInBusiness() or self:IsShopOpen()
end

function XRestaurantModel:GetUrgentTime()
    local template = self:GetActivityConfigTemplate()
    return template and template.UrgentTime or 0
end

--endregion------------------活动数据 finish------------------



--region   ------------------订单 start-------------------


--endregion------------------订单 finish------------------



--region   ------------------餐厅等级 start-------------------

---@return XTableRestaurantLv
function XRestaurantModel:GetRestaurantLvTemplate(level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantLv, level)
end

---@return number
function XRestaurantModel:GetHotSaleAdditionByRestaurantLevel(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.HotSaleAddition or 0
end

function XRestaurantModel:GetCashierLimit(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.CashierLimit or 0
end

function XRestaurantModel:GetCharacterLimit(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.CharacterLimit or 0
end

function XRestaurantModel:GetUnlockIngredient(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.UnlockIngredient or {}
end

function XRestaurantModel:GetUnlockFood(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.UnlockFood or {}
end

function XRestaurantModel:GetRestaurantSceneUrl(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.ScenePrefab or ""
end

function XRestaurantModel:GetRestaurantTitleIcon(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.TitleIcon or ""
end

function XRestaurantModel:GetRestaurantDecorationIcon(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.DecorationIcon or ""
end

--- 获取餐厅升级条件
---@param level number 餐厅等级
--------------------------
function XRestaurantModel:GetUpgradeCondition(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    if not XTool.IsNumberValid(level) then
        return {}
    end
    local template = self:GetRestaurantLvTemplate(level)
    local itemIds = template.UpgradeNeedItemId or {}
    local itemCounts = template.UpgradeNeedItemCount or {}
    local upgradeCondition = {
        TotalStaffNumber = template.UpgradeNeedCharacterNum,
        SeniorCharacterLv = template.UpgradeNeedSeniorCharacterLv,
        TotalSeniorCharacter = template.UpgradeNeedSeniorCharacterNum,
        ConsumeData = {}
    }
    local list = {}
    for idx, itemId in ipairs(itemIds) do
        local item = {
            ItemId = itemId,
            Count = itemCounts[idx] or 0
        }
        table.insert(list, item)
    end
    upgradeCondition.ConsumeData = list

    return upgradeCondition
end

function XRestaurantModel:GetCustomerLimit(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template and template.CustomerLimit or 0
end

function XRestaurantModel:GetUpgradeConsume(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetRestaurantLvTemplate(level)
    return template.UpgradeNeedItemId, template.UpgradeNeedItemCount
end

--endregion------------------餐厅等级 finish------------------



--region   ------------------员工 start-------------------

---@return XTableRestaurantCharacter
function XRestaurantModel:GetCharacterTemplate(charId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantCharacter, charId)
end

---@return XTableRestaurantCharacterLv
function XRestaurantModel:GetCharacterLevelTemplate(charId, level)
    if XTool.IsTableEmpty(self._StaffLevelTemplate) then
        ---@type table<number, XTableRestaurantCharacterLv>
        local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantCharacterLv)
        for _, template in pairs(templates) do
            if not self._StaffLevelTemplate[template.CharacterId] then
                self._StaffLevelTemplate[template.CharacterId] = {}
            end
            self._StaffLevelTemplate[template.CharacterId][template.Lv] = template
        end
    end
    local dict = self._StaffLevelTemplate[charId]
    if not dict then
        XLog.Error("员工等级表不存在角色Id = " .. charId)
        return
    end
    return dict[level]
end

function XRestaurantModel:GetAllCharacterIds()
    local list = {}
    ---@type table<number, XTableRestaurantCharacter>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantCharacter)

    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end

---@return XTableRestaurantCharacterSkill
function XRestaurantModel:GetCharacterSkillTemplate(skillId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantCharacterSkill, skillId)
end

function XRestaurantModel:GetCharacterSkillIds(charId, level)
    local template = self:GetCharacterLevelTemplate(charId, level)
    if not template then
        return {}
    end
    return template.SkillId
end

function XRestaurantModel:GetCharacterSkillAreaType(skillId)
    local template = self:GetCharacterSkillTemplate(skillId)
    if not template then
        return XMVCA.XRestaurant.AreaType.None
    end
    return template.SectionType
end

---@return XTableRestaurantSkillType
function XRestaurantModel:GetCharacterSkillTypeTemplate(areaType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantSkillType, areaType)
end

--- 获取某个技能对产品的加成
---@param skillId number 技能id
---@return table<number, number>
--------------------------
function XRestaurantModel:GetCharacterSkillAddition(skillId)
    if self._SkillAddDict[skillId] then
        return self._SkillAddDict[skillId]
    end
    local dict = {}
    local template = self:GetCharacterSkillTemplate(skillId)
    if template and template.ProductId then
        for idx, productId in ipairs(template.ProductId) do
            local addition = template.SkillAddition[idx] or 0
            dict[productId] = addition
        end
    end
    self._SkillAddDict[skillId] = dict

    return dict
end

--- 获取多个技能对某个区域的产品加成
---@param skillIds number[] 技能Id列表
---@param areaType number 工作区域
---@param productId number 产品Id
---@return number
--------------------------
function XRestaurantModel:GetCharacterSkillTotalAddition(skillIds, areaType, productId)
    if XTool.IsTableEmpty(skillIds) then
        return 0
    end

    if not XTool.IsNumberValid(productId) then
        return 0
    end

    local add = 0
    for _, skillId in ipairs(skillIds) do
        local targetType = self:GetCharacterSkillAreaType(skillId)
        if targetType == areaType then
            local dict = self:GetCharacterSkillAddition(skillId)
            if dict and dict[productId] then
                add = add + dict[productId]
            end
        end
    end

    return add
end

--- 技能是否对该区域有增益
---@param areaType number 工作区域
---@param skillIds number[] 技能Id列表
---@return boolean
--------------------------
function XRestaurantModel:IsAdditionByAreaType(areaType, skillIds)
    if XTool.IsTableEmpty(skillIds) then
        return false
    end
    for _, skillId in ipairs(skillIds) do
        local targetType = self:GetCharacterSkillAreaType(skillId)
        if targetType == areaType then
            return true
        end
    end
    return false
end

function XRestaurantModel:GetCharacterLevelStr(level)
    return self:GetClientConfigValue("StaffLevelDesc", level)
end

--endregion------------------员工 finish------------------



--region   ------------------食材 start-------------------

--- 食材配置
---@param productId number 食材id
---@return XTableRestaurantIngredient
--------------------------
function XRestaurantModel:GetIngredientTemplate(productId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantIngredient, productId)
end

--- 食材基础生产时间
---@param productId number 食材id
---@return number
--------------------------
function XRestaurantModel:GetIngredientBaseProduceSpeed(productId)
    local template = self:GetIngredientTemplate(productId)
    return template and template.ProduceNeedTime or 0
end

--- 食材图标
---@param productId number 食材id
---@return string
--------------------------
function XRestaurantModel:GetIngredientIcon(productId)
    local template = self:GetIngredientTemplate(productId)
    return template and template.Icon or ""
end

--- 食材名称
---@param productId number 食材id
---@return string
--------------------------
function XRestaurantModel:GetIngredientName(productId)
    local template = self:GetIngredientTemplate(productId)
    return template and template.Name or ""
end

--- 通用的品质图
---@param is3d boolean 是否在3D界面展示
---@return string
--------------------------
function XRestaurantModel:GetCommonQualityIcon(is3d)
    local index = is3d and 1 or 2
    return self:GetClientConfigValue("CommonQualityIconUI", index)
end

function XRestaurantModel:GetAllIngredientIds()
    local list = {}
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantIngredient)
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end
--endregion------------------食材 finish------------------



--region   ------------------食物配置 start-------------------

--- 食材配置
---@param productId number 食物id
---@return XTableRestaurantFood
--------------------------
function XRestaurantModel:GetFoodTemplate(productId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantFood, productId)
end

function XRestaurantModel:GetAllFoodIds()
    local list = {}
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantFood)
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end

--- 根据itemId获取食物
---@param itemId number
---@return XTableRestaurantFood
--------------------------
function XRestaurantModel:GetFoodTemplateByItemId(itemId)
    ---@type table<number, XTableRestaurantFood>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantFood)
    for _, template in pairs(templates) do
        --只有非默认解锁才能获取
        if not template.IsDefault then
            for _, id in ipairs(template.UnlockItemIds) do
                if id == itemId then
                    return template
                end
            end
        end
    end
end

--- 食物基础生产时间
---@param productId number 食物id
---@return number
--------------------------
function XRestaurantModel:GetFoodBaseProduceSpeed(productId)
    local template = self:GetFoodTemplate(productId)
    return template and template.ProduceNeedTime or 0
end

--- 食物基础出售时间
---@param productId number 食物id
---@return number
--------------------------
function XRestaurantModel:GetFoodBaseSellSpeed(productId)
    local template = self:GetFoodTemplate(productId)
    return template and template.SaleNeedTime or 0
end

--- 食物基础出售价格
---@param productId number 食物id
---@return number
--------------------------
function XRestaurantModel:GetFoodBaseSellPrice(productId)
    local template = self:GetFoodTemplate(productId)
    return template and template.Price or 0
end

--- 食物品质
---@param productId number 食物id
---@return number
--------------------------
function XRestaurantModel:GetFoodQuality(productId)
    local template = self:GetFoodTemplate(productId)
    return template and template.Quality or 0
end

--- 食物图标
---@param productId number 食物id
---@return string
--------------------------
function XRestaurantModel:GetFoodIcon(productId)
    local template = self:GetFoodTemplate(productId)
    return template and template.Icon or ""
end

--- 食物的品质图
---@param quality number 品质等级
---@param is3d boolean 是否在3D界面展示
---@return string
--------------------------
function XRestaurantModel:GetFoodQualityIcon(quality, is3d)
    local key = is3d and "FoodQualityIcon3DUI" or "FoodQualityIcon2DUI"
    return self:GetClientConfigValue(key, quality)
end

--endregion------------------食物配置 finish------------------



--region   ------------------热销配置 start-------------------

--- 获取每日热销，每天只会更新一次，所以将数据缓存起来，不用存整张表
---@param day number
---@return table<number, number>
--------------------------
function XRestaurantModel:GetHotSaleDataDict(day)
    if self._HotSaleDict[day] then
        return self._HotSaleDict[day]
    end
    local dict = {}
    ---@type XTableRestaurantDailyHotSale
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantDailyHotSale, day)
    if not XTool.IsTableEmpty(template.FoodList) then
        for index, productId in ipairs(template.FoodList) do
            dict[productId] = template.SaleAddition[index] or 0
        end
    end
    self._HotSaleDict[day] = dict

    return dict
end
--endregion------------------热销配置 finish------------------



--region   ------------------区域Buff start-------------------

---@return XTableRestaurantBuffEffect
function XRestaurantModel:GetBuffEffectTemplate(effectId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantBuffEffect, effectId)
end

---@return XTableRestaurantSectionBuff
function XRestaurantModel:GetSectionBuffTemplate(buffId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantSectionBuff, buffId)
end

function XRestaurantModel:GetAllBuffIds()
    if self._AllBuffIds then
        return self._AllBuffIds
    end
    local list = {}
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantSectionBuff)
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    self._AllBuffIds = list

    return list
end

function XRestaurantModel:GetBuffAreaType(buffId)
    local template = self:GetSectionBuffTemplate(buffId)
    return template and template.SectionType or XMVCA.XRestaurant.AreaType.None
end

function XRestaurantModel:GetBuffIdList(areaType)
    if self._AreaBuffIds and self._AreaBuffIds[areaType] then
        return self._AreaBuffIds[areaType]
    end
    if not self._AreaBuffIds then
        self._AreaBuffIds = {}
    end
    local list = {}
    ---@type table<number, XTableRestaurantSectionBuff>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantSectionBuff)
    for id, template in pairs(templates) do
        if template.SectionType == areaType then
            table.insert(list, id)
        end
    end
    self._AreaBuffIds[areaType] = list

    return list
end

--- 获取一个区域Buff解锁的最低的等级
---@param areaType number
---@return number
--------------------------
function XRestaurantModel:GetMinLevelAreaTypeBuff(areaType)
    if not self._MinLevelAreaTypeBuff then
        self._MinLevelAreaTypeBuff = {}
    end
    if self._MinLevelAreaTypeBuff[areaType] then
        return self._MinLevelAreaTypeBuff[areaType]
    end
    self._MinLevelAreaTypeBuff = {}
    ---@type XTableRestaurantSectionBuff[]
    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantSectionBuff)
    local maxLevel = XMVCA.XRestaurant.RestLevelRange.Max
    for _, template in pairs(templates) do
        if template.IsDefault == 1 then
            local curLevel = self._MinLevelAreaTypeBuff[template.SectionType] or maxLevel
            self._MinLevelAreaTypeBuff[template.SectionType] = math.min(template.UnlockLv, curLevel)
        end
    end
    return self._MinLevelAreaTypeBuff[areaType]
end
--endregion------------------区域Buff finish------------------



--region   ------------------仓库配置 start-------------------

--- 仓库配置
---@param areaType number
---@param restaurantLv number
---@param productId number
---@return XTableRestaurantStorage
--------------------------
function XRestaurantModel:GetStorageTemplate(areaType, restaurantLv, productId)
    if XTool.IsTableEmpty(self._StorageAreaTypeTemplate) then
        ---@type table<number, XTableRestaurantStorage>
        local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantStorage)
        for _, template in pairs(templates) do
            if not self._StorageAreaTypeTemplate[template.SectionType] then
                self._StorageAreaTypeTemplate[template.SectionType] = {}
            end
            if not self._StorageAreaTypeTemplate[template.SectionType][template.RestaurantLv] then
                self._StorageAreaTypeTemplate[template.SectionType][template.RestaurantLv] = {}
            end
            self._StorageAreaTypeTemplate[template.SectionType][template.RestaurantLv][template.ProductId] = template
        end
    end
    if not self._StorageAreaTypeTemplate[areaType] then
        XLog.Error("仓库不存在区域类型: " .. tostring(areaType) .. "的配置，请检查!!!")
        return
    end

    if not self._StorageAreaTypeTemplate[areaType][restaurantLv] then
        XLog.Error("仓库区域类型: " .. tostring(areaType) .. "不存在对应餐厅等级:"
                .. tostring(restaurantLv) .. "的配置，请检查!!!")
        return
    end

    return self._StorageAreaTypeTemplate[areaType][restaurantLv][productId]
end

--endregion------------------仓库配置 finish------------------



--region   ------------------角色模型 start-------------------

function XRestaurantModel:GetCustomerIds()
    local list = {}

    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantCustomer)
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end

---@return XTableRestaurantNpc
function XRestaurantModel:GetModelNpcTemplate(npcId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantNpc, npcId)
end

function XRestaurantModel:GetNpcModelUrl(npcId)
    local template = self:GetModelNpcTemplate(npcId)
    return template and template.ModelUrl or ""
end

function XRestaurantModel:GetNpcControllerUrl(npcId)
    local template = self:GetModelNpcTemplate(npcId)
    return template and template.ControllerUrl or ""
end

function XRestaurantModel:GetNpcName(npcId)
    local template = self:GetModelNpcTemplate(npcId)
    return template and template.Name or ""
end

---@return XTableRestaurantCustomer
function XRestaurantModel:GetCustomerTemplate(customerId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantCustomer, customerId)
end

function XRestaurantModel:GetCustomerTextList(customerId)
    local template = self:GetCustomerTemplate(customerId)
    if not template then
        return {}
    end
    return self:GetDialogTextList(template.DialogId)
end

function XRestaurantModel:GetCustomerNpcId(customerId)
    local template = self:GetCustomerTemplate(customerId)
    return template and template.NpcId or 0
end

---@return XTableRestaurantCharacterModel
function XRestaurantModel:GetCharacterModelTemplate(charId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantCharacterModel, charId)
end

---@return string[]
function XRestaurantModel:GetCharacterTextList(charId, areaType)
    local template = self:GetCharacterTemplate(charId)
    if not template then
        return {}
    end
    local dialogId = template.DialogIds[areaType]
    return self:GetDialogTextList(dialogId)
end

---@return XTableRestaurantSignModel
function XRestaurantModel:GetSignModelTemplate(signDay)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantSignModel, signDay)
end

---@return XTableRestaurantOrderModel
function XRestaurantModel:GetOrderModelTemplate(orderId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantOrderModel, orderId)
end

--endregion------------------角色模型 finish------------------



--region   ------------------客户端配置 start-------------------

---@return XTableRestaurantClientConfig
function XRestaurantModel:GetClientConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantClientConfig, key)
end

---@return string
function XRestaurantModel:GetClientConfigValue(key, index)
    local template = self:GetClientConfig(key)
    if not template then
        return
    end
    return template.Values[index]
end

function XRestaurantModel:GetEffectUrl(effectId)
    ---@type XTableRestaurantEffect
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantEffect, effectId)
    if not template then
        return ""
    end
    return template.PrefabUrl
end

---@return string[]
function XRestaurantModel:GetDialogTextList(dialogId)
    ---@type XTableRestaurantDialog
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantDialog, dialogId)
    if not template then
        return
    end
    return template.Text
end

---@return XTableRestaurantTalk
function XRestaurantModel:GetTalkTemplate(talkId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantTalk, talkId)
end

function XRestaurantModel:GetTalkStoryTalkIds(storyId)
    ---@type XTableRestaurantStory
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantStory, storyId)
    return template and template.TalkIds or {}
end

function XRestaurantModel:GetTalkStoryDurations(storyId)
    ---@type XTableRestaurantStory
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantStory, storyId)
    return template and template.Duration or {}
end

function XRestaurantModel:GetStoryNote(storyId)
    ---@type XTableRestaurantStory
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantStory, storyId)
    return template and template.Note or ""
end

--- 获取工作台位置信息
---@param areaType number
---@param index number 工作台下标
---@return table
--------------------------
function XRestaurantModel:GetWorkbenchPosInfo(areaType, index)
    if not self._WorkbenchPosInfo then
        self._WorkbenchPosInfo = {}
        ---@type table<number, XTableRestaurantWorkPos>
        local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantWorkPos)
        for _, template in pairs(templates) do
            if not self._WorkbenchPosInfo[template.Type] then
                self._WorkbenchPosInfo[template.Type] = {}
            end
            self._WorkbenchPosInfo[template.Type][template.Index] = {
                WorkPosition = XMVCA.XRestaurant:StrPos2Vector3(template.Pos),
                IconOffset = XMVCA.XRestaurant:StrPos2Vector3(template.IconOffset),
            }
        end
    end

    local dict = self._WorkbenchPosInfo[areaType]
    if not dict then
        return {
            WorkPosition = Vector3.zero,
            IconOffset = Vector3.zero,
        }
    end

    return dict[index] or {
        WorkPosition = Vector3.zero,
        IconOffset = Vector3.zero,
    }
end

--- 库存描述
---@param index number 描述的下标
---@return string
--------------------------
function XRestaurantModel:GetStorageCountText(index)
    return self:GetClientConfigValue("StorageCountDesc", index)
end

function XRestaurantModel:GetAccelerateTip(index)
    return self:GetClientConfigValue("AccelerateTip", index)
end

function XRestaurantModel:GetBoardCastTip(index)
    return self:GetClientConfigValue("BoardCastTips", index)
end

---@return XTableRestaurantCameraAuxiliary
function XRestaurantModel:GetCameraAuxiliaryTemplate(areaType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantCameraAuxiliary, areaType)
end

function XRestaurantModel:GetAreaTypeName(areaType)
    local template = self:GetCameraAuxiliaryTemplate(areaType)
    if not template then
        return ""
    end
    return template.Name
end

function XRestaurantModel:GetCameraAuxiliaryCenterPos(areaType)
    local template = self:GetCameraAuxiliaryTemplate(areaType)
    return template.CenterPos or "0|0|0"
end

function XRestaurantModel:GetCameraAuxiliaryMinPos(areaType)
    local template = self:GetCameraAuxiliaryTemplate(areaType)
    return template.MinPos or "0|0|0"
end

function XRestaurantModel:GetCameraAuxiliaryMaxPos(areaType)
    local template = self:GetCameraAuxiliaryTemplate(areaType)
    return template.MaxPos or "0|0|0"
end

function XRestaurantModel:GetAreaTypeTitleIcon(areaType)
    local template = self:GetCameraAuxiliaryTemplate(areaType)
    return template and template.TitleIcon or ""
end

function XRestaurantModel:GetCameraProperty()
    local template = self:GetClientConfig("CameraProperty")
    local minX = tonumber(template.Values[1])
    local maxX = tonumber(template.Values[2])
    local speed = tonumber(template.Values[3])
    local euler = XMVCA.XRestaurant:StrPos2Vector3(template.Values[4])
    local duration = tonumber(template.Values[5])
    local inFov = tonumber(template.Values[6])
    local outFov = tonumber(template.Values[8])
    local moveMinimumX = tonumber(template.Values[7])
    local outEuler = XMVCA.XRestaurant:StrPos2Vector3(template.Values[9])

    return minX, maxX, speed, euler, duration, inFov, outFov, moveMinimumX, outEuler
end

function XRestaurantModel:GetCameraPhotoProperty()
    local template = self:GetClientConfig("CameraPhotoProperty")
    local moveSpeed = tonumber(template.Values[1])
    local zoomSpeed = tonumber(template.Values[2])
    return moveSpeed, zoomSpeed
end

function XRestaurantModel:GetCustomerProperty()
    local template = self:GetClientConfig("CustomerProperty")

    return tonumber(template.Values[1]), tonumber(template.Values[2])
end

function XRestaurantModel:GetGlobalIllumination(level)
    if not level then
        level = self:GetRestaurantLv()
    end
    local template = self:GetClientConfig("GlobalIlluminationPath")
    local paths = template.Values
    local count = #paths
    local index = math.min(level, count)
    return paths[index]
end

function XRestaurantModel:GetSignNpcBehaviourId(state)
    return self:GetClientConfigValue("SignNpcBehaviourId", state)
end

function XRestaurantModel:CheckGuideAllFinish()
    for _, guideId in ipairs(GuideGroupIds) do
        if not XDataCenter.GuideManager.CheckIsGuide(guideId) then
            return false
        end
    end
    return true
end

function XRestaurantModel:GetEnterAreaType()
    if not self:IsOpen() then
        return XMVCA.XRestaurant.AreaType.SaleArea
    end

    if self:CheckGuideAllFinish() then
        return XMVCA.XRestaurant.AreaType.SaleArea
    end
    return XMVCA.XRestaurant.AreaType.FoodArea
end

function XRestaurantModel:GetMenuTabList()
    if self._TabMenuList then
        return self._TabMenuList
    end

    local templates = self._ConfigUtil:GetByTableKey(TableKey.RestaurantIllustrated)
    local list = {}
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    table.sort(list, function(a, b)
        return a < b
    end)

    self._TabMenuList = list
    return list
end

---@return XTableRestaurantIllustrated
function XRestaurantModel:GetMenuTabTemplate(tabId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantIllustrated, tabId)
end

--endregion------------------客户端配置 finish------------------



--region   ------------------演出配置 start-------------------

function XRestaurantModel:CheckPerformFinish(performId)
    local performData = self:GetPerformData(performId)
    if performData:IsFinish() then
        return true
    end
    if performData:IsNotStart() then
        return false
    end
    local template = self:GetPerformTemplate(performId)
    local taskIds = template.TaskIds
    if XTool.IsTableEmpty(taskIds) then
        return true
    end
    for _, taskId in ipairs(taskIds) do
        if not self:CheckPerformTaskFinish(performId, taskId) then
            return false
        end
    end
    return true
end

function XRestaurantModel:CheckPerformTaskFinish(performId, taskId)
    local performData = self:GetPerformData(performId)
    local taskData = performData:GetTaskInfo(taskId)
    if not taskData then
        return false
    end
    local template = self:GetPerformTaskTemplate(taskId)
    local conditions = template.Conditions
    if XTool.IsTableEmpty(conditions) then
        return true
    end
    local finish = true
    for _, conditionId in ipairs(conditions) do
        if not self:CheckCondition(conditionId, taskData:GetScheduleValue(conditionId)) then
            finish = false
            break
        end
    end

    return finish
end

function XRestaurantModel:CheckCondition(id, conditionValue, ...)
    if not self._Condition then
        self._Condition = require("XModule/XRestaurant/XSubControl/XRestaurantCondition").New(self)
    end
    return self._Condition:CheckCondition(id, conditionValue, ...)
end

---@return XTableRestaurantPerform
function XRestaurantModel:GetPerformTemplate(performId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantPerform, performId)
end

---@return XTableRestaurantPerformer
function XRestaurantModel:GetPerformerTemplate(performerId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantPerformer, performerId)
end

function XRestaurantModel:GetPerformerNpcId(performerId)
    local template = self:GetPerformerTemplate(performerId)
    return template and template.NpcId or 0
end

function XRestaurantModel:GetAllPerformIds()
    if self._AllPerformIds then
        return self._AllPerformIds
    end
    self:InitPerformIds()
    return self._AllPerformIds
end

---@return XTableRestaurantPerformTask
function XRestaurantModel:GetPerformTaskTemplate(taskId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantPerformTask, taskId)
end

function XRestaurantModel:GetPerformBehaviourId(performId, state)
    local template = self:GetPerformTemplate(performId)
    if not template then
        return
    end
    return template.BehaviourIds[state]
end

---@return XTableRestaurantPhotoElement
function XRestaurantModel:GetPhotoElementTemplate(propId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantPhotoElement, propId)
end

function XRestaurantModel:GetIndentFoodInfo(performId)
    if self._IndentFoodInfo and self._IndentFoodInfo.IndentId == performId then
        return self._IndentFoodInfo.Infos
    end

    local info = {
        IndentId = performId,
        Infos = {}
    }
    local template = self:GetPerformTemplate(performId)
    if not XTool.IsTableEmpty(template.TaskIds) then
        for _, taskId in ipairs(template.TaskIds) do
            local taskTemplate = self:GetPerformTaskTemplate(taskId)
            for _, conditionId in ipairs(taskTemplate.Conditions) do
                local condition = self:GetConditionTemplate(conditionId)
                if XMVCA.XRestaurant:IsIndentCondition(condition.Type) then
                    table.insert(info.Infos, {
                        Id = condition.Params[1],
                        Count = condition.Params[2],
                        CharacterId = condition.Params[3]
                    })
                end
            end
        end
    end

    self._IndentFoodInfo = info

    return info.Infos
end

function XRestaurantModel:GetRunningPerformData()
    return self:GetBusinessData():GetRunningPerform()
end

function XRestaurantModel:GetRunningIndentData()
    return self:GetBusinessData():GetRunningIndent()
end

function XRestaurantModel:GetUnlockIndentCount()
    return self.BusinessData:GetUnlockIndentCount()
end

function XRestaurantModel:GetUnlockPerformCount()
    return self.BusinessData:GetUnlockPerformCount()
end

--endregion------------------演出配置 finish------------------



--region   ------------------工具接口 start-------------------
function XRestaurantModel:GetCookiesKey(key)
    return string.format("RESTAURANT_LEVEL_ID_%s_UID_%s_%s", self._ActivityId, XPlayer.Id, key)
end

---@return XTableRestaurantCondition
function XRestaurantModel:GetConditionTemplate(conditionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RestaurantCondition, conditionId)
end

function XRestaurantModel:GetConditionType(conditionId)
    local template = self:GetConditionTemplate(conditionId)
    return template and template.Type or 0
end

function XRestaurantModel:GetConditionParams(conditionId)
    local template = self:GetConditionTemplate(conditionId)
    return template and template.Params or {}
end

--- 故事对话Id重复检测
---@param templates table<number, XTableRestaurantStory>
--------------------------
function XRestaurantModel:CheckStoryTalkRepeat(templates)
    local dict = {}
    for id, template in pairs(templates) do
        for index, talkId in ipairs(template.TalkIds) do
            if dict[talkId] then
                local log = string.format("对话内容重复, StoryId = %s, TalkId = %s, 下标 = %s", id, talkId, index)
                XLog.Error(log)
            end
            dict[talkId] = true
        end
    end
end

--endregion------------------工具接口 finish------------------

return XRestaurantModel