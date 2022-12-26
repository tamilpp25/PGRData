XCollectionWallConfigs = XCollectionWallConfigs or {}

local TABLE_COLLECTION_WALL = "Share/ScoreTitle/CollectionWall.tab"
local TABLE_COLLECTION_WALL_DECORATION = "Share/ScoreTitle/CollectionWallDecoration.tab"
local TABLE_COLLECTION_SIZE = "Client/CollectionWall/CollectionSize.tab"

-- 装饰品种类
XCollectionWallConfigs.EnumDecorationType = {
    Background = 1, -- 背景
    Pedestal = 2,   -- 底座
}

-- 收藏品墙的状态
XCollectionWallConfigs.EnumWallState = {
    Lock = 1,   -- 未解锁
    None = 2,   -- 空白
    Normal = 3, -- 正常
}

-- 收藏品墙格子的使用的种类
XCollectionWallConfigs.EnumWallGridOpenType = {
    Overview = 1,   -- 管理界面
    Setting = 2,    -- 设置界面
}

-- 收藏品墙装饰品的解锁类型
XCollectionWallConfigs.EnumDecorationUnlockType = {
    Condition = 1,  -- 条件解锁
    Reward = 2,     -- 奖励解锁
}

-- 编辑模式选择的种类
XCollectionWallConfigs.EnumSelectType = {
    BACKGROUND = 1, -- 墙面
    PEDESTAL = 2,   -- 底座
    LITTL = 3,      -- 模型小
    MIDDLE = 4,     -- 模型中
    BIG = 5,        -- 模型大
}

-- 墙面单元格尺寸为90*90
XCollectionWallConfigs.CellSize = 90

local CollectionWallCfg = {}
local CollectionWallDecorationCfg = {}
local CollectionSizeCfg = {}

function XCollectionWallConfigs.Init()
    CollectionWallCfg = XTableManager.ReadByIntKey(TABLE_COLLECTION_WALL, XTable.XTableCollectionWall, "Id")
    CollectionWallDecorationCfg = XTableManager.ReadByIntKey(TABLE_COLLECTION_WALL_DECORATION, XTable.XTableCollectionWallDecoration, "Id")
    CollectionSizeCfg = XTableManager.ReadByIntKey(TABLE_COLLECTION_SIZE, XTable.XTableCollectionSize, "Id")
end


------------------------------------------------------------------ CollectionWall.tab数据读取 -------------------------------------------------------

---
--- 根据'id'获取收藏品墙的配置
--- 建议使用XCollectionWall.lua的接口来获取需要的数据
---@param id number
---@return table
function XCollectionWallConfigs.GetCollectionWallCfg(id)
    local config = CollectionWallCfg[id]

    if not config then
        XLog.ErrorTableDataNotFound("XCollectionWallConfigs.GetCollectionWallCfg",
                "收藏品墙配置", TABLE_COLLECTION_WALL, "Id", tostring(id))
        return {}
    end

    return config
end

---
--- 获取所有收藏品墙的Id数组
---@return table
function XCollectionWallConfigs.GetCollectionWallIdList()
    local idList = {}
    for id, _ in pairs(CollectionWallCfg) do
        table.insert(idList, id)
    end
    return idList
end


------------------------------------------------------------------ CollectionWallDecoration.tab数据读取 -------------------------------------------------------

---
--- 根据'id'获取收藏品墙饰品配置
---@param id number
---@return table
local function GetColDecCfgList(id)
    local config = CollectionWallDecorationCfg[id]

    if not config then
        XLog.ErrorTableDataNotFound("XCollectionWallConfigs.GetColDecCfgList",
                "收藏品墙饰品配置", TABLE_COLLECTION_WALL_DECORATION, "Id", tostring(id))
        return {}
    end

    return config
end

---
--- 获取全部‘type’种类的收藏品墙饰品配置数组
---@param type number
---@return table
function XCollectionWallConfigs.GetColDecCfgListByType(type)
    local result = {}

    for _,data in pairs(CollectionWallDecorationCfg) do
        if data.Type == type then
            table.insert(result,data)
        end
    end

    return result
end

---
--- 根据'id'获取收藏品墙饰品的种类
---@param id number
---@return number
function XCollectionWallConfigs.GetColDecType(id)
    local cfg = GetColDecCfgList(id)
    return cfg.Type
end

---
--- 根据'id'获取收藏品墙饰品的名称
---@param id number
---@return string
function XCollectionWallConfigs.GetColDecName(id)
    local cfg = GetColDecCfgList(id)
    return cfg.Name
end

---
--- 根据'id'获取收藏品墙饰品的图标
---@param id number
---@return string
function XCollectionWallConfigs.GetColDecIcon(id)
    local cfg = GetColDecCfgList(id)
    return cfg.Icon
end

---
--- 根据'id'获取收藏品墙饰品的路径
---@param id number
---@return string
function XCollectionWallConfigs.GetColDecPath(id)
    local cfg = GetColDecCfgList(id)
    return cfg.Path
end

---
--- 根据'id'获取收藏品墙饰品的解锁类型
---@param id number
---@return number
function XCollectionWallConfigs.GetColDecUnlockType(id)
    local cfg = GetColDecCfgList(id)
    return cfg.UnlockType
end

---
--- 根据'id'获取收藏品墙饰品的解锁条件
---@param id number
---@return number
function XCollectionWallConfigs.GetColDecCondition(id)
    local cfg = GetColDecCfgList(id)
    return cfg.Condition
end

---
--- 根据'id'获取收藏品墙饰品的解锁描述
---@param id number
---@return string
function XCollectionWallConfigs.GetColDecLockDesc(id)
    local cfg = GetColDecCfgList(id)
    return cfg.LockDesc
end

---
--- 根据'id'获取收藏品墙饰品的排序值
---@param id number
---@return string
function XCollectionWallConfigs.GetColDecRank(id)
    local cfg = GetColDecCfgList(id)
    return cfg.Rank
end


------------------------------------------------------------------ CollectionSize.tab数据读取 -------------------------------------------------------

---
--- 根据'id'获取收藏品尺寸数据
---@param id number
---@return number
local function GetCollectionSizeCfg(id)
    local config = CollectionSizeCfg[id]

    if not config then
        XLog.ErrorTableDataNotFound("XCollectionWallConfigs.GetColDecCfgList",
                "收藏品尺寸配置", TABLE_COLLECTION_SIZE, "Id", tostring(id))
        return {}
    end

    return config
end

---
--- 根据'id'获取收藏品尺寸
---@param id number
---@return number
function XCollectionWallConfigs.GetCollectionSize(id)
    local cfg = GetCollectionSizeCfg(id)
    return cfg.Size
end

---
--- 根据'id'获取收藏品缩放系数
---@param id number
---@return number
function XCollectionWallConfigs.GetCollectionScale(id)
    local cfg = GetCollectionSizeCfg(id)
    return cfg.Scale
end

---
--- 根据'id'获取收藏品占用的格子
---@param id number
---@return number
function XCollectionWallConfigs.GetCollectionGridNum(id)
    local cfg = GetCollectionSizeCfg(id)
    return cfg.GridNum
end