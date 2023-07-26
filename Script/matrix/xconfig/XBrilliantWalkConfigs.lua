local TABLE_ACTIVITY_PATH = "Share/Fuben/BrilliantWalk/BrilliantWalkActivity.tab" --玩法活动
local ActivityConfig = {}
local TABLE_CHAPTER_PATH = "Share/Fuben/BrilliantWalk/BrilliantWalkChapter.tab" --章节
local ChapterConfig = {}
local TABLE_STAGE_PATH = "Share/Fuben/BrilliantWalk/BrilliantWalkStage.tab" --关卡
local StageConfig = {}
local TABLE_BUILD_PLUGIN_PATH = "Share/Fuben/BrilliantWalk/BrilliantWalkBuildPlugin.tab" --改造零件
local BuildPluginConfig = {}
local TABLE_TRENCH_PATH = "Share/Fuben/BrilliantWalk/BrilliantWalkTrench.tab" --改造槽位
local TrenchConfig = {}
local TABLE_TASK_PATH = "Client/Fuben/BrilliantWalk/BrilliantWalkTask.tab" --改造槽位
local TaskConfig = {}
local TABLE_STAGE_CLIENT_PATH = "Client/Fuben/BrilliantWalk/BrilliantWalkStageClient.tab" --关卡客户端额外配置
local StageClientConfig = {}
local TABLE_ADDITIONAL_BUFF_PATH = "Client/Fuben/BrilliantWalk/BrilliantWalkAdditionalBuff.tab" --被动技能配置
local AdditionalBuffConfig = {}
local TABLE_ATTENTION_PATH = "Client/Fuben/BrilliantWalk/BrilliantWalkAttention.tab" --客户端显示注意事项
local AttentionConfig = {}

XBrilliantWalkConfigs = XBrilliantWalkConfigs or {}
XBrilliantWalkTrenchType = { --槽位类型 对应插件表的TrenchType C# enum BrilliantWalkTrenchType
    ['Logic'] = 1, --逻辑
    ['Ultimate'] = 2, --必杀
    ['Battle'] = 3, --武装
}
XBrilliantWalkBuildPluginType = { --插件类型 对应插件表的Type C# enum BrilliantWalkPluginType
    ['Module'] = 1, --模块
    ['Skill'] = 2, --技能
    ['Perk'] = 3, --技能补充组件
}
XBrilliantWalkStageType = { --关卡类型
    ['Main'] = 1, --主线关卡
    ['Sub'] = 2, --支线关卡
    ['Boss'] = 3, --BOSS关卡
    ['HardBoss'] = 4, --高难BOSS关卡
}
XBrilliantWalkStageModuleType = { --关卡使用模块类型
    ['Custom'] = 1, --使用自定义模块关卡
    ['Inherent'] = 2, --使用固有模块关卡
}
XBrilliantWalkTaskType = { --关卡使用模块类型
    ['Daily'] = 1, --每日任务
    ['Accumulative'] = 2, --累积任务
}
XBrilliantWalkCameraType = { --镜头类型
    ['Main'] = 1, --UiMain用
    ['Chapter'] = 2, --Chapter/ChapterStage/ChapterBoss用
    ['Equipment'] = 3, --Equipment界面使用
    ['Trench1'] = 4, --插槽1 Module界面使用
    ['Trench2'] = 5, --插槽2 Module界面使用
    ['Trench3'] = 6, --插槽3 Module界面使用
    ['Trench4'] = 7, --插槽4 Module界面使用
}
XBrilliantWalkBossChapterDifficult = { --Boss关难度设置
    Normal = 0,
    Hard = 1,
}
--插件系统： 一种插槽可以插入特定模块，一个模块可以插入特定技能，一个技能可以插入特定Perk。
XBrilliantWalkConfigs.ListModuleListInTrench = {}  --插槽对应的模块表 dict<TrenchType,List<PluginId>> PluginId的Type为Module
XBrilliantWalkConfigs.ListSkillListInModule = {} --模块对应的技能表 dict<PluginId1,List<PluginId2>> PluginId1的Type为Module PluginId2的Type为Skill
XBrilliantWalkConfigs.ListPerkListInSkill = {} --技能对应的Perk表 dict<PluginId1,List<PluginId2>> PluginId1的Type为Skill PluginId2的Type为Perk
XBrilliantWalkConfigs.DictNeedPluginTrench = {} --查找哪些模块被插槽依赖

XBrilliantWalkConfigs.StageIdToStageType = nil --关卡ID跟关卡类型的映射表
XBrilliantWalkConfigs.StageTypeNumber = nil --不同关卡种类的数量总数
XBrilliantWalkConfigs.PluginUnlockStage = nil --插件与其解锁关卡对照

function XBrilliantWalkConfigs.Init()
    ActivityConfig      = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH,        XTable.XTableBrilliantWalkActivity,     "Id")
    ChapterConfig       = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH,         XTable.XTableBrilliantWalkChapter,      "Id")
    StageConfig         = XTableManager.ReadByIntKey(TABLE_STAGE_PATH,           XTable.XTableBrilliantWalkStage,        "Id")
    BuildPluginConfig   = XTableManager.ReadByIntKey(TABLE_BUILD_PLUGIN_PATH,    XTable.XTableBrilliantWalkBuildPlugin,  "Id")
    TrenchConfig        = XTableManager.ReadByIntKey(TABLE_TRENCH_PATH,          XTable.XTableBrilliantWalkTrench,       "Id")
    TaskConfig          = XTableManager.ReadByIntKey(TABLE_TASK_PATH,            XTable.XTableBrilliantWalkTask,   "Id")
    StageClientConfig   = XTableManager.ReadByIntKey(TABLE_STAGE_CLIENT_PATH,    XTable.XTableBrilliantWalkStageClient,"Id")
    AdditionalBuffConfig= XTableManager.ReadByIntKey(TABLE_ADDITIONAL_BUFF_PATH, XTable.XTableBrilliantWalkAdditionalBuff,"Id")
    AttentionConfig     = XTableManager.ReadByIntKey(TABLE_ATTENTION_PATH,       XTable.XTableBrilliantWalkAttention,"Id")
    
    for id, config in pairs(BuildPluginConfig) do
        if config.Type == XBrilliantWalkBuildPluginType.Module then
            local list = XBrilliantWalkConfigs.ListModuleListInTrench
            if not list[config.TrenchType] then list[config.TrenchType] = {} end
            table.insert(list[config.TrenchType],id)
        elseif config.Type == XBrilliantWalkBuildPluginType.Skill then
            local list = XBrilliantWalkConfigs.ListSkillListInModule
            if not list[config.PrePluginId] then list[config.PrePluginId] = {} end
            table.insert(list[config.PrePluginId],id)
        elseif config.Type == XBrilliantWalkBuildPluginType.Perk then
            local list = XBrilliantWalkConfigs.ListPerkListInSkill
            if not list[config.PrePluginId] then list[config.PrePluginId] = {} end
            table.insert(list[config.PrePluginId],id)
        end
    end
    local sortFunc = function(a, b)
        return a < b
    end
    for k,list in pairs(XBrilliantWalkConfigs.ListModuleListInTrench) do
        table.sort(list, sortFunc)
    end
    for k,list in pairs(XBrilliantWalkConfigs.ListSkillListInModule) do
        table.sort(list, sortFunc)
    end
    for k,list in pairs(XBrilliantWalkConfigs.ListPerkListInSkill) do
        table.sort(list, sortFunc)
    end

    for id, config in pairs(TrenchConfig) do
        for _,pluginId in ipairs(config.NeedBuildPlugin) do
            if not XBrilliantWalkConfigs.DictNeedPluginTrench[pluginId] then
                XBrilliantWalkConfigs.DictNeedPluginTrench[pluginId] = {}
            end
            table.insert(XBrilliantWalkConfigs.DictNeedPluginTrench[pluginId],id)
        end
    end
end

-------------------------------
--desc: 获取活动数据
--return data : XTable.XTableBrilliantWalkActivity 
-------------------------------
function XBrilliantWalkConfigs.GetActivityConfig(activityId)
    --activityId = IsNumberValid(activityId) and activityId or DefaultActivityId
    local config = ActivityConfig[activityId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetActivityConfig error:配置不存在, activityId: " .. activityId .. ", 配置路径: " .. TABLE_ACTIVITY_PATH)
        return
    end
    return config
end

-------------------------------
--desc: 获取活动奖励数据
--return data : List<itemTemplateId>
-------------------------------
function XBrilliantWalkConfigs.GetActivityTaskReward(activityId)
    --activityId = IsNumberValid(activityId) and activityId or DefaultActivityId
    local config = ActivityConfig[activityId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetActivityConfig error:配置不存在, activityId: " .. activityId .. ", 配置路径: " .. TABLE_ACTIVITY_PATH)
        return
    end
    return config.TaskReward
end

-------------------------------
--desc: 获取活动开场动画数据
--return data : string
-------------------------------
function XBrilliantWalkConfigs.GetActivityStoryId(activityId)
    --activityId = IsNumberValid(activityId) and activityId or DefaultActivityId
    local config = ActivityConfig[activityId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetActivityConfig error:配置不存在, activityId: " .. activityId .. ", 配置路径: " .. TABLE_ACTIVITY_PATH)
        return nil
    end
    return config.StoryId
end


-------------------------------
--desc: 获取章节数据
--return data : XTable.XTableBrilliantWalkChapter 
-------------------------------
function XBrilliantWalkConfigs.GetChapterConfig(chapterId)
    local config = ChapterConfig[chapterId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetChapterConfig error:配置不存在, chapterId: " .. chapterId .. ", 配置路径: " .. TABLE_CHAPTER_PATH)
        return
    end
    return config
end

-------------------------------
--desc: 获取章节开放TimeId
--return int : TimeId
-------------------------------
function XBrilliantWalkConfigs.GetChapterTimeId(chapterId)
    local config = ChapterConfig[chapterId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetChapterConfig error:配置不存在, chapterId: " .. chapterId .. ", 配置路径: " .. TABLE_CHAPTER_PATH)
        return
    end
    return config.TimeId
end

-------------------------------
--desc: 获取所有关卡数据
--return data : XTable.XTableBrilliantWalkStage[]
-------------------------------
function XBrilliantWalkConfigs.GetStageConfigs()
   return StageConfig 
end

-------------------------------
--desc: 获取关卡数据
--return data : XTable.XTableBrilliantWalkStage 
-------------------------------
function XBrilliantWalkConfigs.GetStageConfig(stageId)
    local config = StageConfig[stageId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetStageConfig error:配置不存在, stageId: " .. stageId .. ", 配置路径: " .. TABLE_STAGE_PATH)
        return
    end
    return config
end

-------------------------------
--desc: 获取关卡客户端额外数据
--return data : XTable.XTableBrilliantWalkStageClient 
-------------------------------
function XBrilliantWalkConfigs.GetStageClientConfig(stageId)
    local config = StageClientConfig[stageId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetStageClientConfig error:配置不存在, stageId: " .. stageId .. ", 配置路径: " .. TABLE_STAGE_PATH)
        return
    end
    return config
end

-------------------------------
--desc: 获取插件数据
--return data : XTable.XTableBrilliantWalkBuildPlugin 
-------------------------------
function XBrilliantWalkConfigs.GetBuildPluginConfig(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginConfig error:配置不存在, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return
    end
    return config
end

-------------------------------
--desc: 获取插件名字
--return name:string
-------------------------------
function XBrilliantWalkConfigs.GetBuildPluginName(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginConfig error:配置不存在, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return
    end
    return config.Name
end

-------------------------------
--desc: 获取插件类型
--return type:XBrilliantWalkBuildPluginType
-------------------------------
function XBrilliantWalkConfigs.GetBuildPluginType(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginConfig error:配置不存在, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return
    end
    return config.Type
end

-------------------------------
--desc: 获取插件的前置插件
--return id:int
-------------------------------
function XBrilliantWalkConfigs.GetBuildPluginPrePluginId(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginConfig error:配置不存在, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return
    end
    return config.PrePluginId
end

-------------------------------
--desc: 获取插件使用所需能量
--return energy : int
-------------------------------
function XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config or not config.NeedEnergy then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginNeedEnergy error:配置不存在或者该插件没有配置能量, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return 0
    end
    return config.NeedEnergy
end

-------------------------------
--desc: 获取插件的父插件树(无法追寻到槽位ID)
--return data : [parent1,parent2,...] 假设传入的是perk 那parent1是所属skill parent2是所属module
-------------------------------
function XBrilliantWalkConfigs.GetPluginRoots(buildPluginId)
    local root = {}
    local config = BuildPluginConfig[buildPluginId]
    while config and config.PrePluginId and config.PrePluginId > 0 do
        table.insert(root,config.PrePluginId)
        config = BuildPluginConfig[config.PrePluginId]
    end
    return root
end

-------------------------------
--desc: 获取插件的插槽类型
--return data : [parent1,parent2,...] 假设传入的是perk 那parent1是所属skill parent2是所属module parent3是所属模块
-------------------------------
function XBrilliantWalkConfigs.GetPluginTrenchType(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config or not config.TrenchType then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginNeedEnergy error:配置不存在或者该插件没有配置能量, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return 0
    end
    return config.TrenchType
end

-------------------------------
--desc: 获取插件对应的道具id
--return itemId : int
-------------------------------
function XBrilliantWalkConfigs.GetBuildPluginItemId(buildPluginId)
    local config = BuildPluginConfig[buildPluginId]
    if not config or not config.NeedEnergy then
        XLog.Error("XBrilliantWalkConfigs GetBuildPluginNeedEnergy error:配置不存在或者该插件没有配置能量, buildPluginId: " .. buildPluginId .. ", 配置路径: " .. TABLE_BUILD_PLUGIN_PATH)
        return 0
    end
    return config.ItemId
end

-------------------------------
--desc: 获取槽位数据(换入 槽位编号)
--return data : XTable.XTableBrilliantWalkTrench 
-------------------------------
function XBrilliantWalkConfigs.GetTrenchConfigs()
    return TrenchConfig
end
function XBrilliantWalkConfigs.GetTrenchConfig(trenchIndex)
    local config = TrenchConfig[trenchIndex]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetTrenchConfig error:配置不存在, trenchId: " .. trenchIndex .. ", 配置路径: " .. TABLE_TRENCH_PATH)
        return
    end
    return config
end

-------------------------------
--desc: 获取插槽名字
--return name : string
-------------------------------
function XBrilliantWalkConfigs.GetTrenchName(trenchIndex)
    local config = TrenchConfig[trenchIndex]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetTrenchConfig error:配置不存在, trenchId: " .. trenchIndex .. ", 配置路径: " .. TABLE_TRENCH_PATH)
        return
    end
    return config.Name
end

-------------------------------
--desc: 获取插槽类型
--return type : XBrilliantWalkTrenchType
-------------------------------
function XBrilliantWalkConfigs.GetTrenchType(trenchIndex)
    local config = TrenchConfig[trenchIndex]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetTrenchConfig error:配置不存在, trenchId: " .. trenchIndex .. ", 配置路径: " .. TABLE_TRENCH_PATH)
        return
    end
    return config.TrenchType
end

-------------------------------
--desc: 获取插槽需要的前置插件
--return pluginId[]
-------------------------------
function XBrilliantWalkConfigs.GetTrenchNeedBuildPlugin(trenchIndex)
    local config = TrenchConfig[trenchIndex]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetTrenchConfig error:配置不存在, trenchId: " .. trenchIndex .. ", 配置路径: " .. TABLE_TRENCH_PATH)
        return
    end
    return config.NeedBuildPlugin
end

-------------------------------
--desc: 获取被动BUFF显示数据
--return data : XTable.XTableBrilliantWalkAdditionalBuff 
-------------------------------
function XBrilliantWalkConfigs.GetAdditionalBuffConfigs()
    return AdditionalBuffConfig
end

-------------------------------
--desc: 根据关卡ID获取关卡类型
--return XBrilliantWalkStageType
-------------------------------
local GetStageTypeError = function(stageId)
    XLog.Error("Error! Doesnt Exist StageId:" .. stageId .. " Please Check Servers And Clients BrilliantWalkConfigs.")
    return 1
end
function XBrilliantWalkConfigs.GetStageType(stageId)
    --初始化映射表
    if not XBrilliantWalkConfigs.StageIdToStageType then
        XBrilliantWalkConfigs.StageIdToStageType = {}
        for cId, config in pairs(ChapterConfig) do
            local stageType = 1
            if config.Type == 2 then
                stageType = 3
            end
            if config.MainStageIds and #config.MainStageIds > 0 then
                for _,sId in pairs(config.MainStageIds) do
                    XBrilliantWalkConfigs.StageIdToStageType[sId] = stageType
                end
            end
            if config.MainStageIds and #config.SideStageIds > 0 then
                for _,sId in pairs(config.SideStageIds) do
                    XBrilliantWalkConfigs.StageIdToStageType[sId] = (stageType + 1)
                end
            end
        end
    end
    return XBrilliantWalkConfigs.StageIdToStageType[stageId] or GetStageTypeError(stageId)
end

-------------------------------
--desc: 根据关卡类型 获取关卡总数 (传入XBrilliantWalkStageType)
--return number
-------------------------------
function XBrilliantWalkConfigs.GetStageNumberByType(type)
    --初始化映射表
    if not XBrilliantWalkConfigs.StageTypeNumber then
        XBrilliantWalkConfigs.StageTypeNumber = {0,0,0,0}
        for cId, config in pairs(ChapterConfig) do
            local stageType = 1
            if config.Type == 2 then
                stageType = 3
            end
            if config.MainStageIds and #config.MainStageIds > 0 then
                for _,sId in pairs(config.MainStageIds) do
                    XBrilliantWalkConfigs.StageTypeNumber[stageType] = XBrilliantWalkConfigs.StageTypeNumber[stageType] +1
                end
            end
            if config.SideStageIds and #config.SideStageIds > 0 then
                for _,sId in pairs(config.SideStageIds) do
                    XBrilliantWalkConfigs.StageTypeNumber[stageType+1] = XBrilliantWalkConfigs.StageTypeNumber[stageType+1] +1
                end
            end
        end
    end
    return XBrilliantWalkConfigs.StageTypeNumber[type]
end

-------------------------------
--desc: 根据插件ID 获取解锁关卡ID
--return stageId
-------------------------------
function XBrilliantWalkConfigs.GetPluginUnlockStage(pluginId)
    if not XBrilliantWalkConfigs.PluginUnlockStage then
        XBrilliantWalkConfigs.PluginUnlockStage = {}
        for sId, config in pairs(StageConfig) do
            for index,pluginId in ipairs(config.UnlockPlugin) do
                XBrilliantWalkConfigs.PluginUnlockStage[pluginId] = config.Id
            end
        end
    end
    return XBrilliantWalkConfigs.PluginUnlockStage[pluginId]
end


-------------------------------
--desc: 获取所有任务数据
--return data : List<XTableBrilliantWalkTask>
-------------------------------
function XBrilliantWalkConfigs.GetTaskConfigs()
    return TaskConfig
end
-------------------------------
--desc: 获取任务类型获取任务数据
--return data : List<taskId>
-------------------------------
function XBrilliantWalkConfigs.GetTaskListByType(taskType)
    local taskList = {}
    for _,config in ipairs(TaskConfig) do
        if config.Type == taskType then
            taskList = config.TaskId
        end
    end
    return taskList
end
-------------------------------
--desc: 获取任注意事项
--return data : List<taskId>
-------------------------------
function XBrilliantWalkConfigs.GetAttentionConfig(stageId)
    local config = AttentionConfig[stageId]
    if not config then
        XLog.Error("XBrilliantWalkConfigs GetAttentionConfig error:配置不存在, stageId: " .. stageId .. ", 配置路径: " .. TABLE_ATTENTION_PATH)
        return
    end
    return config
end