local pairs = pairs
local tableInsert = table.insert
local ParseToTimestamp = XTime.ParseToTimestamp

local TABLE_WEAPON_FASHION_PATH = "Share/WeaponFashion/WeaponFashion.tab"
local TABLE_WEAPON_FASHION_RES_PATH = "Client/WeaponFashion/WeaponFashionRes.tab"

local WeaponFashionTemplates = {}
local WeaponFashionResTemplates = {}

local EquipTypeToWeaponFashionIdDic = {}

local function GetConfig(fashionId)
    local tab = WeaponFashionTemplates[fashionId]
    if tab == nil then
        XLog.ErrorTableDataNotFound("XWeaponFashionConfigs.GetConfig", "WeaponFashion", TABLE_WEAPON_FASHION_PATH, "Id", tostring(fashionId))
    end
    return tab
end

local function GetResConfig(fashionId)
    local tab = WeaponFashionResTemplates[fashionId]
    if tab == nil then
        XLog.ErrorTableDataNotFound("XWeaponFashionConfigs.GetResConfig", "WeaponFashionRes", TABLE_WEAPON_FASHION_RES_PATH, "Id", tostring(fashionId))
    end
    return tab
end

XWeaponFashionConfigs = XWeaponFashionConfigs or {}

XWeaponFashionConfigs.DefaultWeaponFashionId = 0

function XWeaponFashionConfigs.Init()
    WeaponFashionTemplates = XTableManager.ReadByIntKey(TABLE_WEAPON_FASHION_PATH, XTable.XTableWeaponFashion, "Id")
    WeaponFashionResTemplates = XTableManager.ReadByIntKey(TABLE_WEAPON_FASHION_RES_PATH, XTable.XTableWeaponFashionRes, "Id")

    for _, config in pairs(WeaponFashionTemplates) do
        local equipType = config.EquipType
        local fashionIds = EquipTypeToWeaponFashionIdDic[equipType] or {}
        tableInsert(fashionIds, config.Id)
        EquipTypeToWeaponFashionIdDic[equipType] = fashionIds
    end
end

function XWeaponFashionConfigs.IsDefaultId(fashionId)
    return fashionId == XWeaponFashionConfigs.DefaultWeaponFashionId
end

function XWeaponFashionConfigs.GetFashionEquipType(fashionId)
    return GetConfig(fashionId).EquipType
end

function XWeaponFashionConfigs.GetWeaponFashionIdsByEquipType(equipType)
    return EquipTypeToWeaponFashionIdDic[equipType] or {}
end

function XWeaponFashionConfigs.GetFashionBeginTime(fashionId)
    local timeStr = GetConfig(fashionId).EffectTimeStr
    return timeStr and ParseToTimestamp(timeStr) or 0
end

function XWeaponFashionConfigs.GetFashionExpireTime(fashionId)
    local timeStr = GetConfig(fashionId).ExpireTimeStr
    return timeStr and ParseToTimestamp(timeStr) or 0
end

function XWeaponFashionConfigs.GetFashionIcon(fashionId)
    return GetResConfig(fashionId).Icon
end

function XWeaponFashionConfigs.GetFashionBigIcon(fashionId)
    return GetResConfig(fashionId).BigIcon
end

function XWeaponFashionConfigs.GetFashionShopIcon(fashionId)
    return GetResConfig(fashionId).ShopIcon
end

function XWeaponFashionConfigs.GetFashionName(fashionId)
    return GetResConfig(fashionId).Name
end

function XWeaponFashionConfigs.GetFashionQuality(fashionId)
    return GetResConfig(fashionId).Quality
end

function XWeaponFashionConfigs.GetFashionDesc(fashionId)
    return GetResConfig(fashionId).Description
end

function XWeaponFashionConfigs.GetFashionWorldDescription(fashionId)
    return GetResConfig(fashionId).WorldDescription
end

function XWeaponFashionConfigs.GetFashionSkipIdParams(fashionId)
    return GetResConfig(fashionId).SkipIdParams
end

function XWeaponFashionConfigs.GetFashionPriority(fashionId)
    return GetResConfig(fashionId).Priority
end

function XWeaponFashionConfigs.GetWeaponResonanceModelId(case, fashionId, resonanceCount)
    resonanceCount = resonanceCount or 0
    local config = GetResConfig(fashionId)
    local resonanceModelTransIds = config["ResonanceModelTransId" .. resonanceCount]
    return resonanceModelTransIds and resonanceModelTransIds[case] or config.ModelTransId[case]
end

function XWeaponFashionConfigs.GetWeaponFashionResTemplates()
    return XTool.Clone(WeaponFashionResTemplates)
end

-- 获取有效时间内的全部武器涂装
function XWeaponFashionConfigs.GetWeaponFashionResTemplatesInTime()
    local weaponFashionResTemplates = XTool.Clone(WeaponFashionResTemplates)
    local weaponFashionResTemplateDic = {}
    local timeStamp = XTime.GetServerNowTimestamp()
    for _, WeaponFashionResTemplate in pairs(weaponFashionResTemplates) do
        local WeaponFashionTemplate = WeaponFashionTemplates[WeaponFashionResTemplate.Id]
        if WeaponFashionTemplate then
            local effectTimeStr = WeaponFashionTemplate.EffectTimeStr
            local expireTimeStr = WeaponFashionTemplate.ExpireTimeStr
            if effectTimeStr and expireTimeStr then
                if(timeStamp >= XTime.ParseToTimestamp(effectTimeStr) and timeStamp <= XTime.ParseToTimestamp(expireTimeStr)) then
                    weaponFashionResTemplateDic[WeaponFashionResTemplate.Id] = WeaponFashionResTemplate
                end
            elseif effectTimeStr then
                if(timeStamp >= XTime.ParseToTimestamp(effectTimeStr)) then
                    weaponFashionResTemplateDic[WeaponFashionResTemplate.Id] = WeaponFashionResTemplate
                end
            elseif expireTimeStr then
                if(timeStamp <= XTime.ParseToTimestamp(expireTimeStr)) then
                    weaponFashionResTemplateDic[WeaponFashionResTemplate.Id] = WeaponFashionResTemplate
                end
            else
                weaponFashionResTemplateDic[WeaponFashionResTemplate.Id] = WeaponFashionResTemplate
            end
        end
    end

    return weaponFashionResTemplateDic
end