XRoomCharFilterTipsConfigs = XRoomCharFilterTipsConfigs or {}

local TABLE_CHARACTER_FILTER = "Client/Character/CharacterFilter.tab"
local TABLE_CHARACTER_FILTER_TAG_GROUP = "Client/Character/CharacterFilterTagGroup.tab"
local TABLE_CHARACTER_FILTER_TAG = "Client/Character/CharacterFilterTag.tab"

local TABLE_CHARACTER_SORT = "Client/Character/CharacterSort.tab"
local TABLE_CHARACTER_SORT_TAG = "Client/Character/CharacterSortTag.tab"


local CharacterFilterConfig             -- 筛选配置项，包含标签组
local CharacterFilterTagGroupConfig     -- 筛选标签组，包含标签
local CharacterFilterTagConfig          -- 筛选标签

local CharacterSortConfig               -- 排序组，包含标签
local CharacterSortTagConfig            -- 排序标签

XRoomCharFilterTipsConfigs.DEFAULT_SORT_TAG_INDEX = 1

---
--- 筛选配置,对应CharacterFilter.tab中的Id
XRoomCharFilterTipsConfigs.EnumFilterType = {
    Common = 1,         -- 通用
    BabelTower = 2,     -- 巴别塔
    Bfrt = 3,           -- 据点占领
    Assign = 4,         -- 边界公约
    RogueLike = 5,      -- 爬塔
    SuperTower = 6,     -- 超级爬塔
}

---
--- 筛选组,对应CharacterFilterTagGroup.tab中的Id
XRoomCharFilterTipsConfigs.EnumFilterTagGroup = {
    Career = 1,  -- 职业
    Element = 2,    -- 能量
}

---
--- 排序配置,对应CharacterSort.tab中的Id
XRoomCharFilterTipsConfigs.EnumSortType = {
    Common = 1,         -- 通用
    BabelTower = 2,     -- 巴别塔
    Bfrt = 3,           -- 据点占领
    Assign = 4,         -- 边界公约
    RogueLike = 5,      -- 爬塔
    SuperTower = 6,     -- 超级爬塔
}

---
--- 排序标签,对应CharacterSortTag.tab中的Id
XRoomCharFilterTipsConfigs.EnumSortTag = {
    Default = 1,    -- 默认
    Level = 2,      -- 等级
    Quality = 3,    -- 阶级
    Ability = 4,    -- 战力
    SuperLevel = 5, -- 超限等级，超级爬塔活动
}

function XRoomCharFilterTipsConfigs.Init()
    CharacterFilterConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_FILTER, XTable.XTableCharacterFilter, "Id")
    CharacterFilterTagGroupConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_FILTER_TAG_GROUP, XTable.XTableCharacterFilterTagGroup, "Id")
    CharacterFilterTagConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_FILTER_TAG, XTable.XTableCharacterFilterTag, "Id")

    CharacterSortConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SORT, XTable.XTableCharacterSort, "Id")
    CharacterSortTagConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SORT_TAG, XTable.XTableCharacterSortTag, "Id")
end


------------------------------------------------------------------ 内部接口 -------------------------------------------------------

local GetCharacterFilterCfg = function(id)
    local config = CharacterFilterConfig[id]

    if not config then
        XLog.ErrorTableDataNotFound("XRoomCharFilterTipsConfigs.GetCharacterFilterCfg",
                "编队角色筛选", TABLE_CHARACTER_FILTER, "Id", tostring(id))
        return {}
    end

    return config
end

local GetCharacterFilterTagGroupCfg = function(id)
    local config = CharacterFilterTagGroupConfig[id]

    if not config then
        XLog.ErrorTableDataNotFound("XRoomCharFilterTipsConfigs.GetCharacterFilterTagGroupCfg",
                "编队角色筛选组", TABLE_CHARACTER_FILTER_TAG_GROUP, "Id", tostring(id))
        return {}
    end

    return config
end

local GetCharacterFilterTagCfg = function(id)
    local config = CharacterFilterTagConfig[id]

    if not config then
        XLog.ErrorTableDataNotFound("XRoomCharFilterTipsConfigs.GetCharacterFilterTagCfg",
                "编队角色筛选标签", TABLE_CHARACTER_FILTER_TAG, "Id", tostring(id))
        return {}
    end

    return config
end

local GetCharacterSortCfg = function(id)
    local config = CharacterSortConfig[id]

    if not config then
        XLog.ErrorTableDataNotFound("XRoomCharFilterTipsConfigs.GetCharacterSortCfg",
                "编队角色排序", TABLE_CHARACTER_SORT, "Id", tostring(id))
        return {}
    end

    return config
end

local GetCharacterSortTagCfg = function(id)
    local config = CharacterSortTagConfig[id]

    if not config then
        XLog.ErrorTableDataNotFound("XRoomCharFilterTipsConfigs.GetCharacterSortTagCfg",
                "编队角色排序标签", TABLE_CHARACTER_SORT_TAG, "Id", tostring(id))
        return {}
    end

    return config
end


------------------------------------------------------------------ CharacterFilter.tab -------------------------------------------------------

---
--- 根据'id'获取筛选配置的筛选组
---@return table
function XRoomCharFilterTipsConfigs.GetFilterTagGroups(id)
    local cfg = GetCharacterFilterCfg(id)
    return cfg.TagGroups
end


------------------------------------------------------------------ CharacterFilterTagGroup.tab -------------------------------------------------------

---
--- 根据'id'获取筛选组的名称
---@return string
function XRoomCharFilterTipsConfigs.GetFilterTagGroupName(id)
    local cfg = GetCharacterFilterTagGroupCfg(id)
    return cfg.GroupName
end

---
--- 根据'id'获取筛选组包含的筛选标签
---@return table
function XRoomCharFilterTipsConfigs.GetFilterTagGroupTags(id)
    local cfg = GetCharacterFilterTagGroupCfg(id)
    return cfg.Tags
end


------------------------------------------------------------------ CharacterFilterTag.tab -------------------------------------------------------

---
--- 根据'id'获取筛选标签的名称
---@return string
function XRoomCharFilterTipsConfigs.GetFilterTagName(id)
    local cfg = GetCharacterFilterTagCfg(id)
    return cfg.TagName
end

---
--- 根据'id'获取筛选标签的角色类型，0通用、1构造体、2授格者
---@return number
function XRoomCharFilterTipsConfigs.GetFilterTagCharType(id)
    local cfg = GetCharacterFilterTagCfg(id)
    return cfg.CharacterType
end

---
--- 根据'id'获取筛选标签所代表的值
---@return number
function XRoomCharFilterTipsConfigs.GetFilterTagValue(id)
    local cfg = GetCharacterFilterTagCfg(id)
    return cfg.Value
end


------------------------------------------------------------------ CharacterSort.tab -------------------------------------------------------

---
--- 根据'id'获取排序配置包含的标签
---@return table
function XRoomCharFilterTipsConfigs.GetCharacterSortTags(id)
    local cfg = GetCharacterSortCfg(id)
    return cfg.Tags
end


------------------------------------------------------------------ CharacterSortTag.tab -------------------------------------------------------

---
--- 根据'id'获取排序标签的名称
---@return string
function XRoomCharFilterTipsConfigs.GetCharacterSortTagName(id)
    local cfg = GetCharacterSortTagCfg(id)
    return cfg.TagName
end

---
--- 根据'id'获取排序标签的角色类型，0通用、1构造体、2授格者
---@return number
function XRoomCharFilterTipsConfigs.GetCharacterSortTagCharType(id)
    local cfg = GetCharacterSortTagCfg(id)
    return cfg.CharacterType
end