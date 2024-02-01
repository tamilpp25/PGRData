XGachaConfigs = XConfigCenter.CreateTableConfig(XGachaConfigs, "XGachaConfigs", "Gacha")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XGachaConfigs.TableKey = enum({
    GachaShow = { DirType = XConfigCenter.DirectoryType.Client },
})

local TABLE_GACHA = "Share/Gacha/Gacha.tab"
local TABLE_GACHA_REWARD = "Share/Gacha/GachaReward.tab"
local TABLE_GACHA_PROBSHOW = "Client/Gacha/GachaProbShow.tab"
local TABLE_GACHA_RULE = "Client/Gacha/GachaRule.tab"
local TABLE_GACHA_SHOW_REWARD_CONFIG = "Client/Gacha/GachaShowRewardConfig.tab"
local TABLE_GACHA_CLIENT_CONFIG = "Client/Gacha/GachaClientConfig.tab"
local TABLE_GACHA_ITEM_EXCHANGE = "Share/Gacha/GachaItemExchange.tab"
local TABLE_GACHA_COURSE_REWARD = "Share/Gacha/GachaCourseReward.tab"

local Gachas = {}
local GachaRewards = {}
local GachaProbShow = {}
local GachaRule = {}
local GachaItemExchange = {}
local GachaCourseReward = {}
local GachaShowRewardConfig = {}
local GachaClientConfig = {}

-- Gacha卡池组字典
-- Key:OrganizeId
-- Value:Gacha.tab配置项数组{gacha, gacha, ..., gacha}
local GachaOrganizeDic = {}

XGachaConfigs.RewardType = {
    Count = 0,
    NotCount = 1,
}

XGachaConfigs.RareType = {
    Normal = false,
    Rare = true,
}

XGachaConfigs.UiType = {
    Free = 1,
    Pay = 2,
}

-- 卡池组内卡池的状态
XGachaConfigs.OrganizeGachaStatus = {
    Normal = 1,     -- 正常（可抽卡）
    Lock = 2,       -- 锁定
    SoldOut = 3,    -- 售罄
}

function XGachaConfigs.Init()
    Gachas = XTableManager.ReadByIntKey(TABLE_GACHA, XTable.XTableGacha, "Id")
    GachaRewards = XTableManager.ReadByIntKey(TABLE_GACHA_REWARD, XTable.XTableGachaReward, "Id")
    GachaProbShow = XTableManager.ReadByIntKey(TABLE_GACHA_PROBSHOW, XTable.XTableGachaProbShow, "Id")
    GachaRule = XTableManager.ReadByIntKey(TABLE_GACHA_RULE, XTable.XTableGachaRule, "Id")
    GachaItemExchange = XTableManager.ReadByIntKey(TABLE_GACHA_ITEM_EXCHANGE, XTable.XTableGachaItemExchange, "Id")
    GachaCourseReward = XTableManager.ReadByIntKey(TABLE_GACHA_COURSE_REWARD, XTable.XTableGachaCourseReward, "Id")
    GachaShowRewardConfig = XTableManager.ReadByIntKey(TABLE_GACHA_SHOW_REWARD_CONFIG, XTable.XTableGachaShowRewardConfig, "Id")
    GachaClientConfig = XTableManager.ReadByStringKey(TABLE_GACHA_CLIENT_CONFIG, XTable.XTableGachaClientConfig, "Key")

    for _, gacha in pairs(Gachas) do
        if gacha.OrganizeId and gacha.OrganizeId ~= 0 then
            if not GachaOrganizeDic[gacha.OrganizeId] then
                GachaOrganizeDic[gacha.OrganizeId] = {}
            end
            table.insert(GachaOrganizeDic[gacha.OrganizeId], gacha)
        end
    end

    for _, gachas in pairs(GachaOrganizeDic) do
        table.sort(gachas, function(a, b)
            return a.OrganizeSort < b.OrganizeSort
        end)
    end
end

function XGachaConfigs.GetGachaShowByGroupId(id)
    if not id then
        id = 1
    end
    local config = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaShow)
    local res = {}
    for k, v in pairs(config) do
        if v.GroupId == id then
            res[v.Type] = v
        end
    end
    return res
end

function XGachaConfigs.GetGachaShowRewardConfig()
    return GachaShowRewardConfig
end

function XGachaConfigs.GetGachaShowRewardConfigById(id)
    return GachaShowRewardConfig[id]
end

function XGachaConfigs.GetGachaReward()
    return GachaRewards
end

function XGachaConfigs.GetGachaCourseReward()
    return GachaCourseReward
end

function XGachaConfigs.GetGachaCourseRewardById(id)
    return GachaCourseReward[id]
end

function XGachaConfigs.GetGachas()
    return Gachas
end

function XGachaConfigs.GetGachaItemExchangeCfgById(id)
    return GachaItemExchange[id]
end

function XGachaConfigs.GetGachaCfgById(id)
    if not Gachas[id] then
        XLog.ErrorTableDataNotFound("XGachaConfigs.GetGachaCfgById", "Gacha", TABLE_GACHA, "id", tostring(id))
        return {}
    end
    return Gachas[id]
end

function XGachaConfigs.GetGachaProbShows()
    return GachaProbShow
end

function XGachaConfigs.GetGachaRuleCfgById(id)
    if not GachaRule[id] then
        XLog.ErrorTableDataNotFound("XGachaConfigs.GetGachaRuleCfgById", "GachaRule", TABLE_GACHA_RULE, "id", tostring(id))
        return
    end
    return GachaRule[id]
end

function XGachaConfigs.GetClientConfig(key, index)
    index = index or 1
    if not GachaClientConfig[key] then
        XLog.ErrorTableDataNotFound("XGachaConfigs.GetClientConfig", "GachaClientConfig", TABLE_GACHA_CLIENT_CONFIG, "key", tostring(key))
        return nil
    end
    return GachaClientConfig[key].Value[index]
end

-------------------------------------------Organize卡池组数据读取----------------------------------------------------------

---
--- 内部接口
--- 获取属于'organizeId'卡池组的卡池配置
local function GetGchaOrganize(organizeId)
    if not GachaOrganizeDic[organizeId] then
        XLog.Error(string.format("XGachaConfigs:GetOrganize函数错误，GachaOrganizeDic不存在organizeId:%s的数据",
                tostring(organizeId)))
        return {}
    end
    return GachaOrganizeDic[organizeId]
end

---
--- 内部接口
--- 获取'organizeId'卡池组的第一个卡池
local function GetOrganizeFirstGacha(organizeId)
    local organize = GetGchaOrganize(organizeId)

    local firstGacha = organize[1]
    if not firstGacha then
        XLog.Error(string.format("XGachaConfigs.GetOrganizeFirstGacha函数错误，卡池组%s没有PreGachaId为空或者0的卡池",
                tostring(organizeId)))
        return
    end
    return firstGacha
end


---
--- 获取'organizeId'卡池组的所有卡池的Id数组
function XGachaConfigs.GetOrganizeGahcaIdList(organizeId)
    local organize = GetGchaOrganize(organizeId)
    local idList = {}
    for index, gacha in ipairs(organize) do
        idList[index] = gacha.Id
    end
    return idList
end

---
--- 获取'organizeId'卡池组第一个卡池的GachaRule配置
---@return table GachaRule配置
function XGachaConfigs.GetOrganizeRuleCfg(organizeId)
    local firstGacha = GetOrganizeFirstGacha(organizeId)
    if not firstGacha then
        return
    end
    return XGachaConfigs.GetGachaRuleCfgById(firstGacha.Id)
end

---
--- 获取'organizeId'卡池组第一个卡池的开始时间与结束时间
---@return string 开始时间|结束时间
function XGachaConfigs.GetOrganizeTime(organizeId)
    local firstGacha = GetOrganizeFirstGacha(organizeId)
    if not firstGacha then
        return
    end
    return firstGacha.StartTimeStr, firstGacha.EndTimeStr
end

---
--- 获取'organizeId'卡池组'gachaId'在数组中的序号
function XGachaConfigs.GetOrganizeIndex(organizeId, gachaId)
    local organize = GetGchaOrganize(organizeId)
    for i, gacha in ipairs(organize) do
        if gacha.Id == gachaId then
            return i
        end
    end
    XLog.Error(string.format("XGachaConfigs.GetOrganizeIndex函数错误，卡池%s不在%s卡池组中", tostring(gachaId), tostring(organizeId)))
end

---
--- 获取'organizeId'卡池组'gachaId'前一个卡池的id
--- 如果'gachaId'是第一个卡池则返回0
function XGachaConfigs.GetOrganizePreGachaId(gachaId)
    local gacha = XGachaConfigs.GetGachaCfgById(gachaId)
    return gacha.PreGachaId
end

---
--- 获取'organizeId'卡池组'gachaId'后一个卡池的id
--- 如果'gachaId'是最后一个卡池则返回0
function XGachaConfigs.GetOrganizeNextGachaId(organizeId, gachaId)
    local idList = XGachaConfigs.GetOrganizeGahcaIdList(organizeId)

    local index
    for i, id in ipairs(idList) do
        if id == gachaId then
            index = i + 1
        end
    end
    if not index then
        XLog.Error(string.format("XGachaConfigs.GetOrganizeNextGachaId函数错误,%s卡池组没有%s卡池数据",
                tostring(organizeId), tostring(gachaId)))
        return 0
    end
    return idList[index] or 0
end

---
--- 获取'gachaId'的卡池图标
function XGachaConfigs.GetOrganizeGachaIcon(gachaId)
    local gacha = XGachaConfigs.GetGachaCfgById(gachaId)
    return gacha.GachaIcon
end
