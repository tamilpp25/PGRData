XNewActivityCalendarConfigs = XConfigCenter.CreateTableConfig(XNewActivityCalendarConfigs, "XNewActivityCalendarConfigs", "NewActivityCalendar")

--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XNewActivityCalendarConfigs.TableKey = enum({
    NewActivityCalendarActivity = { ReadKeyName = "ActivityId" },
    NewActivityCalendarPeriod = { ReadKeyName = "PeriodId" },
    NewActivityCalendarKind = { DirType = XConfigCenter.DirectoryType.Client },
})

function XNewActivityCalendarConfigs.Init()

end

function XNewActivityCalendarConfigs.GetCalendarActivityConfig(activityId)
    return XNewActivityCalendarConfigs.GetCfgByIdKey(XNewActivityCalendarConfigs.TableKey.NewActivityCalendarActivity, activityId)
end

function XNewActivityCalendarConfigs.GetAllCalendarActivityConfig()
    return XNewActivityCalendarConfigs.GetAllConfigs(XNewActivityCalendarConfigs.TableKey.NewActivityCalendarActivity)
end

function XNewActivityCalendarConfigs.GetCalendarPeriodConfig(periodId)
    return XNewActivityCalendarConfigs.GetCfgByIdKey(XNewActivityCalendarConfigs.TableKey.NewActivityCalendarPeriod, periodId)
end

function XNewActivityCalendarConfigs.GetKindConfig(kindId)
    return XNewActivityCalendarConfigs.GetCfgByIdKey(XNewActivityCalendarConfigs.TableKey.NewActivityCalendarKind, kindId)
end