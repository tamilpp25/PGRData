XRiftConfig = XConfigCenter.CreateTableConfig(XRiftConfig, "XRiftConfig", "Fuben/Rift")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XRiftConfig.TableKey = enum({
    RiftActivity = {},
    RiftChapter = {},
    RiftLayer = {},
    RiftNodeRandomItem = {}, -- 关卡库
    RiftMonster = {},
    RiftStage = {},
    RiftMonsterWareRandomItem = {}, -- 怪物库
    RiftMonsterBuffRandomItem = {}, -- 词缀库
    RiftCharacterAndRobot = {ReadKeyName = "CharacterId"},
    RiftTeamAttribute = {}, -- 队伍加点表
    RiftTeamAttributeCost = {}, -- 队伍加点消耗表
    RiftTeamAttributeEffect = {}, -- 队伍加点效果表
    RiftTeamAttributeEffectType = { DirType = XConfigCenter.DirectoryType.Client }, -- 队伍加点效果类型表
    RiftPlugin = {}, -- 插件表
    RiftPluginAttrFix = {}, -- 插件补正表
    RiftPluginQuality = { DirType = XConfigCenter.DirectoryType.Client }, -- 插件品质表
    RiftPluginShopGoods = {}, -- 插件商店表
    RiftTask = { DirType = XConfigCenter.DirectoryType.Client }, -- 任务表
    RiftLayerDetail = { DirType = XConfigCenter.DirectoryType.Client },
    RiftFuncUnlock = {}, -- 功能解锁表
    RiftShop = { DirType = XConfigCenter.DirectoryType.Client }, -- 商店表
})

XRiftConfig.LayerType = 
{
    Normal = 1,
    Zoom = 2, -- 跃升
    Multi = 3,
}

XRiftConfig.AttributeType = 
{
    Strength = 1, -- 力量
    Physical = 2, -- 体力
    Energy = 3, -- 能量
    Focus = 4, -- 专注
}

XRiftConfig.AttributeLevelStr = 
{
    [1] = "B",
    [2] = "A",
    [3] = "S",
}

-- 属性补正效果类型
XRiftConfig.AttributeFixEffectType =
{
    Value = 1, -- 加成值
    Percent = 2, -- 加成百分比
}

-- 功能解锁
XRiftConfig.FuncUnlockId = 
{
    Attribute = 1,
    LuckyStage = 2,
    PluginShop = 3,
}

-- 自定义字典
local AttrEffectDic = {}
local PluginAttrFixDic = {}
local PluginFixGroupIdToAttrIdDic = {}
local StageIdDic = {}

XRiftConfig.StageGroupType = 
{
    Normal = 1,
    Zoom = 2, -- 跃升
    Multi = 3,
    Luck = 4,
}
-- 幸运节点的位置写死为4
XRiftConfig.StageGroupLuckyPos = 4
-- 属性加点模板数量
XRiftConfig.AttrTemplateCnt = 5
-- 默认属性加点模板id
XRiftConfig.DefaultAttrTemplateId = 1
-- 属性数量
XRiftConfig.AttrCnt = 4
-- 插件最多补正属性数量
XRiftConfig.PluginMaxFixCnt = 2

function XRiftConfig.Init()
    XRiftConfig.CreateAttributeEffectDic()
    XRiftConfig.CreatePluginAttrFixDic()
    XRiftConfig.CreateStageIdDic()
end

-------------------------------------------------- RiftActivity.tab 活动表 begin --------------------------------------------------

function XRiftConfig.GetActivityShopIds(id)
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftActivity, id)
    local shopIds = {}
    for _, shopId in ipairs(config.ShopId) do
        if XTool.IsNumberValid(shopId) then
            table.insert(shopIds, shopId)
        end
    end
    return shopIds
end
-------------------------------------------------- RiftActivity.tab 活动表 end --------------------------------------------------

-------------------------------------------------- RiftTeamAttribute.tab 队伍加点表 begin --------------------------------------------------

function XRiftConfig.GetAttrName(attrId)
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttribute, attrId)
    return config.Name
end
-------------------------------------------------- RiftTeamAttribute.tab 队伍加点表 end --------------------------------------------------

-------------------------------------------------- RiftTeamAttributeEffect.tab 队伍加点效果表 begin --------------------------------------------------

function XRiftConfig.CreateAttributeEffectDic()
    AttrEffectDic = {}
    local effectCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttributeEffect)
    for _, config in ipairs(effectCfgs) do
        local id = XRiftConfig.GetAttrEffectId(config.GroupId, config.Level)
        AttrEffectDic[id] = config
    end
end

-- 由groupId和level生成唯一id快速读取数据
function XRiftConfig.GetAttrEffectId(groupId, level)
    return tostring(groupId) .. "_" .. tostring(level)
end

function XRiftConfig.GetAttributeEffectConfig(groupId, level)
    local id = XRiftConfig.GetAttrEffectId(groupId, level)
    return AttrEffectDic[id]
end

-------------------------------------------------- RiftTeamAttributeEffect.tab 队伍加点效果表 end --------------------------------------------------

-------------------------------------------------- RiftPluginAttrFix.tab 插件补正表 begin --------------------------------------------------

function XRiftConfig.CreatePluginAttrFixDic()
    PluginAttrFixDic = {}
    local attrFixCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftPluginAttrFix)
    for _, config in ipairs(attrFixCfgs) do
        local id = XRiftConfig.GetPluginAttrFixId(config.GroupId, config.FixAttrId, config.FixAttrLevel)
        PluginAttrFixDic[id] = config
        PluginFixGroupIdToAttrIdDic[config.GroupId] = config.FixAttrId
    end
end

function XRiftConfig.GetPluginAttrFixId(groupId, fixAttrId, fixAttrLevel)
    return tostring(groupId) .. "_" .. tostring(fixAttrId) .. "_" .. tostring(fixAttrLevel)
end

function XRiftConfig.GetAttrIdByFixGroupId(groupId)
    return PluginFixGroupIdToAttrIdDic[groupId]
end

-- 插件补正配置多个groupId，每个groupId只受一种属性加成影响，以当前加点方案该属性点值 组成唯一的key
function XRiftConfig.GetPluginAttrFixConfig(groupId, fixAttrId, fixAttrLevel)
    local id = XRiftConfig.GetPluginAttrFixId(groupId, fixAttrId, fixAttrLevel)
    return PluginAttrFixDic[id]
end
-------------------------------------------------- RiftPluginAttrFix.tab 插件补正表 end --------------------------------------------------

function XRiftConfig.GetTeamAttributeName(attrId)
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttribute, attrId)
    return config.Name
end

-------------------------------------------------- Stage --------------------------------------------------
function XRiftConfig.CreateStageIdDic()
    for k, config in pairs(XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftStage)) do
        StageIdDic[config.StageId] = config
    end
end

function XRiftConfig.GetStageConfigById(stageId)
    return StageIdDic[stageId]
end
