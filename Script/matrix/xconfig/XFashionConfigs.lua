XFashionConfigs = XConfigCenter.CreateTableConfig(XFashionConfigs, "XFashionConfigs", "Fashion")

local TABLE_FASHION_SERIES = "Client/Fashion/FashionSeries.tab"
local TABLE_FASHION_PATH = "Share/Fashion/Fashion.tab"
local TABLE_FASHION_VOICE_PATH = "Client/Fashion/FashionVoice.tab"

--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XFashionConfigs.TableKey = enum({
    FashionAureole = {},
    Fashion = {}
})

--涂装头像类型
XFashionConfigs.HeadPortraitType = {
    Default = 0, --默认
    Liberation = 1, --终解
    Fashion = 2, --涂装头像
}

local FashionSeriesConfig = {}
local FashionVoiceConfig = nil
-- local CharacterAureoleIdDic = {} -- 角色id和终解环数据字典

function XFashionConfigs.Init()
    FashionSeriesConfig = XTableManager.ReadByIntKey(TABLE_FASHION_SERIES, XTable.XTableFashionSeries, "Id")
end

---------------------------------------------------FashionSeries.tab数据读取---------------------------------------------------------
local function GetFashionSeriesConfig(id)
    local cfg = FashionSeriesConfig[id]
    if cfg == nil then
        XLog.ErrorTableDataNotFound("XFashionConfigs.GetFashionSeriesConfig",
        "涂装系列",
        TABLE_FASHION_SERIES,
        "Id",
        tostring(id))
        return {}
    end
    return cfg
end

function XFashionConfigs.GetAureoleEffectPathById(id)
    local cfg = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.FashionAureole)[id]
    return cfg and cfg.EffectPath
end

function XFashionConfigs.GetFashionCfgById(id)
    return XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.Fashion)[id]
end

---
--- 获取涂装系列名称
function XFashionConfigs.GetSeriesName(id)
    local cfg = GetFashionSeriesConfig(id)
    if not cfg.Name then
        XLog.ErrorTableDataNotFound("XFashionConfigs.GetSeriesName",
        "涂装名称",
        TABLE_FASHION_SERIES,
        "Id",
        tostring(id))
        return ""
    end
    return cfg.Name
end

---@return XTableFashion
function XFashionConfigs.GetFashionTemplate(fashionId)
    local template = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.Fashion)[fashionId]
    if not template then
        XLog.ErrorTableDataNotFound("XFashionConfigs.GetFashionTemplate", 
                "Fashion", TABLE_FASHION_PATH, "Id", tostring(fashionId))
        return {}
    end
    return template
end 

---@return XTableFashion[]
function XFashionConfigs.GetFashionTemplates()
    return XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.Fashion)
end 

function XFashionConfigs.GetFashionLiberationEffectRootAndPath(fashionId)
    local template = XFashionConfigs.GetFashionTemplate(fashionId)
    
    local rootName, fxPath = template.EffectRootName, template.EffectPath
    
    if not rootName or not fxPath then
        XLog.ErrorTableDataNotFound("XFashionManager.GetFashionLiberationEffectRootAndPath", "EffectRootName/EffectPath", TABLE_FASHION_PATH, "Id", tostring(fashionId))
        return "", ""
    end
    return rootName, fxPath
end

--region 涂装音效相关
local function GetFashionVoiceCfgs()
    if not FashionVoiceConfig then
        FashionVoiceConfig = XTableManager.ReadByIntKey(TABLE_FASHION_VOICE_PATH, XTable.XTableFashionVoice, "FashionId")
    end
    
    return FashionVoiceConfig
end

local function GetFashionVoiceConfig(fashionId)
    local configs = GetFashionVoiceCfgs()
    
    return configs[fashionId]
end

function XFashionConfigs.GetFashionCueIdByFashionId(fashionId)
    local config = GetFashionVoiceConfig(fashionId)

    if not config then
        return
    end
    
    return config.CueId
end
--endregion