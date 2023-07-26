XRestaurantConfigs = XRestaurantConfigs or {}

---@class XRestaurantConfigs.WorkState 工作状态
---@field Free number 空闲状态
---@field Working number 工作中状态
---@field Pause number 工作暂停状态
XRestaurantConfigs.WorkState = {
    Free = 1,
    Working = 2,
    Pause = 3,
}

---@class XRestaurantConfigs.StaffLevel 员工等级
---@field Low number 低级
---@field Medium number 中级
---@field High number 高级
XRestaurantConfigs.StaffLevel = {
    Low = 1,
    Medium = 2,
    High = 3,
    Max = 3,
}

---@class XRestaurantConfigs.AreaType 区域类型
---@field IngredientArea number 备菜
---@field FoodArea number 做菜
---@field SaleArea number 售卖
XRestaurantConfigs.AreaType = {
    IngredientArea = 1,
    FoodArea = 2,
    SaleArea = 3
}

---@class XRestaurantConfigs.ItemId 道具
---@field RestaurantUpgradeCoin number 升级货币
---@field RestaurantShopCoin number 商店货币
---@field RestaurantAccelerate number 加速道具
XRestaurantConfigs.ItemId = {
    RestaurantUpgradeCoin = 63407,
    RestaurantShopCoin = 63408,
    RestaurantAccelerate = 63409,
}

--- 餐厅等级范围
XRestaurantConfigs.LevelRange = {
    Min = 1,
    Max = 7
}

--- 无效值
XRestaurantConfigs.InvalidValue = -1

--- float 消除误差
XRestaurantConfigs.Inaccurate = 0.0000001

--- 时间单位
XRestaurantConfigs.TimeUnit = {
    Second = 1,
    Minute = 60,
    Hour = 3600
}

--- 保留小数位数
XRestaurantConfigs.Digital = {
    One = 1,
    Two = 2,
}

--- 餐厅升级效果类型
XRestaurantConfigs.EffectType = {
    IngredientCount = 1,
    FoodCount = 2,
    SaleCount = 3,
    CharacterLimit = 4,
    CashierLimit = 5,
    HotSaleAddition = 6,
}

--- 订单状态
XRestaurantConfigs.OrderState = {
    NotStart = 0,
    OnGoing  = 1,
    Finish   = 2,
}

--- 签到状态
XRestaurantConfigs.SignState = {
    Incomplete = 1, --签到未完成
    Complete   = 2, --签到已完成
}

XRestaurantConfigs.MenuTabType = {
    Food    = 1, --菜谱
    Message = 2, --留言
}

--任务类型
XRestaurantConfigs.TaskType = {
    Daily       = 1, --每日任务
    Recipe      = 2, --食谱任务
    Activity    = 3, --活动任务
}

XRestaurantConfigs.BuryingButton = {
    BtnShop = 1,
    BtnTask = 2,
    BtnMenu = 3,
    BtnGo = 4,
    BtnHot = 5,
    BtnStatistics = 6,
}

local STR_MINUTE = CS.XTextManager.GetText("Minute")
local STR_SECOND = CS.XTextManager.GetText("Second")

-- 餐厅的引导Id
XRestaurantConfigs.GuideGroupIds = { 61320, 61321, 61322 }

--region   ------------------Path start-------------------
local TABLE_RESTAURANT_ACTIVITY_PATH = "Share/Restaurant/RestaurantActivity.tab"
local TABLE_RESTAURANT_CHARACTER_PATH = "Share/Restaurant/RestaurantCharacter.tab"
local TABLE_RESTAURANT_CHARACTER_LV_PATH = "Share/Restaurant/RestaurantCharacterLv.tab"
local TABLE_RESTAURANT_CHARACTER_SKILL_PATH = "Share/Restaurant/RestaurantCharacterSkill.tab"
local TABLE_RESTAURANT_CONFIG_PATH = "Share/Restaurant/RestaurantConfig.tab"
local TABLE_RESTAURANT_DAILY_HOT_SALE_PATH = "Share/Restaurant/RestaurantDailyHotSale.tab"
local TABLE_RESTAURANT_FOOD_PATH = "Share/Restaurant/RestaurantFood.tab"
local TABLE_RESTAURANT_INGREDIENT_PATH = "Share/Restaurant/RestaurantIngredient.tab"
local TABLE_RESTAURANT_LV_PATH = "Share/Restaurant/RestaurantLv.tab"
local TABLE_RESTAURANT_STORAGE_PATH = "Share/Restaurant/RestaurantStorage.tab"
local TABLE_SIGN_ACTIVITY_PATH = "Share/Restaurant/SignActivity.tab"
local TABLE_SIGN_AWARD_PATH = "Share/Restaurant/SignAward.tab"
local TABLE_ORDER_ACTIVITY = "Share/Restaurant/OrderActivity.tab"
local TABLE_RESTAURANT_ORDER = "Share/Restaurant/RestaurantOrder.tab"
local TABLE_AREA_TYPE_BUFF_PATH = "Share/Restaurant/RestaurantSectionBuff.tab"
local TABLE_BUFF_EFFECT_PATH = "Share/Restaurant/RestaurantBuffEffect.tab"

local TABLE_CAMERA_AUXILIARY_PATH = "Client/Restaurant/RestaurantCameraAuxiliary.tab"
local TABLE_CLIENT_CONFIG_PATH = "Client/Restaurant/RestaurantClientConfig.tab"
local TABLE_CHARACTER_MODEL_PATH = "Client/Restaurant/RestaurantCharacterModel.tab"
local TABLE_SIGN_MODEL_PATH = "Client/Restaurant/RestaurantSignModel.tab"
local TABLE_WORK_POS_PATH = "Client/Restaurant/RestaurantWorkPos.tab"
local TABLE_SKILL_TYPE_PATH = "Client/Restaurant/RestaurantSkillType.tab"
local TABLE_BUBBLE_TEXT_PATH = "Client/Restaurant/RestaurantCharacterText.tab"
local TABLE_ORDER_MODEL_PATH = "Client/Restaurant/RestaurantOrderModel.tab"
local TABLE_NPC_CUSTOMER_PATH = "Client/Restaurant/RestaurantNPCCustomer.tab"
local TABLE_NPC_CUSTOMER_TEXT_PATH = "Client/Restaurant/RestaurantNPCCustomerText.tab"
local TABLE_ILLUSTRATED_PATH = "Client/Restaurant/RestaurantIllustrated.tab"
--endregion------------------Path finish------------------

--region   ------------------Data start-------------------
---@type table<number, XTableRestaurantActivity>
local TableActivity
---@type table<number, XTableRestaurantCharacter>
local TableCharacter
---@type table<number, XTableRestaurantCharacterLv>
local TableCharacterLevel
---@type table<number, XTableRestaurantCharacterSkill>
local TableCharacterSkill
---@type table<number, XTableRestaurantConfig>
local TableConfig
---@type table<number, XTableRestaurantDailyHotSale>
local TableDailyHotSale
---@type table<number, XTableRestaurantFood>
local TableFood
---@type table<number, XTableRestaurantIngredient>
local TableIngredient
---@type table<number, XTableRestaurantLv>
local TableRestaurantLv
---@type table<number, XTableRestaurantStorage>
local TableRestaurantStorage
---@type table<number, XTableSignActivity>
local TableSignActivity
---@type table<number, XTableSignAward>
local TableSignAward
---@type table<number, XTableRestaurantCameraAuxiliary>
local TableCameraAuxiliary
---@type table<string, XTableRestaurantClientConfig>
local TableClientConfig
---@type table<number, XTableRestaurantCharacterModel>
local TableCharacterModel
---@type table<number, XTableRestaurantSignModel>
local TableSignModel
---@type table<number, XTableRestaurantWorkPos>
local TableWorkPos
---@type table<number, XTableOrderActivity>
local TableOrderActivity
---@type table<number, XTableRestaurantOrder>
local TableRestaurantOrder
---@type table<number, XTableRestaurantOrderModel>
local TableOrderNpcModel
---@type table<number, XTableRestaurantNPCCustomer>
local TableNpcCustomer
---@type table<number, XTableRestaurantNPCCustomerText>
local TableNpcCustomerText
---@type table<number, XTableRestaurantIllustrated>
local TableIllustrated
---@type table<number, XTableRestaurantSectionBuff>
local TableAreaTypeBuff
---@type table<number, XTableRestaurantBuffEffect>
local TableBuffEffect

local TableSkillType
local TableBubbleText

local RandomStay = { Min = 2, Max = 5 }         -- 角色随机停留时间（s）
--local RandomBubble = { Min = 40, Max = 120 }    -- 角色随机对话气泡时间（s）

--可能会频繁GC的部分存起来
local CharacterEffectData
local WorkBenchData
--endregion------------------Data finish------------------

local CompareNumber = function(numberA, numberB)
    return numberA < numberB
end

function XRestaurantConfigs.Init()
    -- 活动总控
    TableActivity = XTableManager.ReadByIntKey(TABLE_RESTAURANT_ACTIVITY_PATH, XTable.XTableRestaurantActivity, "Id")
    -- 员工表
    TableCharacter = XTableManager.ReadByIntKey(TABLE_RESTAURANT_CHARACTER_PATH, XTable.XTableRestaurantCharacter, "Id")
    -- 员工等级表
    TableCharacterLevel = XTableManager.ReadByIntKey(TABLE_RESTAURANT_CHARACTER_LV_PATH, XTable.XTableRestaurantCharacterLv, "Id")
    -- 员工技能表
    TableCharacterSkill = XTableManager.ReadByIntKey(TABLE_RESTAURANT_CHARACTER_SKILL_PATH, XTable.XTableRestaurantCharacterSkill, "Id")
    -- 热卖表
    TableDailyHotSale = XTableManager.ReadByIntKey(TABLE_RESTAURANT_DAILY_HOT_SALE_PATH, XTable.XTableRestaurantDailyHotSale, "DayId")
    -- 食物表
    TableFood = XTableManager.ReadByIntKey(TABLE_RESTAURANT_FOOD_PATH, XTable.XTableRestaurantFood, "Id")
    -- 原料表
    TableIngredient = XTableManager.ReadByIntKey(TABLE_RESTAURANT_INGREDIENT_PATH, XTable.XTableRestaurantIngredient, "Id")
    -- 餐厅等级
    TableRestaurantLv = XTableManager.ReadByIntKey(TABLE_RESTAURANT_LV_PATH, XTable.XTableRestaurantLv, "Lv")
    -- 仓库
    TableRestaurantStorage = XTableManager.ReadByIntKey(TABLE_RESTAURANT_STORAGE_PATH, XTable.XTableRestaurantStorage, "Id")
    -- 签到
    TableSignActivity = XTableManager.ReadByIntKey(TABLE_SIGN_ACTIVITY_PATH, XTable.XTableSignActivity, "Id")
    -- 签到奖励
    TableSignAward = XTableManager.ReadByIntKey(TABLE_SIGN_AWARD_PATH, XTable.XTableSignAward, "Id")
    -- 摄像机辅助
    TableCameraAuxiliary = XTableManager.ReadByIntKey(TABLE_CAMERA_AUXILIARY_PATH, XTable.XTableRestaurantCameraAuxiliary, "Type")
    -- 客户端配置
    TableClientConfig = XTableManager.ReadByStringKey(TABLE_CLIENT_CONFIG_PATH, XTable.XTableRestaurantClientConfig, "Key")
    -- 角色模型/动画表
    TableCharacterModel = XTableManager.ReadByIntKey(TABLE_CHARACTER_MODEL_PATH, XTable.XTableRestaurantCharacterModel, "CharacterId")
    -- 签到展示模型
    TableSignModel = XTableManager.ReadByIntKey(TABLE_SIGN_MODEL_PATH, XTable.XTableRestaurantSignModel, "SignDay")
    --订单活动
    TableOrderActivity = XTableManager.ReadByIntKey(TABLE_ORDER_ACTIVITY, XTable.XTableOrderActivity, "Id")
    --订单任务
    TableRestaurantOrder = XTableManager.ReadByIntKey(TABLE_RESTAURANT_ORDER, XTable.XTableRestaurantOrder, "Id")
    --订单NPC模型
    TableOrderNpcModel = XTableManager.ReadByIntKey(TABLE_ORDER_MODEL_PATH, XTable.XTableRestaurantOrderModel, "Id")
    --工作点
    local workPos = XTableManager.ReadByIntKey(TABLE_WORK_POS_PATH, XTable.XTableRestaurantWorkPos, "Id")
    TableWorkPos = {}
    for _, template in pairs(workPos) do
        local type = template.Type
        TableWorkPos[type] = TableWorkPos[type] or {}
        TableWorkPos[type][template.Index] = template
    end
    --技能类型
    TableSkillType = XTableManager.ReadByIntKey(TABLE_SKILL_TYPE_PATH, XTable.XTableRestaurantSkillType, "Type")
    --双端共享配置
    TableConfig = XTableManager.ReadByIntKey(TABLE_RESTAURANT_CONFIG_PATH, XTable.XTableRestaurantConfig, "Id")
    --冒泡文本
    TableBubbleText = XTableManager.ReadByIntKey(TABLE_BUBBLE_TEXT_PATH, XTable.XTableRestaurantCharacterText, "Id")
    --顾客NPC
    TableNpcCustomer = XTableManager.ReadByIntKey(TABLE_NPC_CUSTOMER_PATH, XTable.XTableRestaurantNPCCustomer, "Id")
    --顾客气泡
    TableNpcCustomerText = XTableManager.ReadByIntKey(TABLE_NPC_CUSTOMER_TEXT_PATH, XTable.XTableRestaurantNPCCustomerText, "Id")
    --图鉴页签
    TableIllustrated = XTableManager.ReadByIntKey(TABLE_ILLUSTRATED_PATH, XTable.XTableRestaurantIllustrated, "Id")
    --Buff信息
    TableAreaTypeBuff = XTableManager.ReadByIntKey(TABLE_AREA_TYPE_BUFF_PATH, XTable.XTableRestaurantSectionBuff, "Id")
    --Buff效果
    TableBuffEffect = XTableManager.ReadByIntKey(TABLE_BUFF_EFFECT_PATH, XTable.XTableRestaurantBuffEffect, "Id")

    XRestaurantConfigs.InitCommon()
end

function XRestaurantConfigs.Clear()
    CharacterEffectData = nil
    WorkBenchData = nil
end

function XRestaurantConfigs.InitCommon()
    local str = XRestaurantConfigs.GetClientConfig("CharacterProperty", 3)
    local values = string.Split(str, "|")
    RandomStay.Min = tonumber(values[1])
    RandomStay.Max = tonumber(values[2])

    --str = XRestaurantConfigs.GetClientConfig("CharacterProperty", 4)
    --values = string.Split(str, "|")
    --RandomBubble.Min = tonumber(values[1])
    --RandomBubble.Max = tonumber(values[2])

    XRestaurantConfigs.BubbleDuration = tonumber(XRestaurantConfigs.GetClientConfig("BubbleProperty", 1))
end

--region   ------------------Activity start-------------------
local GetActivityTemplate = function(activityId)
    local template = TableActivity[activityId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetActivityTemplate",
                "RestaurantActivity", TABLE_RESTAURANT_ACTIVITY_PATH, "Id", tostring(activityId))
        return {}
    end
    return template
end

local GetActivityConfig = function(activityId)
    local template = TableConfig[activityId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetActivityConfig",
                "RestaurantConfig", TABLE_RESTAURANT_CONFIG_PATH, "Id", tostring(activityId))
        return {}
    end
    return template
end

local GetActivityTimeId = function(activityId)
    local template = GetActivityTemplate(activityId)
    return template and template.TimeId or 0
end

local GetActivityShopTimeId = function(activityId)
    local template = GetActivityTemplate(activityId)
    return template and template.ShopTimeId or 0
end

function XRestaurantConfigs.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

function XRestaurantConfigs.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XRestaurantConfigs.CheckActivityInTime(activityId, defaultOpen)
    return XFunctionManager.CheckInTimeByTimeId(GetActivityTimeId(activityId), defaultOpen)
end

function XRestaurantConfigs.GetShopStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityShopTimeId(activityId))
end

function XRestaurantConfigs.GetShopEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityShopTimeId(activityId))
end

function XRestaurantConfigs.CheckShopInTime(activityId, defaultOpen)
    return XFunctionManager.CheckInTimeByTimeId(GetActivityShopTimeId(activityId), defaultOpen)
end

function XRestaurantConfigs.GetActivityName(activityId)
    local template = GetActivityTemplate(activityId)
    return template.Name
end

function XRestaurantConfigs.GetShopId(activityId)
    local template = GetActivityTemplate(activityId)
    return template.ShopId
end

function XRestaurantConfigs.GetActivityOfflineBillTime(activityId)
    local template = GetActivityConfig(activityId)
    return template.OfflineBillTime or 0
end

function XRestaurantConfigs.GetActivityAccelerateUseLimit(activityId)
    local template = GetActivityConfig(activityId)
    return template.AccelerateUseLimit or 0
end

function XRestaurantConfigs.GetActivityAccelerateTime(activityId)
    local template = GetActivityConfig(activityId)
    return template.AccelerateTime or 0
end

function XRestaurantConfigs.GetActivityUrgentTime(activityId)
    local template = GetActivityConfig(activityId)
    return template.UrgentTime or 0

end

function XRestaurantConfigs.GetTimeLimitTaskIds(activityId)
    local template = GetActivityTemplate(activityId)
    return template.TimeLimitTaskIds
end

function XRestaurantConfigs.GetRecipeTaskId(activityId)
    local template = GetActivityTemplate(activityId)
    return template.RecipeTaskId
end

--endregion------------------Activity finish------------------

--region   ------------------Character start-------------------
local CharacterLevelTemplate
local CharacterBubbleTextTemplate
local CharacterSkillTypeLabelIcon
local GetCharacterTemplate = function(characterId)
    local template = TableCharacter[characterId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCharacterTemplate",
                "RestaurantCharacter", TABLE_RESTAURANT_CHARACTER_PATH, "Id", tostring(characterId))
        return {}
    end
    return template
end

local GetCharacterLevelTemplate = function(characterId, level)
    if not CharacterLevelTemplate then
        CharacterLevelTemplate = {}
        for id, template in pairs(TableCharacterLevel) do
            local charId, lv = template.CharacterId, template.Lv
            CharacterLevelTemplate[charId] = CharacterLevelTemplate[charId] or {}
            CharacterLevelTemplate[charId][lv] = id
        end

    end
    local id = CharacterLevelTemplate[characterId][level]
    local template = TableCharacterLevel[id]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCharacterLevelTemplate",
                "RestaurantCharacterLv", TABLE_RESTAURANT_CHARACTER_LV_PATH, "Id", tostring(id))
        return {}
    end

    return template
end

local GetCharacterModelTemplate = function(characterId)
    local template = TableCharacterModel[characterId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCharacterModelTemplate",
                "RestaurantCharacterModel", TABLE_CHARACTER_MODEL_PATH, "CharacterId", tostring(characterId))
        return {}
    end
    return template
end

local GetCharacterSkillTemplate = function(skillId)
    local template = TableCharacterSkill[skillId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCharacterSkillTemplate",
                "RestaurantCharacterSkill", TABLE_RESTAURANT_CHARACTER_SKILL_PATH, "Id", tostring(skillId))
        return {}
    end

    return template
end

local GetCharacterSkillTypeTemplate = function(type)
    local template = TableSkillType[type]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCharacterSkillTypeTemplate",
                "RestaurantSkillType", TABLE_SKILL_TYPE_PATH, "Type", tostring(type))
        return {}
    end
    return template
end

local GetCharacterBubbleTextTemplate = function(characterId, areaType)
    if not CharacterBubbleTextTemplate then
        CharacterBubbleTextTemplate = {}
        for id, template in pairs(TableBubbleText) do
            local charId, workType = template.CharacterId, template.WorkType
            CharacterBubbleTextTemplate[charId] = CharacterBubbleTextTemplate[charId] or {}
            CharacterBubbleTextTemplate[charId][workType] = id
        end
    end
    local id = CharacterBubbleTextTemplate[characterId][areaType]
    local template = TableBubbleText[id]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCharacterBubbleTextTemplate",
                "RestaurantCharacterText", TABLE_BUBBLE_TEXT_PATH, "Id", tostring(id))
        return {}
    end
    return template
end

function XRestaurantConfigs.GetCharacters()
    return TableCharacter
end

--- 是否为免费角色
---@param characterId number 角色id
---@return boolean
--------------------------
function XRestaurantConfigs.IsFreeCharacter(characterId)
    local employData = XRestaurantConfigs.GetCharacterEmployConsume(characterId)
    return XTool.IsTableEmpty(employData)
end

--- 获取角色招募消耗
---@param characterId number 角色id
---@return XConsumeData[]
--------------------------
function XRestaurantConfigs.GetCharacterEmployConsume(characterId)
    ---@type XConsumeData[]
    local consume = {}
    local template = GetCharacterTemplate(characterId)
    for idx, itemId in ipairs(template.EmployNeedItemId or {}) do
        ---@class XConsumeData
        ---@field ItemId number
        ---@field Count number
        local item = {
            ItemId = itemId,
            Count = template.EmployNeedItemCount and template.EmployNeedItemCount[idx] or 0
        }
        table.insert(consume, item)
    end
    return consume
end

function XRestaurantConfigs.GetCharacterName(characterId)
    local template = GetCharacterTemplate(characterId)
    return template.Name
end

function XRestaurantConfigs.GetCharacterPriority(characterId)
    local template = GetCharacterTemplate(characterId)
    return template.Priority or 0
end

--- 当前等级升级到下级所需材料
---@param characterId number 角色id
---@param level number 角色当前等级
---@return XConsumeData[]
--------------------------
function XRestaurantConfigs.GetCharacterLevelUpConsume(characterId, level)
    local template = GetCharacterLevelTemplate(characterId, level)
    local consume = {}
    for idx, itemId in ipairs(template.UpgradeNeedItemId or {}) do
        ---@type XConsumeData
        local item = {
            ItemId = itemId,
            Count = template.UpgradeNeedItemCount and template.UpgradeNeedItemCount[idx] or 0
        }
        table.insert(consume, item)
    end
    return consume
end

function XRestaurantConfigs.GetCharacterSkillIds(characterId, level)
    local template = GetCharacterLevelTemplate(characterId, level)
    return template.SkillId or {}
end

function XRestaurantConfigs.GetCharacterModel(characterId)
    local template = GetCharacterModelTemplate(characterId)
    return template.ModelPath
end

function XRestaurantConfigs.GetCharacterController(characterId)
    local template = GetCharacterModelTemplate(characterId)
    return template.ControllerPath
end

function XRestaurantConfigs.GetCharacterAnimName(characterId, index)
    local template = GetCharacterModelTemplate(characterId)
    local anim = template.Anim or {}
    return anim[index]
end

function XRestaurantConfigs.GetCharacterAnimCount(characterId)
    local template = GetCharacterModelTemplate(characterId)
    local anim = template.Anim or {}
    return #anim
end

function XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
    local template = GetCharacterSkillTemplate(skillId)
    return template.SectionType or XRestaurantConfigs.AreaType.IngredientArea
end

function XRestaurantConfigs.GetCharacterSkillAddition(skillId)
    local template = GetCharacterSkillTemplate(skillId)
    local map = {}
    for idx, productId in ipairs(template.ProductId) do
        local addition = template.SkillAddition[idx] or 0
        map[productId] = addition
    end
    return map
end

function XRestaurantConfigs.GetCharacterSkillAdditionList(skillId)
    local template = GetCharacterSkillTemplate(skillId)
    local list = {}
    for idx, productId in ipairs(template.ProductId) do

        table.insert(list, {
            Id = productId,
            Addition = template.SkillAddition[idx] or 0,
            AreaType = template.SectionType
        })
    end
    
    return list
end

function XRestaurantConfigs.GetCharacterSkillName(skillId)
    local template = GetCharacterSkillTemplate(skillId)
    return template.Name
end

function XRestaurantConfigs.GetCharacterSkillDesc(skillId)
    local template = GetCharacterSkillTemplate(skillId)
    return template.Desc
end

function XRestaurantConfigs.GetCharacterSkillPercentAddition(addition, areaType, productId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local product = viewModel:GetProduct(areaType, productId)
    local percent
    if XRestaurantConfigs.CheckIsSaleArea(areaType) then
        local baseSpeed = product:GetProperty("_SellPrice")
        percent = addition / baseSpeed
    else
        local produceNeedTime = product:GetProperty("_Speed")
        --local baseSpeed = 1 / produceNeedTime
        --local subTime = produceNeedTime - addition
        --if subTime <= 0 then
        --    XLog.Error("配置错误: 工作台制造一个成品时间小于技能加成时间")
        --    return "Error"
        --end
        --local addSpeed = 1 / subTime
        --percent = (addSpeed - baseSpeed) / baseSpeed
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
function XRestaurantConfigs.GetAddCountAndUnit(base, addition, areaType)
    local baseCount, addSpeed, addCount
    if XRestaurantConfigs.CheckIsSaleArea(areaType) then
        baseCount = base
        addSpeed = base + addition
        addCount = addSpeed
    else
        local Hour = XRestaurantConfigs.TimeUnit.Hour
        --保留小数位数
        local Digital = XRestaurantConfigs.Digital.One

        baseCount = XRestaurantConfigs.GetAroundValue(Hour / base, Digital)
        addSpeed = math.max(1, base - addition)
        addCount = XRestaurantConfigs.GetAroundValue(Hour / addSpeed, Digital)
    end

    local add = addCount - baseCount
    return baseCount, add, add > 0 and "+" or ""
end

function XRestaurantConfigs.GetCharacterSkillTypeName(type)
    local template = GetCharacterSkillTypeTemplate(type)
    return template.Name
end

function XRestaurantConfigs.GetCharacterSkillLabelIcon(type, isSmall)
    if not CharacterSkillTypeLabelIcon or not CharacterSkillTypeLabelIcon[type] then
        CharacterSkillTypeLabelIcon = {}
        local template = GetCharacterSkillTypeTemplate(type)
        local icons = string.Split(template.LabelIcon, "|") or {}
        CharacterSkillTypeLabelIcon[type] = {
            Big = icons[1],
            Small = icons[2],
        }
    end
    return isSmall and CharacterSkillTypeLabelIcon[type].Small or CharacterSkillTypeLabelIcon[type].Big
end

function XRestaurantConfigs.GetCharacterLevelStr(level)
    return XRestaurantConfigs.GetClientConfig("StaffLevelDesc", level)
end

function XRestaurantConfigs.GetCharacterLevelLabelIcon(level)
    return XRestaurantConfigs.GetClientConfig("StaffLevelLabelIcon", level)
end

function XRestaurantConfigs.GetCharacterBubbleText(characterId, areaType)
    local template = GetCharacterBubbleTextTemplate(characterId, areaType)
    return template and template.Text or {}
end

--endregion------------------Character finish------------------

--region   ------------------Restaurant start-------------------
local GetRestaurantLevelTemplate = function(level)
    local template = TableRestaurantLv[level]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs->GetRestaurantLevelTemplate",
                "RestaurantLv", TABLE_RESTAURANT_LV_PATH, "Level" .. tostring(level))
        return {}
    end
    return template
end

function XRestaurantConfigs.GetCharacterLimit(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.CharacterLimit or 0
end

function XRestaurantConfigs.GetCashierLimit(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.CashierLimit or 0
end

--- 解锁原材料
---@param level number 餐厅等级
---@return number[]
--------------------------
function XRestaurantConfigs.GetUnlockIngredient(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.UnlockIngredient or {}
end

--- 解锁菜谱
---@param level number 餐厅等级
---@return number[]
--------------------------
function XRestaurantConfigs.GetUnlockFood(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.UnlockFood or {}
end

function XRestaurantConfigs.GetIngredientCounterNum(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.IngredientCounterNum or 0
end

function XRestaurantConfigs.GetFoodCounterNum(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.FoodCounterNum or 0
end

function XRestaurantConfigs.GetSaleCounterNum(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.SaleCounterNum or 0
end

function XRestaurantConfigs.GetCounterNumByAreaType(areaType, level)
    if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
        return XRestaurantConfigs.GetIngredientCounterNum(level)
    elseif XRestaurantConfigs.CheckIsFoodArea(areaType) then
        return XRestaurantConfigs.GetFoodCounterNum(level)
    elseif XRestaurantConfigs.CheckIsSaleArea(areaType) then
        return XRestaurantConfigs.GetSaleCounterNum(level)
    end
    return 0
end

function XRestaurantConfigs.GetRestaurantScenePrefab(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.ScenePrefab or 0
end

function XRestaurantConfigs.GetRestaurantTitleIcon(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.TitleIcon or 0
end

function XRestaurantConfigs.GetRestaurantDecorationIcon(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.DecorationIcon or 0
end

--- 获取餐厅升级条件
---@param level number 餐厅等级
---@return XRestaurantUpgradeCondition
--------------------------
function XRestaurantConfigs.GetUpgradeCondition(level)
    if not XTool.IsNumberValid(level) then
        return {}
    end
    local template = GetRestaurantLevelTemplate(level)
    local itemIds = template.UpgradeNeedItemId or {}
    local itemCounts = template.UpgradeNeedItemCount or {}
    ---@class XRestaurantUpgradeCondition
    ---@field TotalStaffNumber number 员工总数
    ---@field SeniorCharacterLv number 需要的员工等级
    ---@field TotalSeniorCharacter number 达到等级的员工数量
    ---@field ConsumeData XConsumeData[] 达到等级的员工数量
    local upgradeCondition = {
        TotalStaffNumber = template.UpgradeNeedCharacterNum,
        SeniorCharacterLv = template.UpgradeNeedSeniorCharacterLv,
        TotalSeniorCharacter = template.UpgradeNeedSeniorCharacterNum,
        ConsumeData = {}
    }
    local list = {}
    for idx, itemId in ipairs(itemIds) do
        ---@type XConsumeData
        local item = {
            ItemId = itemId,
            Count = itemCounts[idx] or 0
        }
        table.insert(list, item)
    end
    upgradeCondition.ConsumeData = list

    return upgradeCondition
end

function XRestaurantConfigs.GetRestaurantUnlockEffectList(targetLevel)
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
    func(XRestaurantConfigs.EffectType.IngredientCount, XRestaurantConfigs.GetIngredientCounterNum)
    func(XRestaurantConfigs.EffectType.FoodCount, XRestaurantConfigs.GetFoodCounterNum)
    func(XRestaurantConfigs.EffectType.SaleCount, XRestaurantConfigs.GetSaleCounterNum)
    func(XRestaurantConfigs.EffectType.CharacterLimit, XRestaurantConfigs.GetCharacterLimit)
    func(XRestaurantConfigs.EffectType.CashierLimit, XRestaurantConfigs.GetCashierLimit)
    func(XRestaurantConfigs.EffectType.HotSaleAddition, XRestaurantConfigs.GetHotSaleAdditionByRestaurantLevel)

    return list
end

function XRestaurantConfigs.GetRestaurantUnlockProductList(areaType, productIds)
    local list = {}
    for _, id in pairs(productIds or {}) do
        table.insert(list, {
            AreaType = areaType,
            Id = id,
        })
    end
    return list
end

--- 升级条件列表
---@param data XRestaurantUpgradeCondition
---@return string[]
--------------------------
function XRestaurantConfigs.GetRestaurantUnlockConditionList(data)
    local list = {}
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel then
        return list
    end

    local staffNumber = data.TotalStaffNumber
    if staffNumber > 0 then
        local text = XRestaurantConfigs.GetClientConfig("RestaurantLvUpConditionText", 1)
        text = string.format(text, staffNumber)
        local staffList = viewModel:GetRecruitStaffList()
        local finish = #staffList >= staffNumber
        table.insert(list, {
            Text = text,
            Finish = finish,
            Type = 1,
        })
    end

    local level, count = data.SeniorCharacterLv, data.TotalSeniorCharacter
    if level > 0 and count > 0 then
        local text = XRestaurantConfigs.GetClientConfig("RestaurantLvUpConditionText", 2)
        text = string.format(text, count, XRestaurantConfigs.GetCharacterLevelStr(level))
        local staffList = viewModel:GetStaffListByMinLevel(level)
        local finish = #staffList >= count
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

--- 餐厅等级对热销的加成
---@param level number 餐厅等级
---@return number 加成百分比
--------------------------
function XRestaurantConfigs.GetHotSaleAdditionByRestaurantLevel(level)
    local template = GetRestaurantLevelTemplate(level)
    return template.HotSaleAddition or 0
end

function XRestaurantConfigs.GetCustomerLimit(level)
    local template = GetRestaurantLevelTemplate(level)
    return template and template.CustomerLimit or 0
end

--- 获取当前等级已解锁产品
---@param level number 当前等级
---@param func function 获取解锁Id函数
---@return table<number, number>
--------------------------
function XRestaurantConfigs.GetUnlockProduct(level, func)
    local map = {}
    for lv = XRestaurantConfigs.LevelRange.Min, level do
        local list = func(lv)
        for _, id in pairs(list or {}) do
            map[id] = true
        end
    end
    return map
end

function XRestaurantConfigs.GetHotSaleDataList(day)
    local template = TableDailyHotSale[day]
    if not template then
        return {}
    end
    local list = {}
    for idx, foodId in ipairs(template.FoodList or {}) do
        local addition = template.SaleAddition[idx] or 0
        table.insert(list, {
            Id = foodId,
            Addition = addition
        })
    end

    return list
end
--endregion------------------Restaurant finish------------------

--region   ------------------Food And Ingredient start-------------------
local FoodUnlockItems = {}
local GetFoodTemplate = function(foodId)
    local template = TableFood[foodId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetFoodTemplate",
                "RestaurantFood", TABLE_RESTAURANT_FOOD_PATH, "Id" .. tostring(foodId))
        return {}
    end
    return template
end

local GetIngredientTemplate = function(ingredientId)
    local template = TableIngredient[ingredientId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetIngredientTemplate",
                "RestaurantIngredient", TABLE_RESTAURANT_INGREDIENT_PATH, "Id" .. tostring(ingredientId))
        return {}
    end
    return template
end

function XRestaurantConfigs.GetIngredients()
    return TableIngredient
end

function XRestaurantConfigs.GetFoods()
    return TableFood
end

--如果多次使用，注意缓存
function XRestaurantConfigs.GetFoodIdList()
    local list = {}
    for id in pairs(TableFood) do
        table.insert(list, id)
    end
    table.sort(list, CompareNumber)
    
    return list
end

function XRestaurantConfigs.GetFoodName(foodId)
    local template = GetFoodTemplate(foodId)
    return template.Name
end

function XRestaurantConfigs.GetFoodBasePrice(foodId)
    local template = GetFoodTemplate(foodId)
    return template.Price
end

function XRestaurantConfigs.GetFoodBaseProduceSpeed(foodId)
    local template = GetFoodTemplate(foodId)
    return template.ProduceNeedTime
end

function XRestaurantConfigs.GetFoodBaseSellSpeed(foodId)
    local template = GetFoodTemplate(foodId)
    return template.SaleNeedTime
end

function XRestaurantConfigs.GetFoodIcon(foodId)
    local template = GetFoodTemplate(foodId)
    return template.Icon
end

function XRestaurantConfigs.GetFoodQuality(foodId)
    local template = GetFoodTemplate(foodId)
    return template.Quality
end

function XRestaurantConfigs.GetFoodPriority(foodId)
    local template = GetFoodTemplate(foodId)
    return template.Priority
end

function XRestaurantConfigs.GetFoodIsDefault(foodId)
    local template = GetFoodTemplate(foodId)
    local isDefault = template.IsDefault or 0
    return  isDefault == 1
end

function XRestaurantConfigs.GetFoodUnlockItems(foodId)
    if FoodUnlockItems[foodId] then
        return FoodUnlockItems[foodId]
    end
    
    local template = GetFoodTemplate(foodId)
    local itemIds = template.UnlockItemIds
    local items = {}
    for i, itemId in ipairs(itemIds) do
        table.insert(items, {
            Id = itemId,
            Count = template.UnlockItemCounts[i] or 0
        })
    end

    FoodUnlockItems[foodId] = items
    
    return items
end

function XRestaurantConfigs.GetFoodTemplateByItemId(itemId)
    for _, template in pairs(TableFood) do
        --只有非默认解锁才能获取
        if template.IsDefault == 0 then
            for _, id in ipairs(template.UnlockItemIds) do
                if id == itemId then
                    return template
                end
            end
        end
    end
end

function XRestaurantConfigs.GetFoodQualityIcon(quality, is3d)
    local key = is3d and "FoodQualityIcon3DUI" or "FoodQualityIcon2DUI"
    return XRestaurantConfigs.GetClientConfig(key, quality)
end

function XRestaurantConfigs.GetCommonQualityIcon(is3d)
    local index = is3d and 1 or 2
    return XRestaurantConfigs.GetClientConfig("CommonQualityIconUI", index)
end

--- 获取食物所需食材
---@param foodId number 食物Id
---@return XConsumeData[]
--------------------------
function XRestaurantConfigs.GetIngredientList(foodId)
    local template = GetFoodTemplate(foodId)
    local list = {}
    for idx, ingredientId in ipairs(template.ConsumeIngredientIds or {}) do
        ---@type XConsumeData
        local item = {
            ItemId = ingredientId,
            Count = template.ConsumeIngredientCounts and template.ConsumeIngredientCounts[idx] or 0
        }
        table.insert(list, item)
    end
    return list
end

function XRestaurantConfigs.GetIngredientName(ingredientId)
    local template = GetIngredientTemplate(ingredientId)
    return template.Name
end

function XRestaurantConfigs.GetIngredientIcon(ingredientId)
    local template = GetIngredientTemplate(ingredientId)
    return template.Icon
end

function XRestaurantConfigs.GetIngredientBaseProduceSpeed(ingredientId)
    local template = GetIngredientTemplate(ingredientId)
    return template.ProduceNeedTime
end

function XRestaurantConfigs.GetIngredientPriority(ingredientId)
    local template = GetIngredientTemplate(ingredientId)
    return template.Priority
end
--endregion------------------Food And Ingredient finish------------------

--region   ------------------Storage start-------------------
local RestaurantStorageTemplate

local GetRestaurantStorageTemplate = function(sectionType, restaurantLv, productId)
    if not RestaurantStorageTemplate then
        RestaurantStorageTemplate = {}
        for id, template in pairs(TableRestaurantStorage or {}) do
            RestaurantStorageTemplate[template.SectionType] = RestaurantStorageTemplate[template.SectionType] or {}
            RestaurantStorageTemplate[template.SectionType][template.RestaurantLv] = RestaurantStorageTemplate[template.SectionType][template.RestaurantLv] or {}
            RestaurantStorageTemplate[template.SectionType][template.RestaurantLv][template.ProductId] = id
        end
    end
    local storageId
    if RestaurantStorageTemplate and
            RestaurantStorageTemplate[sectionType] and
            RestaurantStorageTemplate[sectionType][restaurantLv] then
        storageId = RestaurantStorageTemplate[sectionType][restaurantLv][productId]
    end

    if not XTool.IsNumberValid(storageId) then
        XLog.Error("obtain restaurant storage template error: ", "SectionType = " .. sectionType,
                "RestaurantLv = " .. restaurantLv, "ProductId = " .. productId)
        return {}
    end
    return TableRestaurantStorage[storageId]
end

--- 获取产品上限
---@param sectionType XRestaurantConfigs.AreaType 区域类型
---@param restaurantLv number 餐厅等级
---@param productId number 产品Id
---@return number
--------------------------
function XRestaurantConfigs.GetProductLimit(sectionType, restaurantLv, productId)
    local template = GetRestaurantStorageTemplate(sectionType, restaurantLv, productId)
    return template.StorageLimit or 0
end
--endregion------------------Storage finish------------------

--region   ------------------Sign start-------------------
local SignAwardTemplate
local GetSignActivityTemplate = function(activityId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel then
        XLog.Error("活动为开启, 请检查配置!!!")
        return
    end

    if viewModel:GetProperty("_Id") ~= activityId then
        XLog.Error("活动期数不一致，请检查逻辑!!")
        return
    end
    
    local signActivityId = viewModel:GetProperty("_SignActivityId")
    local template = TableSignActivity[signActivityId]
    
    return template
end

local GetSignActivityTimeId = function(activityId)
    local template = GetSignActivityTemplate(activityId)
    return template and template.TimeId or 0
end

local GetSignAwardTemplate = function(signActivityId, day)
    if not SignAwardTemplate then
        SignAwardTemplate = {}
        for id, template in pairs(TableSignAward) do
            if template.SignActivityId == signActivityId then
                SignAwardTemplate[template.DayId] = id
            end
        end
    end
    local id = SignAwardTemplate[day]
    local template = TableSignAward[id]
    if not template then
        return {}
    end
    return template
end

function XRestaurantConfigs.GetSignActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetSignActivityTimeId(activityId))
end

function XRestaurantConfigs.GetSignActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetSignActivityTimeId(activityId))
end

function XRestaurantConfigs.CheckSignActivityInTime(activityId, defaultOpen)
    return XFunctionManager.CheckInTimeByTimeId(GetSignActivityTimeId(activityId), defaultOpen)
end

function XRestaurantConfigs.GetSignActivityName(activityId)
    local template = GetSignActivityTemplate(activityId)
    return template.Name or ""
end

function XRestaurantConfigs.GetSignActivityRewardId(activityId, day)
    local signTemplate = GetSignActivityTemplate(activityId)
    if not signTemplate then
        return 0
    end
    local signActivityId = signTemplate.Id
    local template = GetSignAwardTemplate(signActivityId, day)
    return template.RewardId or 0
end

function XRestaurantConfigs.GetSignActivityNpcImgUrl(activityId, day)
    local signTemplate = GetSignActivityTemplate(activityId)
    if not signTemplate then
        return ""
    end
    local signActivityId = signTemplate.Id
    local template = GetSignAwardTemplate(signActivityId, day)
    return template.NpcImgUrl or ""
end

function XRestaurantConfigs.GetSignActivitySignDesc(activityId, day)
    local signTemplate = GetSignActivityTemplate(activityId)
    if not signTemplate then
        return ""
    end
    local signActivityId = signTemplate.Id
    local template = GetSignAwardTemplate(signActivityId, day)
    return template.SignDesc or ""
end

function XRestaurantConfigs.GetSignActivityReplyBtnDesc(activityId, day)
    local signTemplate = GetSignActivityTemplate(activityId)
    if not signTemplate then
        return ""
    end
    local signActivityId = signTemplate.Id
    local template = GetSignAwardTemplate(signActivityId, day)
    return template.ReplyBtnDesc or ""
end

function XRestaurantConfigs.GetSignActivityNpcModelPath(day)
    local template = TableSignModel[day] or {}
    return template.ModelPath or ""
end

function XRestaurantConfigs.GetSignActivityNpcControllerPath(day)
    local template = TableSignModel[day]
    return template.ControllerPath
end

function XRestaurantConfigs.GetSignActivityNpcAnimations(day)
    local template = TableSignModel[day]
    return template and template.Anim or {}
end
--endregion------------------Sign finish------------------

--region   ------------------Order Activity start-------------------
---@type XTableOrderActivity
local OrderTemplate
local OrderFoodInfo

---@return XTableOrderActivity
local GetOrderActivityTemplate = function(activityId)
    if not OrderTemplate or OrderTemplate.RestaurantActivityId ~= activityId then
        for _, template in pairs(TableOrderActivity) do
            if template.RestaurantActivityId == activityId then
                OrderTemplate = template
                break
            end

            if not OrderTemplate then
                XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetOrderTemplate", 
                        "OrderActivity", TABLE_ORDER_ACTIVITY, "RestaurantActivityId", activityId)
            end
        end
    end
    
    return OrderTemplate or {}
end

---@return XTableRestaurantOrder
local GetOrderInfoTemplate = function(orderId)
    local template = TableRestaurantOrder[orderId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetOrderInfoTemplate", 
                "RestaurantOrder", TABLE_RESTAURANT_ORDER, "Id", orderId)
        return
    end
    
    return template
end

local GetOrderNpcModelTemplate = function(npcId) 
    local template = TableOrderNpcModel[npcId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetOrderNpcModelTemplate",
                "RestaurantOrderModel", TABLE_ORDER_MODEL_PATH, "Id", npcId)
        return
    end
    return template
end

function XRestaurantConfigs.GetOrderNpcId(orderId)
    local template = GetOrderInfoTemplate(orderId)
    return template and template.NpcId or 0
end

function XRestaurantConfigs.GetOrderModel(npcId)
    local template = GetOrderNpcModelTemplate(npcId)
    return template.ModelPath
end

function XRestaurantConfigs.GetOrderModelController(npcId)
    local template = GetOrderNpcModelTemplate(npcId)
    return template.ControllerPath
end

function XRestaurantConfigs.GetOrderNpcAnimationList(npcId)
    local template = GetOrderNpcModelTemplate(npcId)
    return template.Anim
end

function XRestaurantConfigs.GetOrderNpcName(npcId)
    local template = GetOrderNpcModelTemplate(npcId)
    return template.Name
end

function XRestaurantConfigs.GetOrderNpcIcon(npcId)
    local template = GetOrderNpcModelTemplate(npcId)
    return template.Icon
end

function XRestaurantConfigs.GetOrderNpcReplay(npcId)
    local template = GetOrderNpcModelTemplate(npcId)
    if not template then
        return ""
    end
    return XUiHelper.ReplaceTextNewLine(template.RePlay)
end

function XRestaurantConfigs.GetOrderFoodInfos(orderId)
    if OrderFoodInfo and OrderFoodInfo.OrderId == orderId then
        return OrderFoodInfo.Infos
    end
    OrderFoodInfo = {
        OrderId = orderId,
        Infos = {}
    }
    local template = GetOrderInfoTemplate(orderId)
    for i, id in ipairs(template.FoodIds) do
        table.insert(OrderFoodInfo.Infos, {
            Id = id,
            Count = template.FoodNums[i] or 0
        })
    end
    return OrderFoodInfo.Infos
end

function XRestaurantConfigs.GetOrderDesc(orderId)
    local template = GetOrderInfoTemplate(orderId)
    return XUiHelper.ReplaceTextNewLine(template.OrderDesc)
end

function XRestaurantConfigs.GetOrderRewardId(orderId)
    local template = GetOrderInfoTemplate(orderId)
    return template and template.RewardId or 0
end

--endregion------------------Order Activity finish------------------

--region   ------------------Customer start-------------------
local CustomerId2TextId

local GetCustomerModel = function(npcId) 
    local template = TableNpcCustomer[npcId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCustomerModel", 
                "RestaurantNpcCustomer", TABLE_NPC_CUSTOMER_PATH, "Id", tostring(npcId))
        return
    end
    
    return template
end

local GetCustomerText = function(npcId)
    if not CustomerId2TextId then
        CustomerId2TextId = {}
        for id, data in pairs(TableNpcCustomerText) do
            CustomerId2TextId[data.NpcId] = id
        end
    end
    local talkId = CustomerId2TextId[npcId]
    if not XTool.IsNumberValid(talkId) then
        XLog.Error("未找到对应的气泡Id, NpcId = "..tostring(npcId))
        return
    end
    local template = TableNpcCustomerText[talkId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCustomerText",
                "RestaurantNpcCustomerText", TABLE_NPC_CUSTOMER_TEXT_PATH, "Id", tostring(talkId))
        return
    end
    
    return template
end

local GetIllustratedTemplate = function(tabId) 
    local template = TableIllustrated[tabId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetIllustratedTemplate",
                "RestaurantIllustrated", TABLE_ILLUSTRATED_PATH, "Id", tostring(tabId))
        return
    end
    return template
end

function XRestaurantConfigs.GetCustomerModelPath(npcId)
    local template = GetCustomerModel(npcId)
    return template and template.Model or ""
end

function XRestaurantConfigs.GetCustomerModelController(npcId)
    local template = GetCustomerModel(npcId)
    return template and template.ControllerPath or ""
end

function XRestaurantConfigs.GetCustomerTextList(npcId)
    local template = GetCustomerText(npcId)
    return template and template.Text or {}
end

function XRestaurantConfigs.GetCustomerBehaviourId(npcId)
    local template = GetCustomerModel(npcId)
    return template and template.BehaviourId or "Customer_1"
end

function XRestaurantConfigs.GetCustomerNpcIds()
    local list = {}
    for id in pairs(TableNpcCustomer) do
        table.insert(list, id)
    end
    
    return list
end

local TabList
function XRestaurantConfigs.GetMenuTabList()
    if TabList then
        return TabList
    end
    local tab = {}
    for _, data in pairs(TableIllustrated) do
        table.insert(tab, data.Id)
    end
    
    table.sort(tab, CompareNumber)
    TabList = tab
    return tab
end

function XRestaurantConfigs.GetMenuTabName(tabId)
    local template = GetIllustratedTemplate(tabId)
    return template and template.TabName or ""
end

function XRestaurantConfigs.CheckMenuTabInTime(tabId)
    local template = GetIllustratedTemplate(tabId)
    local timeId = template and template.TimeId or 0
    return XFunctionManager.CheckInTimeByTimeId(timeId, true)
end

function XRestaurantConfigs.GetMenuTabUnlockTimeStr(tabId, format)
    local template = GetIllustratedTemplate(tabId)
    local timeId = template and template.TimeId or 0
    local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(timeId)
    return XTime.TimestampToGameDateTimeString(timeOfBgn, format)
end

--endregion------------------Customer finish------------------

--region   ------------------Buff start-------------------
local AreaType2BuffIds = {}
local AreaType2MinLevel = {}

local GetBuffInfo = function(buffId)
    local template = TableAreaTypeBuff[buffId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetBuffInfo",
                "RestaurantSectionBuff", TABLE_AREA_TYPE_BUFF_PATH, "Id", tostring(buffId))
        return {}
    end
    
    return template
end

local GetEffectInfo = function(effectId)
    local template = TableBuffEffect[effectId]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetEffectInfo",
                "RestaurantBuffEffect", TABLE_BUFF_EFFECT_PATH, "Id", tostring(effectId))
        return {}
    end

    return template
end 

function XRestaurantConfigs.GetBuffName(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.Name or ""
end

function XRestaurantConfigs.GetBuffDesc(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.Desc or ""
end

function XRestaurantConfigs.GetBuffAreaType(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.SectionType or 0
end

function XRestaurantConfigs.GetBuffUnlockLv(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.UnlockLv or 0
end

function XRestaurantConfigs.GetBuffEffectIds(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.EffectIds or {}
end

function XRestaurantConfigs.GetBuffEffectAdditions(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.EffectAdditions or {}
end

function XRestaurantConfigs.GetBuffUnlockItems(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.UnlockItemIds or {}
end

function XRestaurantConfigs.GetBuffUnlockItemCounts(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.UnlockItemCounts or {}
end

function XRestaurantConfigs.GetBuffCharacterIds(buffId)
    local template = GetBuffInfo(buffId)
    return template and template.CharacterIds or {}
end

function XRestaurantConfigs.GetBuffIdList(areaType)
    if AreaType2BuffIds[areaType] then
        return AreaType2BuffIds[areaType]
    end
    local list = {}
    for id, template in pairs(TableAreaTypeBuff) do
        if template.SectionType == areaType then
            table.insert(list, id)
        end
    end
    AreaType2BuffIds[areaType] = list
    
    return list
end

--获取区域Buff解锁等级
function XRestaurantConfigs.GetAreaBuffUnlockMinLevel(areaType)
    if AreaType2MinLevel[areaType] then
        return AreaType2MinLevel[areaType]
    end
    local buffIds = XRestaurantConfigs.GetBuffIdList(areaType)
    local minLevel = XRestaurantConfigs.LevelRange.Max
    for _, buffIdId in ipairs(buffIds) do
        local template = GetBuffInfo(buffIdId)
        if template.IsDefault == 1 then
            minLevel = math.min(template.UnlockLv, minLevel)
        end
    end
    AreaType2MinLevel[areaType] = minLevel
    
    return minLevel
end

--增益玩法最低等级
function XRestaurantConfigs.GetBuffUnlockMinLevel()
    local level = XRestaurantConfigs.LevelRange.Max
    for _, areaType in pairs(XRestaurantConfigs.AreaType) do
        level = math.min(level, XRestaurantConfigs.GetAreaBuffUnlockMinLevel(areaType))
    end
    return level
end

function XRestaurantConfigs.GetEffectProductIds(effectId)
    local template = GetEffectInfo(effectId)
    return template and template.ProductIds or {}
end

function XRestaurantConfigs.GetEffectAreaType(effectId)
    local template = GetEffectInfo(effectId)
    return template and template.SectionType or 0
end

--endregion------------------Buff finish------------------

local GetCameraAuxiliaryTemplate = function(type)
    local template = TableCameraAuxiliary[type]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetCameraAuxiliaryTemplate",
                "RestaurantCameraAuxiliary", TABLE_CAMERA_AUXILIARY_PATH, "Type", tostring(type))
        return {}
    end
    return template
end

function XRestaurantConfigs.GetCameraAuxiliaryCenterPos(type)
    local template = GetCameraAuxiliaryTemplate(type)
    return template.CenterPos or "0|0|0"
end

function XRestaurantConfigs.GetCameraAuxiliaryMinPos(type)
    local template = GetCameraAuxiliaryTemplate(type)
    return template.MinPos or "0|0|0"
end

function XRestaurantConfigs.GetCameraAuxiliaryMaxPos(type)
    local template = GetCameraAuxiliaryTemplate(type)
    return template.MaxPos or "0|0|0"
end

function XRestaurantConfigs.GetCameraAuxiliaryAreaName(type)
    local template = GetCameraAuxiliaryTemplate(type)
    return template.Name or ""
end

function XRestaurantConfigs.GetClientConfig(key, index)
    local template = TableClientConfig[key]
    if not template then
        XLog.ErrorTableDataNotFound("XRestaurantConfigs -> GetClientConfig",
                "RestaurantClientConfig", TABLE_CLIENT_CONFIG_PATH, "Key", tostring(key))
        return {}
    end
    local values = template.Values
    return values[index]
end

function XRestaurantConfigs.StrPos2Vector3(strPos, separator)
    separator = separator or "|"
    strPos = strPos or ""
    local tmp = string.Split(strPos, separator)
    local arr = {}
    for i = 1, 3 do
        local str = tmp[i]
        arr[i] = str and tonumber(str) or 0
    end
    return CS.UnityEngine.Vector3(arr[1], arr[2], arr[3])
end

function XRestaurantConfigs.GetWorkBenchData(areaType, index)
    if not WorkBenchData or not WorkBenchData[areaType] 
            or not WorkBenchData[areaType][index] then
        local template = TableWorkPos[areaType][index]
        if not template then
            XLog.ErrorTableDataNotFound("XRestaurantConfigs.GetWorkBenchData",
                    "RestaurantWorkPos", TABLE_WORK_POS_PATH, "Type" .. tostring(areaType) .. " Index = " .. tostring(index))
            return {
                WorkPosition    = CS.UnityEngine.Vector3.zero,
                IconOffset      = CS.UnityEngine.Vector3.zero
            }
        end
        WorkBenchData = WorkBenchData or {}
        WorkBenchData[areaType] = WorkBenchData[areaType] or {}
        WorkBenchData[areaType][index] = {
            WorkPosition    = XRestaurantConfigs.StrPos2Vector3(template.Pos),
            IconOffset      = XRestaurantConfigs.StrPos2Vector3(template.IconOffset)
        }
    end
    return WorkBenchData[areaType][index]
end

function XRestaurantConfigs.TransProduceTime(speed)
    local min = math.floor(speed / 60)
    local sec = speed - min * 60
    if sec == 0 then
        return string.format("%d%s0%s ", min, STR_MINUTE, STR_SECOND)
    elseif min == 0 then
        return string.format("%d%s", sec, STR_SECOND)
    end
    return string.format("%d%s%02d%s", min, STR_MINUTE, sec, STR_SECOND)
end

function XRestaurantConfigs.GetGlobalIllumination(level)
    local template = TableClientConfig.GlobalIlluminationPath
    local paths = template.Values
    local count = #paths
    local index = math.min(level, count)
    return paths[index]
end

function XRestaurantConfigs.GetStatisticsTip(areaType, index)
    local key = XRestaurantConfigs.CheckIsIngredientArea(areaType)
            and "IngredientStatisticsTip" or "FoodStatisticsTip"
    return XRestaurantConfigs.GetClientConfig(key, index)
end

function XRestaurantConfigs.GetIngredientStoragePreviewTip(produceSpeed, consumeSpeed, count)
    if produceSpeed == 0 and consumeSpeed == 0 then
        return ""
    end
    
    local subSpeed = produceSpeed - consumeSpeed
    if math.abs(subSpeed) <= XRestaurantConfigs.Inaccurate and produceSpeed ~= 0 then
        return XRestaurantConfigs.GetClientConfig("StoragePreviewTip1", 3)
    end
    local index = subSpeed > 0 and 1 or 2
    local desc = XRestaurantConfigs.GetClientConfig("StoragePreviewTip1", index)
    local hour = math.abs(count / subSpeed)
    return string.format(desc, XRestaurantConfigs.GetAroundValue(hour, XRestaurantConfigs.Digital.Two))
end

function XRestaurantConfigs.GetCookStoragePreviewTip(isPositive, insufficient, isZero, time)
    if isZero then
        return XRestaurantConfigs.GetClientConfig("StoragePreviewTip2", 4)
    end
    local index
    --生产速度 > 消耗速度 && 食材库存足够
    if isPositive then
        index = 1
    elseif insufficient then --食材消耗 > 售卖 
        index = 3
    else --食材消耗 < 售卖
        index = 2
    end
    local desc = XRestaurantConfigs.GetClientConfig("StoragePreviewTip2", index)
    return string.format(desc, XRestaurantConfigs.GetAroundValue(time, XRestaurantConfigs.Digital.Two))
end

function XRestaurantConfigs.GetSaleStoragePreviewTip(fullTime, saleTime)
    if math.abs(fullTime - saleTime) <= XRestaurantConfigs.Inaccurate then
        return XRestaurantConfigs.GetClientConfig("StoragePreviewTip3", 3)
    end
    --售卖完毕
    local index, time
    if fullTime > saleTime then
        index = 2
        time = saleTime
    else--收银台满
        index = 1
        time = fullTime
    end
    local desc = XRestaurantConfigs.GetClientConfig("StoragePreviewTip3", index)
    return string.format(desc, XRestaurantConfigs.GetAroundValue(time, XRestaurantConfigs.Digital.Two))
end

function XRestaurantConfigs.GetStayTimeRange()
    return RandomStay
end

--function XRestaurantConfigs.GetBubbleTimeRange()
--    return RandomBubble
--end

function XRestaurantConfigs.GetShopTimeTxt(timeStr)
    return string.format(XRestaurantConfigs.GetClientConfig("ShopTimeTxt", 1), timeStr)
end

function XRestaurantConfigs.GetShopBuyTxtColor(index)
    return XRestaurantConfigs.GetClientConfig("ShopBuyTxtColor", index)
end

function XRestaurantConfigs.GetShopBuyLimitColor(index)
    return XRestaurantConfigs.GetClientConfig("ShopBuyLimitColor", index)
end

function XRestaurantConfigs.GetSignedTxt()
    return XRestaurantConfigs.GetClientConfig("SignedTxt", 1)
end

function XRestaurantConfigs.GetSignNotInTimeTxt()
    return XRestaurantConfigs.GetClientConfig("SignNotInTimeTxt", 1)
end

function XRestaurantConfigs.GetSkillAdditionDesc(areaType)
    local index = XRestaurantConfigs.CheckIsSaleArea(areaType) and 2 or 1
    return XRestaurantConfigs.GetClientConfig("SkillAdditionDesc", index)
end

function XRestaurantConfigs.GetSkillNoAdditionDesc()
    return XRestaurantConfigs.GetClientConfig("SkillAdditionDesc", 3)
end

function XRestaurantConfigs.GetSkillAdditionUnit(areaType)
    local index = XRestaurantConfigs.CheckIsSaleArea(areaType) and 2 or 1
    return XRestaurantConfigs.GetClientConfig("ProduceTimeUnit", index)
end

function XRestaurantConfigs.CheckIsIngredientArea(areaType)
    return areaType == XRestaurantConfigs.AreaType.IngredientArea
end

function XRestaurantConfigs.CheckIsFoodArea(areaType)
    return areaType == XRestaurantConfigs.AreaType.FoodArea
end

function XRestaurantConfigs.CheckIsSaleArea(areaType)
    return areaType == XRestaurantConfigs.AreaType.SaleArea
end

function XRestaurantConfigs.GetRequestFrequentlyTip(waitSecond)
    local tip = XRestaurantConfigs.GetClientConfig("RequestFrequentlyTip", 1)
    tip = string.format(tip, waitSecond)
    return tip
end

function XRestaurantConfigs.GetCharacterEffectData(index)
    if not CharacterEffectData or not CharacterEffectData[index] then
        CharacterEffectData = CharacterEffectData or {}
        local posStr = XRestaurantConfigs.GetClientConfig("CharacterEffectPos", index)
        CharacterEffectData[index] = {
            Url = XRestaurantConfigs.GetClientConfig("CharacterEffect", index),
            Position = XRestaurantConfigs.StrPos2Vector3(posStr)
        }
    end
    return CharacterEffectData[index]
end

function XRestaurantConfigs.GetSignNpcEffect(index)
    return XRestaurantConfigs.GetClientConfig("SignNPCEffect", index)
end

function XRestaurantConfigs.GetUiEffect(index)
    return XRestaurantConfigs.GetClientConfig("UiEffect", index)
end

function XRestaurantConfigs.GetWorkPauseReason(index)
    return XRestaurantConfigs.GetClientConfig("WorkPauseReason", index)
end

function XRestaurantConfigs.GetOrderNpcBehaviourId(state)
    -- state 下标从0开始
    state = state + 1
    return XRestaurantConfigs.GetClientConfig("OrderNpcBehaviourId", state)
end

function XRestaurantConfigs.GetSignNpcBehaviourId(state)
    return XRestaurantConfigs.GetClientConfig("SignNpcBehaviourId", state)
end

function XRestaurantConfigs.GetStaffNpcBehaviourId(state)
    return XRestaurantConfigs.GetClientConfig("StaffNpcBehaviourId", state)
end

function XRestaurantConfigs.GetStaffTabText(index)
    return XRestaurantConfigs.GetClientConfig("StaffTabText", index)
end

function XRestaurantConfigs.GetRecipeTaskTip()
    return XRestaurantConfigs.GetClientConfig("RecipeTaskTriggerTip", 1)
end

function XRestaurantConfigs.GetCommonUnlockText(index)
    return XRestaurantConfigs.GetClientConfig("CommonUnlockText", index)
end

function XRestaurantConfigs.GetRestaurantNotInBusinessText()
    return XRestaurantConfigs.GetClientConfig("RestaurantNotInBusiness", 1)
end

function XRestaurantConfigs.GetBuffAreaUnlockTip(areaType)
    local minLevel = XRestaurantConfigs.GetAreaBuffUnlockMinLevel(areaType)
    return string.format(XRestaurantConfigs.GetCommonUnlockText(2), minLevel)
end

function XRestaurantConfigs.GetBuffUnlockLvTip(buffId)
    local minLevel = XRestaurantConfigs.GetBuffUnlockLv(buffId)
    return string.format(XRestaurantConfigs.GetCommonUnlockText(2), minLevel)
end

function XRestaurantConfigs.GetBuffUnlockedTip(buffId)
    local desc = XRestaurantConfigs.GetClientConfig("BuffUpdateText", 1)
    return string.format(desc, XRestaurantConfigs.GetBuffName(buffId))
end

function XRestaurantConfigs.GetBuffSwitchTip(areaType, buffId)
    local desc = XRestaurantConfigs.GetClientConfig("BuffUpdateText", 2)
    return string.format(desc, XRestaurantConfigs.GetCameraAuxiliaryAreaName(areaType), XRestaurantConfigs.GetBuffName(buffId))
end

function XRestaurantConfigs.GetCameraProperty()
    local key = "CameraProperty"
    local template = TableClientConfig[key]
    local minX = tonumber(template.Values[1])
    local maxX = tonumber(template.Values[2])
    local speed = tonumber(template.Values[3])
    local euler = XRestaurantConfigs.StrPos2Vector3(template.Values[4])
    local duration = tonumber(template.Values[5])
    local inFov = tonumber(template.Values[6])
    local outFov = tonumber(template.Values[8])
    local moveMinimumX = tonumber(template.Values[7])
    local outEuler = XRestaurantConfigs.StrPos2Vector3(template.Values[9])
    
    return minX, maxX, speed, euler, duration, inFov, outFov, moveMinimumX, outEuler
end

function XRestaurantConfigs.GetBuffAdditionIcon()
    return XRestaurantConfigs.GetClientConfig("AdditionIcon", 1)
end

function XRestaurantConfigs.GetSkillAdditionIcon()
    return XRestaurantConfigs.GetClientConfig("AdditionIcon", 2)
end

function XRestaurantConfigs.GetStopAllProductText()
    local key = "StopAllProductText"
    local template = TableClientConfig[key]
    return template.Values[1], template.Values[2]
end

function XRestaurantConfigs.CustomerProperty()
    local min = tonumber(XRestaurantConfigs.GetClientConfig("CustomerProperty", 1))
    local max = tonumber(XRestaurantConfigs.GetClientConfig("CustomerProperty", 2))
    
    return min, max
end

function XRestaurantConfigs.GetUpOrDownArrowIcon(index)
    return XRestaurantConfigs.GetClientConfig("RImgUpgradeIcon", index)
end

function XRestaurantConfigs.GetBuffAdditionText(areaType)
    return XRestaurantConfigs.GetClientConfig("BuffAdditionText", areaType)
end

function XRestaurantConfigs.GetNoStaffWorkText()
    return XRestaurantConfigs.GetClientConfig("NoStaffWorkText", 1)
end

function XRestaurantConfigs:GetRunningTimeStr(index)
    return XRestaurantConfigs.GetClientConfig("RunningTimeStr", index)
end

function XRestaurantConfigs.CheckGuideAllFinish()
    for _, guideId in ipairs(XRestaurantConfigs.GuideGroupIds) do
        if not XDataCenter.GuideManager.CheckIsGuide(guideId) then
            return false
        end
    end
    return true
end 

function XRestaurantConfigs.GetOrderTitleText(name)
    return string.format(XRestaurantConfigs.GetClientConfig("OrderTitleText", 1), name)
end

function XRestaurantConfigs.GetAroundValue(value, digital)
    local decimal = math.pow(10, digital)
    return CS.UnityEngine.Mathf.Floor(value * decimal + 0.5) / decimal
end

function XRestaurantConfigs.Burying(btnId, uiName)
    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    dict["update_time"] = XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp())
    dict["ui_name"] = uiName
    dict["btn_id"] = btnId

    CS.XRecord.Record(dict, "900002", "RestaurantRecord")
end