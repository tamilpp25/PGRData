-- BVB 配置类
XMonsterCombatConfigs = XConfigCenter.CreateTableConfig(XMonsterCombatConfigs, "XMonsterCombatConfigs", "Fuben/MonsterCombat")

--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============

XMonsterCombatConfigs.TableKey = enum({
    MonsterCombatActivity = {}, -- 活动表
    MonsterCombatChapter = {}, -- 章节表
    MonsterCombatStage = {}, -- 关卡表
    MonsterCombatMonster = {}, -- 怪物表
    MonsterCombatBuff = { ReadKeyName = "MonsterId" }, -- buff表
    MonsterCombatChapterDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 章节详情表
    MonsterCombatStageDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 关卡详情表
    MonsterCombatMonsterDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 怪物详情表
    MonsterCombatConfig = { ReadFuncName = "ReadByStringKey", ReadKeyName = "Key", DirType = XConfigCenter.DirectoryType.Client }, -- 配置表
})

-- 关卡详情
XMonsterCombatConfigs.StageDetailUiName = "UiMonsterCombatTeachingDetail"

--怪物详情
XMonsterCombatConfigs.MonsterInfoUiName = "UiMonsterCombatInfo"

XMonsterCombatConfigs.ChapterType = {
    Normal = 1, -- 普通章节
    Core = 2, -- 核心章节
}

XMonsterCombatConfigs.StageType = {
    Challenge = 1, -- 挑战模式
    TimeScore = 2, -- 时间刷分模式
    KillScore = 3, -- 击杀刷分模式
    RoundScore = 4, -- 轮次刷分模式
}

XMonsterCombatConfigs.MonsterInterfaceType = {
    Monster = 1, -- 怪物界面
    Battle = 2, -- 编队界面
}

function XMonsterCombatConfigs.Init()

end

function XMonsterCombatConfigs.GetAllMonsterIds()
    local allMonsterIds = {}
    local configs = XMonsterCombatConfigs.GetAllConfigs(XMonsterCombatConfigs.TableKey.MonsterCombatMonster)
    for _, config in pairs(configs) do
        table.insert(allMonsterIds, config.Id)
    end
    return allMonsterIds
end

function XMonsterCombatConfigs.GetMonsterCombatStagePrefabByKey(key)
    return XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatConfig, key).Values[1]
end

function XMonsterCombatConfigs.GetBuffConfigByMonsterId(monsterId)
    return XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatBuff, monsterId)
end
