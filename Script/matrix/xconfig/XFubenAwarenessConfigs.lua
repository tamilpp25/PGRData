XFubenAwarenessConfigs = XConfigCenter.CreateTableConfig(XFubenAwarenessConfigs, "XFubenAwarenessConfigs", "Fuben/Awareness")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XFubenAwarenessConfigs.TableKey = enum({
    AwarenessChapter = {},
    AwarenessTeamInfo = {},
})

local StageChapterIdDic = {}

function XFubenAwarenessConfigs.Init()
    XFubenAwarenessConfigs.CreateStageChapterIdDic()
end

---------------关卡
function XFubenAwarenessConfigs.CreateStageChapterIdDic()
    for chapterId, v in pairs(XFubenAwarenessConfigs.GetAllConfigs(XFubenAwarenessConfigs.TableKey.AwarenessChapter)) do
        for k, stageId in pairs(v.StageId) do
            StageChapterIdDic[stageId] = chapterId
        end
    end
end

function XFubenAwarenessConfigs.GetStageChapterIdDic()
    return StageChapterIdDic
end

function XFubenAwarenessConfigs.GetChapterIdByStageId(stageId)
    return StageChapterIdDic[stageId]
end
