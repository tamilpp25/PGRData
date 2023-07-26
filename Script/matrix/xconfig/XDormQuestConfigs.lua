XDormQuestConfigs = XConfigCenter.CreateTableConfig(XDormQuestConfigs, "XDormQuestConfigs", "Dormitory/Quest")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XDormQuestConfigs.TableKey = enum({
    Quest = {}, -- 委托表
    QuestFile = {}, -- 委托文件表
    QuestTerminal = { ReadKeyName = "Lv" }, -- 终端控制表
    QuestAnnouncerDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 发布势力详情表
    QuestAttribDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 推荐属性详情表
    QuestQualityDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 委托等级详情表
    QuestTerminalDetail = { ReadKeyName = "Lv", DirType = XConfigCenter.DirectoryType.Client }, -- 委托终端详情表
    QuestTypeDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 委托类型详情表
    QuestFileDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 委托文件详情表
    QuestFileGroupDetail = { DirType = XConfigCenter.DirectoryType.Client }, -- 委托文件列表详情表
})

-- 升级状态
XDormQuestConfigs.TerminalUpgradeState = {
    Finish = 0, -- 已完成 
    OnGoing = 1,  -- 进行中
}

-- 终端队伍状态
XDormQuestConfigs.TerminalTeamState = {
    Dispatched = 1, -- 完成（可领取）
    Dispatching = 2, -- 派遣中
    Empty = -1, -- 空闲中
    Lock = -2, -- 未解锁
}

XDormQuestConfigs.UiGridQuestMoveMinX = XUiHelper.GetClientConfig("UiGridQuestMoveMinX", XUiHelper.ClientConfigType.Int)
XDormQuestConfigs.UiGridQuestMoveMaxX = XUiHelper.GetClientConfig("UiGridQuestMoveMaxX", XUiHelper.ClientConfigType.Int)
XDormQuestConfigs.UiGridQuestMoveTargetX = XUiHelper.GetClientConfig("UiGridQuestMoveTargetX", XUiHelper.ClientConfigType.Int)

local QuestFileGroupDic = {}
local QuestFileSubGroupDic = {}

local function InitQuestFileGroup()
    local questFileGroupConfig = XDormQuestConfigs.GetAllConfigs(XDormQuestConfigs.TableKey.QuestFileGroupDetail)
    for _, config in pairs(questFileGroupConfig) do
        if not XTool.IsNumberValid(config.ParentGroup) then
            table.insert(QuestFileGroupDic, config)
        else
            if not QuestFileSubGroupDic[config.ParentGroup] then
                QuestFileSubGroupDic[config.ParentGroup] = {}
            end
            table.insert(QuestFileSubGroupDic[config.ParentGroup], config)
        end
    end
    table.sort(QuestFileGroupDic, function(a, b)
        return a.Id < b.Id
    end)
end

function XDormQuestConfigs.Init()
    InitQuestFileGroup()
end

--region 推荐属性相关

-- 通过属性Id获取属性的图标
function XDormQuestConfigs.GetQuestAttribIconById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestAttribDetail, id)
    if not config then
        return ""
    end
    return config.Icon or ""
end

--endregion

--region 发布势力相关

function XDormQuestConfigs.GetQuestAnnouncerNameById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestAnnouncerDetail, id)
    if not config then
        return ""
    end
    return config.Name or ""
end

function XDormQuestConfigs.GetQuestAnnouncerIconById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestAnnouncerDetail, id)
    if not config then
        return ""
    end
    return config.Icon or ""
end

--endregion

--region 委托类型相关

function XDormQuestConfigs.GetQuestTypeIconById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestTypeDetail, id)
    if not config then
        return ""
    end
    return config.Icon or ""
end

--endregion

--region 委托等级相关

function XDormQuestConfigs.GetQuestQualityNameById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestQualityDetail, id)
    if not config then
        return ""
    end
    return config.Name or ""
end

function XDormQuestConfigs.GetQuestQualityColorById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestQualityDetail, id)
    if not config then
        return ""
    end
    return XUiHelper.Hexcolor2Color(config.Color)
end

function XDormQuestConfigs.GetQuestQualityIconById(id)
    local config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestQualityDetail, id)
    if not config then
        return ""
    end
    return config.Icon or ""
end

--endregion

--region 委托文件列表相关

function XDormQuestConfigs.GetQuestFileGroupDic()
    return QuestFileGroupDic
end

function XDormQuestConfigs.GetQuestFileSubGroupDic(id)
    return QuestFileSubGroupDic[id]
end
    
--endregion

