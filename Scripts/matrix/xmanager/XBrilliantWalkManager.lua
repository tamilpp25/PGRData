local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
--光辉同行玩法 操作机器人大战三百回合
XBrilliantWalkManagerCreator = function()
    local XBrilliantWalkManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.BrilliantWalk, "BrilliantWalkManager")
    --初始化UI配置
    XBrilliantWalkManager.UiGridChapterMoveMinX = CS.XGame.ClientConfig:GetInt("BrilliantWalkStageChapterGridMoveMinX")
    XBrilliantWalkManager.UiGridChapterMoveMaxX = CS.XGame.ClientConfig:GetInt("BrilliantWalkStageChapterGridMoveMaxX")
    XBrilliantWalkManager.UiGridChapterMoveTargetX = CS.XGame.ClientConfig:GetInt("BrilliantWalkStageChapterGridMoveTargetX")
    XBrilliantWalkManager.UiGridChapterMoveDuration = CS.XGame.ClientConfig:GetFloat("BrilliantWalkStageChapterGridMoveDuration")

    XBrilliantWalkManager.UiGridBossChapterMoveMinX = CS.XGame.ClientConfig:GetInt("BrilliantWalkStageBossChapterGridMoveMinX")
    XBrilliantWalkManager.UiGridBossChapterMoveMaxX = CS.XGame.ClientConfig:GetInt("BrilliantWalkStageBossChapterGridMoveMaxX")
    XBrilliantWalkManager.UiGridBossChapterMoveTargetX = CS.XGame.ClientConfig:GetInt("BrilliantWalkStageBossChapterGridMoveTargetX")
    XBrilliantWalkManager.UiGridBossChapterMoveDuration = CS.XGame.ClientConfig:GetFloat("BrilliantWalkStageBossChapterGridMoveDuration")
    
    local METHOD_NAME = { --请求协议
        PreFight = "PreFightRequest",
        BrilliantWalkBuildPluginRequest = "BrilliantWalkBuildPluginRequest", --请求修改模块配件
    }
    local LOCAL_STROAGE = { --本地持久化Key(持久化数据跟着活动ID走 更换活动ID时 清空数据)
        ActivityId = "BrilliantWalkActivityId", --当前持久化数据的活动ID
        PluginData = "BrilliantWalkPluginData", --插件模板
        FirstOpened = "BrilliantWalkFirstOpened", --已经打开过玩法
        PlayedFirstMovie = "BrilliantWalkPlayedFirstMovie", --已经播放过开场动画
        SkillPerkSetData = "BrilliantWalkSkillPerkSetData", --Perk设置缓存
        NewPluginRedData = "BrilliantWalkNewPluginRedData", --新插件红点缓存
    }
    local _CurActivityId --当前活动ID
    local ChapterList = {} --当前活动章节列表 
    local ChapterUnlockDict = {} --解锁的章节
    local PassChapterDict = {} --通过的章节
    local MainChapterList = {} --当前活动主线章节列表
    local BossChapterList = {} --当前活动Boss章节列表(每次活动仅有一个BOSS章节)
    local BossStageSettleData --Boss关卡结算数据缓存
    local PassStageDict = {} --通过的关卡
    local StageMaxScore = {} --关卡的最高评分
    local PassStageTypeNumber = {} --不同类型关卡的通关数量
    -------------------------------
    --desc: 当前玩家装配的模块数据 其他以PluginData命名的数据也要遵循此格式
    --PluginData : {
    --      [TrenchId] : {
    --          [PluginId](Module): {
    --              [PluginId](Skill): perkid
    --          }
    --      }
    --}
    -- TrenchId Module Skill为空即无激活 perkid为0时则无激活
    -------------------------------
    local CurPluginData = {} --当前玩家装配的模块数据(不与服务器同步 玩家作修改时并不立刻与服务器同步 所以分成两个数据)
    local ServerPluginData = {} --当前玩家装配的模块数据(与服务器同步)--常量
    local UnlockPlugin = {} --key为已经解锁的pluginId
    local ViewedUnlockPlugin = nil --key为已经查阅过的pluginId
    local LastSkillPerkSet = {} --上一次操作的技能Perk配置(策划需求，当激活技能时，默认选择上一次激活此技能时选择的Perk)
    local PluginMaxEnergy = 0
    
    local UiBossChapterDifficultCahce = XBrilliantWalkBossChapterDifficult.Normal
    
    --region 本地持久化数据
    --检查当前Activity下的缓存合法性
    local function LocalStroageCheckActivityCache()
        local oldAId = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.ActivityId)) or nil
        if oldAId == nil or oldAId == _CurActivityId then
            return
        end
        LocalStroageClearData()
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.ActivityId),_CurActivityId)
    end
    --清空该玩法缓存
    local function LocalStroageClearData()
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.PluginData))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.FirstOpened))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.PlayedFirstMovie))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.SkillPerkSetData))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.NewPluginRedData))
    end
    --保存初次打开
    local function LocalStroageSaveFirstOpened()
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.FirstOpened),true)
    end
    --读取初次打开
    local function LocalStroageLoadFirstOpened()
        return XSaveTool.GetData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.FirstOpened)) or false
    end
    --保存开场电影播放
    local function LocalStroageSavePlayedFirstMovie()
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.PlayedFirstMovie),true)
    end
    --读取开场电影播放
    local function LocalStroageLoadPlayedFirstMovie()
        return XSaveTool.GetData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.PlayedFirstMovie)) or false
    end
    --保存插件配置
    local function LocalStroageSavePluginData(pluginData)
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.PluginData),pluginData)
        XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_CHANGE)
    end
    --读取插件配置
    local function LocalStroageLoadPluginData()
        return XSaveTool.GetData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.PluginData)) or nil
    end
    --保存技能Perk配置
    local function LocalStroageSaveSkillPerkSetData(skillPerkSetData)
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.SkillPerkSetData),skillPerkSetData)
    end
    --读取技能Perk配置
    local function LocalStroageLoadSkillPerkSetData()
        return XSaveTool.GetData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.SkillPerkSetData)) or {}
    end
    --保存新插件红点数据
    local function LocalStroageSaveNewPluginRedData(newPluginRedData)
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.NewPluginRedData),newPluginRedData)
    end
    --读取新插件红点数据
    local function LocalStroageLoadNewPluginRedData()
        return XSaveTool.GetData(string.format("%d%s", XPlayer.Id, LOCAL_STROAGE.NewPluginRedData)) or {}
    end
    --endregion

    --region 数据转换
    --------------------------------------
    --serverPluginData = { 
    --    List<TrenchInfo> BuildTrench 
    --}
    --TrenchInfo = {
    --    int TrenchId;
    --    public List<int> PluginList;
    --}
    --------------------------------------
    --pluginData 数据结构请看文件顶部
    -- 插件本地内存数据格式 和 服务器数据格式相互转换 begin
    local function ServerPlugInData2PlugInData(serverPluginData)
        local pluginData = {}
        local function GetModuleData(trench,config)
            local pluginId = config.Id
            if not pluginData[trench][pluginId] then pluginData[trench][pluginId] = {} end
            return pluginData[trench][pluginId]
        end
        local function GetSkillData(trench,config)
            local pluginId = config.Id
            local moduleId = config.PrePluginId
            local moduleConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(moduleId)
            local data = GetModuleData(trench,moduleConfig)
            if not data[pluginId] then data[pluginId] = 0 end
            return data
        end
        local function GetPerkData(trench,config) 
            local pluginId = config.Id
            local skillId = config.PrePluginId
            local skillConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(skillId)
            local data = GetSkillData(trench,skillConfig)
            data[skillId] = pluginId
        end
        for _, trenchInfo in ipairs(serverPluginData) do
            local trench = trenchInfo.TrenchId
            if not pluginData[trench] then pluginData[trench] = {} end
            for i, pluginId in ipairs(trenchInfo.PluginList) do
                local config = XBrilliantWalkConfigs.GetBuildPluginConfig(pluginId)
                if config.Type == XBrilliantWalkBuildPluginType.Module then
                    GetModuleData(trench,config)
                elseif config.Type == XBrilliantWalkBuildPluginType.Skill then
                    GetSkillData(trench,config)
                elseif config.Type == XBrilliantWalkBuildPluginType.Perk then
                    GetPerkData(trench,config)
                end
            end
        end
        return pluginData
    end
    local function PlugInData2ServerPlugInData(pluginData)
        local serverPluginData = {}
        for trench, modules in pairs(pluginData) do
            local trenchInfo = {}
            trenchInfo.TrenchId = trench
            table.insert(serverPluginData,trenchInfo)
            local trenchPluginData = {}
            trenchInfo.PluginList = trenchPluginData
            for moduleId, skills in pairs(modules) do
                table.insert(trenchPluginData,moduleId)
                for skillId, perkId in pairs(skills) do
                    table.insert(trenchPluginData,skillId)
                    if perkId ~= 0 then
                        table.insert(trenchPluginData,perkId)
                    end
                end
            end
        end
        return serverPluginData
    end
    -- 插件本地内存数据格式 和 服务器数据格式相互转换 end
    -- 插件数据 转换成 已装备插件列表 dict<EquipedPluginId,true>
    local function PlugInData2EquipPluginDict(pluginData)
        local ListPluginIds = {}
        for trenchId, modules in pairs(pluginData) do
            for moduleId, skills in pairs(modules) do
                ListPluginIds[moduleId] = ListPluginIds[moduleId] or {}
                ListPluginIds[moduleId][trenchId] = true
                for skillId, perkId in pairs(skills) do
                    ListPluginIds[skillId] = ListPluginIds[skillId] or {}
                    ListPluginIds[skillId][trenchId] = true
                    if perkId ~= 0 then
                        ListPluginIds[perkId] = ListPluginIds[perkId] or {}
                        ListPluginIds[perkId][trenchId] = true
                    end
                end
            end
        end
        return ListPluginIds
    end
    --endregion

    --region 活动开放
    --活动是否开启
    function XBrilliantWalkManager.IsOpen()
        if not XTool.IsNumberValid(_CurActivityId) or _CurActivityId == 0 then return false end
        local timeId = XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).TimeId
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end
    --获取开始时间
    function XBrilliantWalkManager.GetActivityStartTime()
        if not XTool.IsNumberValid(_CurActivityId) or _CurActivityId == 0 then return 0 end
        local timeId = XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).TimeId
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end
    --获取结束时间
    function XBrilliantWalkManager.GetActivityEndTime()
        if not XTool.IsNumberValid(_CurActivityId) or _CurActivityId == 0 then return 0 end
        local timeId = XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).TimeId
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end
    --获取当前剩余时间
    function XBrilliantWalkManager.GetActivityRunningTimeStr()
        if not XTool.IsNumberValid(_CurActivityId) or _CurActivityId == 0 then return "" end
        local timeId = XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).TimeId
        local startTime = XFunctionManager.GetStartTimeByTimeId(timeId) or 0
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId) or 0
        local nowTime = XTime.GetServerNowTimestamp()
        if startTime and endTime and nowTime >= startTime and nowTime <= endTime then
            return XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.ACTIVITY)
        end
        return ""
    end
    --获取当前活动Id
    function XBrilliantWalkManager.Get_CurActivityId()
        return _CurActivityId
    end
    --后端通知活动结束 但现在还没有相关协议 先放置接口
    function XBrilliantWalkManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end
    --endregion

    --region 副本入口扩展
    function XBrilliantWalkManager:ExOpenMainUi()
        --功能开启
        if not XFunctionManager.DetectionFunction(self:ExGetFunctionNameType())then
            return
        end
        --活动开放
        if not XBrilliantWalkManager.IsOpen() then
            XUiManager.TipMsg(XUiHelper.GetText("BrilliantWalkActivityNotOpen"))
            return
        end
        if LocalStroageLoadFirstOpened() then
            XLuaUiManager.Open("UiBrilliantWalkMain")
            return
        end
        if LocalStroageLoadPlayedFirstMovie() then
            LocalStroageSaveFirstOpened()
            XLuaUiManager.Open("UiBrilliantWalkMain")
            return
        end
        local movieId = XBrilliantWalkConfigs.GetActivityStoryId(_CurActivityId)
        if movieId == nil then
            LocalStroageSaveFirstOpened()
            LocalStroageSavePlayedFirstMovie()
            XLuaUiManager.Open("UiBrilliantWalkMain")
        end
        XDataCenter.MovieManager.PlayMovie(movieId,function()
            LocalStroageSaveFirstOpened()
            LocalStroageSavePlayedFirstMovie()
            XLuaUiManager.Open("UiBrilliantWalkMain")
        end,nil,nil,false)
    end
    function XBrilliantWalkManager:ExGetFunctionNameType()
        return XFunctionManager.FunctionName.FubenBrilliantWalk
    end
    --endregion
    
    --region 数据
    --同步机体插件装配数据
    local function SynchronizePluginData()
        CurPluginData = XTool.Clone(ServerPluginData)
    end
    --初始化游戏数据
    local DEBUG_NOTIFY_DATA = false
    function XBrilliantWalkManager.NotifyBrilliantWalkData(notifyData)
        if notifyData.ActivityId == 0 then
            _CurActivityId = notifyData.ActivityId
            return
        end
        --初始化活动数据
        if not (_CurActivityId == notifyData.ActivityId) then
            _CurActivityId = notifyData.ActivityId
            ChapterList = XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).ChapterIds
            MainChapterList = {} --当前活动主线章节列表
            BossChapterList = {} --当前活动Boss章节列表
            for _,chapterId in pairs(ChapterList) do
                local chapterConfig = XBrilliantWalkConfigs.GetChapterConfig(chapterId)
                if chapterConfig.Type == 1 then
                    table.insert(MainChapterList,chapterId)
                else
                    table.insert(BossChapterList,chapterId)
                end
            end
            LocalStroageCheckActivityCache()
        end
        --章节进度
        PassChapterDict = {}
        ChapterUnlockDict = {}
        for _,chapterId in pairs(notifyData.PassChapters) do
            PassChapterDict[chapterId] = true
        end
        for index,chapterId in pairs(ChapterList) do
            if index == 1 then --如果是第一章节 则直接解锁
                ChapterUnlockDict[chapterId] = true
            else
                if PassChapterDict[ChapterList[index - 1]] then --如果已经通关上一章节，则解锁。
                    ChapterUnlockDict[chapterId] = true
                else --否则记录解锁章节id
                    ChapterUnlockDict[chapterId] = ChapterList[index - 1]
                end
            end
        end
        --关卡进度
        PassStageDict = {}
        PassStageTypeNumber = {0,0,0,0}
        for _,stageData in pairs(notifyData.PassStages) do
            local stageId = stageData.StageId
            local type = XBrilliantWalkConfigs.GetStageType(stageId)
            PassStageDict[stageId] = true
            StageMaxScore[stageId] = stageData.MaxScore
            PassStageTypeNumber[type] = PassStageTypeNumber[type] + 1
        end
        --初始化最大能量
        PluginMaxEnergy = CS.XGame.Config:GetInt("BrilliantWalkInitEnergy") + notifyData.AddEnergy
        --初始化插件同步数据
        ServerPluginData = ServerPlugInData2PlugInData(notifyData.BuildTrench)
        --初始化插件解锁列表
        local initPluginList = XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).InitPlugin
        for _,v in ipairs(initPluginList) do
            UnlockPlugin[v] = true
        end
        for _,v in ipairs(notifyData.UnlockPlugin) do
            UnlockPlugin[v] = true
        end
        XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_ON_PLUGIN_UNLOCK_STATE)
        --初始化插件数据本地缓存，如果数据不可用，则使用同步数据
        CurPluginData = LocalStroageLoadPluginData()
        if not CurPluginData or not XDataCenter.BrilliantWalkManager.CheckPluginDataValuable(CurPluginData) then
            SynchronizePluginData()
        end
        --初始化技能Perk配置本地缓存
        LastSkillPerkSet = LocalStroageLoadSkillPerkSetData()
        if DEBUG_NOTIFY_DATA then
            XLog.Error("NotifyBrilliantWalkData")
            XLog.Error("RawData:" , notifyData)
            XLog.Error("_CurActivityId:" .. _CurActivityId)
            XLog.Error("PassChapterDict:" , PassChapterDict)
            XLog.Error("ChapterUnlockDict:" , ChapterUnlockDict)
            XLog.Error("PassStageDict:" , PassStageDict)
            XLog.Error("PassStageTypeNumber:" , PassStageTypeNumber)
            XLog.Error("PluginMaxEnergy:" , PluginMaxEnergy)
            XLog.Error("UnlockPlugin:" , UnlockPlugin)
            XLog.Error("CurPluginData:" , CurPluginData)
        end
    end
    --检查槽位是否解锁
    function XBrilliantWalkManager.CheckTrenchUnlock(Trench)
        local trenchConfig = XBrilliantWalkConfigs.GetTrenchConfig(Trench)
        --检查 是否在解锁模块后解锁插槽 条件之间是or关系
        local needUnlock = true
        if #trenchConfig.NeedUnlockPlugin > 0 then
            needUnlock = false
            for _,unlockPluginId in ipairs(trenchConfig.NeedUnlockPlugin) do
                if XBrilliantWalkManager.CheckPluginUnlock(unlockPluginId) then
                    needUnlock = true
                    break
                end
            end
        end
        --检查 是否在装备模块后解锁插槽 条件之间是or关系
        local needBuild = true
        if #trenchConfig.NeedBuildPlugin > 0 then
            needBuild = false
            local pluginEquipedDict = PlugInData2EquipPluginDict(CurPluginData)
            for _,needEquipedPluginId in ipairs(trenchConfig.NeedBuildPlugin) do
                if pluginEquipedDict[needEquipedPluginId] then
                    needBuild = true
                    break
                end
            end
        end
        return needUnlock and needBuild;
    end
    --检查某个配件ID 是否已经解锁
    function XBrilliantWalkManager.CheckPluginUnlock(pluginId)
        return UnlockPlugin[pluginId] or false
    end
    --检查某个配件ID 是否装备
    function XBrilliantWalkManager.CheckPluginEquiped(pluginId)
        local equipPluginDict = PlugInData2EquipPluginDict(CurPluginData)
        return equipPluginDict[pluginId] or false
    end
    --检查某个配件ID 是否装备在指定插槽上
    function XBrilliantWalkManager.CheckPluginEquipedInTrench(trenchId, pluginId)
        local equipPluginDict = PlugInData2EquipPluginDict(CurPluginData)
        return equipPluginDict[pluginId] and equipPluginDict[pluginId][trenchId] or false
    end
    --获取插槽装备的模块ID
    function XBrilliantWalkManager.CheckTrenchEquipModule(trenchId)
        if not CurPluginData[trenchId] then
            return nil
        end
        for moduleId,skillData in pairs(CurPluginData[trenchId]) do
            return moduleId
        end
    end
    --获取指定插件的子插件安装情况 返回nil即搜索的插件本身没安装 搜索无效
    function XBrilliantWalkManager.GetPluginInstallInfo(trenchId, pluginId)
        if not XBrilliantWalkManager.CheckPluginEquipedInTrench(trenchId,pluginId) then return nil end
        local roots = XBrilliantWalkConfigs.GetPluginRoots(pluginId)
        local subPluginsInfo = CurPluginData[trenchId]
        while #roots > 0 do
            subPluginsInfo = subPluginsInfo[roots[#roots]]
            table.remove(roots,#roots)
        end
        return subPluginsInfo[pluginId]
    end
    --获取已经装备的所有技能ID
    function XBrilliantWalkManager.GetAllEquipedSkillId()
        local pulginEquipedDict = PlugInData2EquipPluginDict(CurPluginData)
        local equipedSkills = {}
        for pluginId,trenchIds in pairs(pulginEquipedDict) do
            local config = XBrilliantWalkConfigs.GetBuildPluginConfig(pluginId)
            if config.Type == XBrilliantWalkBuildPluginType.Skill then
                for trenchId,_ in pairs(trenchIds) do
                    table.insert(equipedSkills,{trenchId,pluginId})
                end
            end
        end
        return equipedSkills
    end
    --检查装备上的Module是否有激活的Skill
    function XBrilliantWalkManager.CheckModuleActiveSkill(trenchId,moduleId)
        local pluginType = XBrilliantWalkConfigs.GetBuildPluginType(moduleId)
        if not pluginType == XBrilliantWalkBuildPluginType.Module then
            XLog.Error("Plugin " .. moduleId .." isn't a Module")
        end
        if not (CurPluginData[trenchId] and CurPluginData[trenchId][moduleId]) then return false end
        if next(CurPluginData[trenchId][moduleId]) == nil  then return false end
        return true
    end
    --获取现在使用插件所使用的能量值
    function XBrilliantWalkManager.GetCurPluginEnergy()
        local pulginEquipedDict = PlugInData2EquipPluginDict(CurPluginData)
        local energy = 0
        for pluginId,trenchIds in pairs(pulginEquipedDict) do
            for trenchId,_ in pairs(trenchIds) do
                energy = energy + XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(pluginId)
            end
        end
        return energy
    end
    --传入插件列表 获取使用能量值总和
    function XBrilliantWalkManager.GetCustomPluginEnergy(plugins)
        local energy = 0
        for i,pluginId in pairs(plugins) do
            energy = energy + XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(pluginId)
        end
        return energy
    end
    --获取插件可用最大能量值
    function XBrilliantWalkManager.GetPluginMaxEnergy()
        return PluginMaxEnergy
    end
    --检查部件装配数据是否可用(查询是否非法数据)
    function XBrilliantWalkManager.CheckPluginDataValuable(pluginData)
        --检查装配的配件 有没有没解锁的
        for trench, modules in pairs(pluginData) do
            for moduleId, skills in pairs(modules) do
                if not XBrilliantWalkManager.CheckPluginUnlock(moduleId) then return false end
                for skillId, perkId in pairs(skills) do
                    if not XBrilliantWalkManager.CheckPluginUnlock(skillId) then return false end
                    if not perkId == 0 and not XBrilliantWalkManager.CheckPluginUnlock(perkId) then return false end
                end
            end
        end
        return true
    end
    --获取技能Perk缓存配置
    function XBrilliantWalkManager.GetSkillPerkSetData(skillId)
        return LastSkillPerkSet and LastSkillPerkSet[skillId] or nil
    end
    --获取关卡解锁情况　and 关系
    function XBrilliantWalkManager.GetStageUnlockData(stageId)
        local perStages = XFubenConfigs.GetPreStageId(stageId)
        local isUnLock = true
        if #perStages > 0 then
            for i=1,#perStages do
                if not (PassStageDict[perStages[i]] == true) then
                    isUnLock = false
                end
            end
        end
        --XLog.Error("CheckPluginDataValuable",stageId,isUnLock,perStages)
        return isUnLock,perStages
    end
    --检查关卡是否动画类别(并非副本类别)
    function XBrilliantWalkManager.CheckStageIsMovieStage(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
            return true
        end
        return false
    end
    --获取关卡的评分等级
    function XBrilliantWalkManager.GetStageScoreRank(stageId, score)
        if score <= 0 then return 1 end
        local config = XBrilliantWalkConfigs.GetStageClientConfig(stageId)
        if not config then
            return 1
        end
        for rank,scoreLine in ipairs(config.ScoreRank) do
            if score < scoreLine then
                if rank == 1 then return 1 end
                return rank - 1
            end
        end
        return #config.ScoreRank
    end
    --获取所有任务数据
    function XBrilliantWalkManager.GetAllTaskData()
        local taskDatas = {}
        local taskConfigs = XBrilliantWalkConfigs.GetTaskConfigs()
        for _,config in ipairs(taskConfigs) do
            for _, taskId in pairs(config.TaskId) do
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
                if taskData then
                    table.insert(taskDatas, taskData)
                end
            end
        end
        return taskDatas
    end
    --获取章节是否开放
    function XBrilliantWalkManager.GetChapterIsOpen(chpaterId)
        local timeId = XBrilliantWalkConfigs.GetChapterTimeId(chpaterId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end
    --获取章节开放时间
    function XBrilliantWalkManager.GetChapterStartTime(chpaterId)
        local timeId = XBrilliantWalkConfigs.GetChapterTimeId(chpaterId)
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end
    --获取章节开放描述
    function XBrilliantWalkManager.GetChapterOpenTimeMsg(chpaterId)
        local timeStamp = XBrilliantWalkManager.GetChapterStartTime(chpaterId) - XTime.GetServerNowTimestamp()
        local dataTime = XUiHelper.GetTime(timeStamp)
        return CS.XTextManager.GetText("BrilliantWalkChapterTime",dataTime)
    end
    --获取章节是否解锁
    function XBrilliantWalkManager.CheckChapterIsUnlock(chpaterId)
        if not XBrilliantWalkManager.GetChapterIsOpen(chpaterId) then return false end
        return ChapterUnlockDict[chpaterId]
    end
    --endregion
    
    --region 获取界面数据 和 跨界面操作
    --设置光辉同行主界面(处于一个策划需求，当玩家第一次打第一关并且胜利时 回到主界面时 会回到主页而不是回到关卡选择 应该是做新手指引用的)
    local CleanUiMainCache
    function XBrilliantWalkManager.SetUiMainClearCache()
        CleanUiMainCache = true
    end
    function XBrilliantWalkManager.GetUiMainClearCache()
        if CleanUiMainCache then
            CleanUiMainCache = false
            return true
        end
        return false
    end
    --光辉同行主界面
    function XBrilliantWalkManager.GetUiDataMain()
        local UiDataMain = {
            BossStageProcess = PassStageTypeNumber[XBrilliantWalkStageType.Boss], --头目关卡主线进度
            MaxBossStageProcess = XBrilliantWalkConfigs.GetStageNumberByType(XBrilliantWalkStageType.Boss),
            BossHardStageProcess = PassStageTypeNumber[XBrilliantWalkStageType.HardBoss], --头目关卡支线进度
            MaxBossHardStageProcess = XBrilliantWalkConfigs.GetStageNumberByType(XBrilliantWalkStageType.HardBoss),
            BossChapterId = BossChapterList[1], --Boss章节的id
            IsBossChapterUnlock = XBrilliantWalkManager.CheckChapterIsUnlock(BossChapterList[1]), --Boss章节是否开锁
            MainStageProcess = PassStageTypeNumber[XBrilliantWalkStageType.Main], --普通关卡主线进度
            MaxMainStageProcess = XBrilliantWalkConfigs.GetStageNumberByType(XBrilliantWalkStageType.Main),
            SubStageProcess = PassStageTypeNumber[XBrilliantWalkStageType.Sub], --普通关卡支线进度
            MaxSubStageProcess = XBrilliantWalkConfigs.GetStageNumberByType(XBrilliantWalkStageType.Sub),
            ActivityTime = XDataCenter.BrilliantWalkManager.GetActivityRunningTimeStr(),
            TaskRewardProgress = 0, --任务进度
            MaxTaskRewardProgress = 0, --任务进度最大值
            TaskItemList = {}, --任务奖励列表
        }
        return UiDataMain
    end
    --整备界面(准备出击界面)
    function XBrilliantWalkManager.GetUiDataEquipment(stageId)
        local stageConfig
        if stageId then stageConfig = XBrilliantWalkConfigs.GetStageConfig(stageId) end
        local UiDataEquipment = {
            StageConfig = stageConfig or nil,
            TrenchConfigs = XBrilliantWalkConfigs.GetTrenchConfigs(),
            CurPluginsDatas = CurPluginData, --装备了的模块信息
            AddtionalBuffs = XBrilliantWalkConfigs.GetAdditionalBuffConfigs()
        }
        return UiDataEquipment
    end
    --整备模块详情界面
    function XBrilliantWalkManager.GetUiDataModuleInfo()
        local UiDataModuleInfo = {
            TrenchConfigs = XBrilliantWalkConfigs.GetTrenchConfigs(),
            CurPluginsDatas = CurPluginData, --装备了的模块信息
        }
        return UiDataModuleInfo
    end
    --快速切换模块界面
    function XBrilliantWalkManager.GetUiDataSkillModuleSwitch()
        local UiDataSkillModuelSwitch = {
            ListActivatedModuleSkill = {}, --已激活模块技能列表
            SwitchModuleSkillData = {}, --需要切换的模块技能
        }
        return UiDataSkillModuelSwitch
    end
    --技能详情界面
    function XBrilliantWalkManager.GetUiDataSkillGrid()
        local UiDataSkillInfo = {
            ModuleSkillData = {}, --模组技能信息
        }
        return UiDataSkillInfo
    end
    --任意插件界面 查阅过某个插件
    function XBrilliantWalkManager.UiViewPlugin(pluginId)
        if not ViewedUnlockPlugin[pluginId] then
            ViewedUnlockPlugin[pluginId] = true
            LocalStroageSaveNewPluginRedData(ViewedUnlockPlugin)
            XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_ON_PLUGIN_UNLOCK_STATE)
        end
    end
    --章节选择界面
    function XBrilliantWalkManager.GetUiDataChapterSelect()
        local chapterConfig = {}
        local chapterUnlock = {}
        for _,chpaterId in pairs(MainChapterList) do
            table.insert(chapterConfig,XBrilliantWalkConfigs.GetChapterConfig(chpaterId))
            table.insert(chapterUnlock,XBrilliantWalkManager.CheckChapterIsUnlock(chpaterId) and ChapterUnlockDict[chpaterId])
        end
        local UiDataChapterSelect = {
            chapterConfig = chapterConfig, --章节数据
            ChapterUnlock = chapterUnlock, --章节解锁情况
            TaskRewardProgress = 0, --任务进度
            MaxTaskRewardProgress = 0, --任务进度最大值
            TaskItemList = {}, --任务奖励列表
        }
        return UiDataChapterSelect
    end
    --关卡选择界面
    function XBrilliantWalkManager.GetUiDataStageSelect(chapterId)
        local UiDataStageSelect = {
            TaskReward = 0, --任务奖励
            ChapterConfig = XBrilliantWalkConfigs.GetChapterConfig(chapterId) --章节数据
        }
        return UiDataStageSelect
    end
    --关卡选择图标图标数据
    function XBrilliantWalkManager.GetUIStageData(stageId)
        local isUnLock,perStages = XDataCenter.BrilliantWalkManager.GetStageUnlockData(stageId)
        local UIStageData = {
            StageIcon = XFubenConfigs.GetStageIcon(stageId), --关卡图标
            StageName = XFubenConfigs.GetStageName(stageId), --关卡名字
            IsUnLock = isUnLock, --是否解锁
            PerStages = perStages, --前置关卡ID数组
            IsClear = PassStageDict[stageId], --是否已经通关
        }
        return UIStageData
    end
    --关卡详情界面
    function XBrilliantWalkManager.GetUiDataStageDetail(stageId)
        local bwStageConfig = XBrilliantWalkConfigs.GetStageConfig(stageId)
        local pulginEquipedDict = PlugInData2EquipPluginDict(CurPluginData)
        local recommendBuildEquipState = {}
        if #bwStageConfig.RecommendBuild > 0 then
            for index,pluginId in ipairs(bwStageConfig.RecommendBuild) do
                recommendBuildEquipState[index] = pulginEquipedDict[pluginId] or false
            end
        end
        local UiDataStageInfo = {
            StageName = XFubenConfigs.GetStageName(stageId),--关卡名
            ActionPoint = XDataCenter.FubenManager.GetRequireActionPoint(stageId),--消耗血清
            RecommendBuild = bwStageConfig.RecommendBuild, --推荐插件
            RecommendBuildEquipState = recommendBuildEquipState, --推荐插件装备情况
            UnlockPlugin = bwStageConfig.UnlockPlugin, --解锁插件
            UnlockEnergy = bwStageConfig.AddEnergy or 0, --添加能量
            IsClear = PassStageDict[stageId], --是否已经通关
        }
        return UiDataStageInfo

    end
    --Boss关卡选择界面
    function XBrilliantWalkManager.GetUiDataBossStageSelect()
        local chapterId = BossChapterList[1]
        local UiDataStageSelect = {
            TaskReward = 0, --任务奖励
            ChapterConfig = XBrilliantWalkConfigs.GetChapterConfig(chapterId) --章节数据
        }
        return UiDataStageSelect
    end
    --BOSS关卡详情界面
    function XBrilliantWalkManager.GetUiDataBossStageInfo(StageId)
        local bwStageConfig = XBrilliantWalkConfigs.GetStageConfig(StageId)
        local pulginEquipedDict = PlugInData2EquipPluginDict(CurPluginData)
        local recommendBuildEquipState = {}
        if #bwStageConfig.RecommendBuild > 0 then
            for index,pluginId in ipairs(bwStageConfig.RecommendBuild) do
                recommendBuildEquipState[index] = pulginEquipedDict[pluginId] or false
            end
        end
        local UiDataBossStageInfo = {
            StageName = XFubenConfigs.GetStageName(StageId), --关卡名
            Description = XFubenConfigs.GetStageDescription(StageId), --关卡描述
            ActionPoint = XDataCenter.FubenManager.GetRequireActionPoint(StageId), --消耗血清
            RecommendBuild = bwStageConfig.RecommendBuild, --推荐插件
            RecommendBuildEquipState = recommendBuildEquipState, --推荐插件装备情况
            MaxScore = StageMaxScore[StageId] or 0, --最高分数
        }
        return UiDataBossStageInfo
    end
    --任务界面
    function XBrilliantWalkManager.GetUIDataTask(taskType)
        local taskList = {}
        local taskIdList = XBrilliantWalkConfigs.GetTaskListByType(taskType)
        local taskData
        for _, taskId in pairs(taskIdList) do
            taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData then
                table.insert(taskList, taskData)
            end
        end
        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        local finish = XDataCenter.TaskManager.TaskState.Finish
        table.sort(taskList, function(a, b)
            if a.State ~= b.State then
                if a.State == achieved then
                    return true
                end
                if b.State == achieved then
                    return false
                end
                if a.State == finish then
                    return false
                end
                if b.State == finish then
                    return true
                end
            end

            local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
            local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
            return templatesTaskA.Priority > templatesTaskB.Priority
        end)
        local UiDataTaskInfo = {
            TaskList = taskList
        }
        return UiDataTaskInfo
    end
    --其他任务界面的小任务UI
    function XBrilliantWalkManager.GetUIDataMiniTask()
        local taskManager = XDataCenter.TaskManager
        --初始化界面要显示的奖励道具表
        local showTaskRewards = XBrilliantWalkConfigs.GetActivityTaskReward(_CurActivityId) or {}
        local showItemDict = {} --界面要显示的奖励道具表
        for _,itemTemplateId in ipairs(showTaskRewards) do
            showItemDict[itemTemplateId] = {
                TemplateId = itemTemplateId,
                GetNum = 0, --已经领取的数量
                TotleNum = 0, --总共可以获取的数量
            }
        end
        local datas = XBrilliantWalkManager.GetAllTaskData()
        local TaskState = taskManager.TaskState
        local doneTaskNum = 0 --已经完成的任务数量
        local allTaskNum = #datas --全部任务数量
        for _,taskData in ipairs(datas) do
            --记录已完成任务数量
            if taskData.State == TaskState.Finish then
                doneTaskNum = doneTaskNum + 1
            end
            --处理显示道具
            local taskTemplate = taskManager.GetTaskTemplate(taskData.Id)
            local rewards = XRewardManager.GetRewardList(taskTemplate.RewardId)
            for _,reward in ipairs(rewards) do
                if showItemDict[reward.TemplateId] then
                    showItemDict[reward.TemplateId].TotleNum = showItemDict[reward.TemplateId].TotleNum + reward.Count
                    if taskData.State == TaskState.Finish then
                        showItemDict[reward.TemplateId].GetNum = showItemDict[reward.TemplateId].GetNum + reward.Count
                    end
                end
            end
        end
        local showItemList = {}
        for _,itemTemplateId in ipairs(showTaskRewards) do
            if showItemDict[itemTemplateId] then
                table.insert(showItemList,showItemDict[itemTemplateId])
            end
        end
        local UiDataMiniTask = {
            TaskRewardProgress = doneTaskNum, --任务进度
            MaxTaskRewardProgress = allTaskNum, --任务进度最大值
            TaskItemList = showItemList, --任务奖励列表
        }
        return UiDataMiniTask
    end
    --Boss关卡结算界面
    function XBrilliantWalkManager.GetUIBossStageSettleWin()
        return BossStageSettleData
    end
    --endregion
    
    --region 界面操作接口
    --获取任务奖励
    function XBrilliantWalkManager.DoGetTaskReward()
    end

    --弹出插件解锁提示
    function XBrilliantWalkManager.ShowPluginUnlockMsg(pluginId)
        local stageId = XBrilliantWalkConfigs.GetPluginUnlockStage(pluginId)
        if stageId then
            local stageName = XFubenConfigs.GetStageName(stageId) --关卡名
            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkStageUnlock",stageName))
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkStagePluginNotUnlock"))
        end
    end
    
    --BOSS关卡界面数据缓存
    function XBrilliantWalkManager.SetDifficultCache(difficult)
        UiBossChapterDifficultCahce = difficult
    end
    function XBrilliantWalkManager.GetDifficultCache()
        return UiBossChapterDifficultCahce
    end
    
    --启用/关闭Perk　begin 因为技能和Perk绑定 所以只跟Perk有关的接口是Manger私有接口
    local function DoEnablePerk(trench, perkId)
        if not (XBrilliantWalkConfigs.GetPluginTrenchType(perkId) == XBrilliantWalkConfigs.GetTrenchConfig(trench).TrenchType) then
            XLog.Error("Trench Type Error! trench:" .. trench .. "   can't handle plugin:" .. perkId)
            return false;
        end
        local parentPluginDatas = XBrilliantWalkConfigs.GetPluginRoots(perkId)
        local skillId = parentPluginDatas[1]
        local moduleId = parentPluginDatas[2]
        --若所属技能还没激活 
        if not CurPluginData[trench][moduleId][skillId] then return false end
        --若perk已经激活 
        if CurPluginData[trench][moduleId][skillId] == perkId then return false end
        --若插件未解锁
        if not XBrilliantWalkManager.CheckPluginUnlock(perkId) then return false end
        --如果该技能上装载了其他Perk 则卸载其他Perk
        local equipedPerk = CurPluginData[trench][moduleId][skillId]
        if not (equipedPerk == 0) then
            DoDisablePerk(trench,equipedPerk)
        end
        --装配perk
        CurPluginData[trench][moduleId][skillId] = perkId
        LocalStroageSavePluginData(CurPluginData)
        --记录技能Perk配置
        LastSkillPerkSet[skillId] = perkId
        LocalStroageSaveSkillPerkSetData(LastSkillPerkSet)
        return true
    end

    local function DoDisablePerk(trench, perkId)
        if not (XBrilliantWalkConfigs.GetPluginTrenchType(perkId) == XBrilliantWalkConfigs.GetTrenchConfig(trench).TrenchType) then
            XLog.Error("Trench Type Error! trench:" .. trench .. "   can't handle plugin:" .. perkId)
            return false;
        end
        local parentPluginDatas = XBrilliantWalkConfigs.GetPluginRoots(perkId)
        local skillId = parentPluginDatas[1]
        local moduleId = parentPluginDatas[2]
        CurPluginData[trench][moduleId][skillId] = 0
        XBrilliantWalkManager.CheckDisablePluginLockTrench(perkId)
        LocalStroageSavePluginData(CurPluginData)
    end
    --废弃
    local function DoDisablePerkBySkillId(trench, skillId)
        if not (XBrilliantWalkConfigs.GetPluginTrenchType(skillId) == XBrilliantWalkConfigs.GetTrenchConfig(trench).TrenchType) then
            XLog.Error("Trench Type Error! trench:" .. trench .. "   can't handle plugin:" .. skillId)
            return false;
        end
        local parentPluginDatas = XBrilliantWalkConfigs.GetPluginRoots(skillId)
        local moduleId = parentPluginDatas[1]
        local perkId = CurPluginData[trench][moduleId][skillId]
        if not (perkId == 0) then
            DoDisablePerk(trench, perkId)
        end
        --CurPluginData[trench][moduleId][skillId] = 0
        --LocalStroageSavePluginData(CurPluginData)
    end
    --启用/关闭Perk　end

    --启用/关闭技能 begin
    local function DoEnableSkill(trench, skillId)
        if not (XBrilliantWalkConfigs.GetPluginTrenchType(skillId) == XBrilliantWalkConfigs.GetTrenchConfig(trench).TrenchType) then
            XLog.Error("Trench Type Error! trench:" .. trench .. "   can't handle plugin:" .. skillId)
            return false;
        end
        local parentPluginDatas = XBrilliantWalkConfigs.GetPluginRoots(skillId)
        local moduleId = parentPluginDatas[1]
        --若所属模块还没激活 
        if not CurPluginData[trench][moduleId] then return false end
        --若所属技能已经激活 
        if CurPluginData[trench][moduleId][skillId] then return false end
        --若插件未解锁
        if not XBrilliantWalkManager.CheckPluginUnlock(skillId) then return false end
        --装配技能
        CurPluginData[trench][moduleId][skillId] = 0
        LocalStroageSavePluginData(CurPluginData)
        return true
    end

    function XBrilliantWalkManager.DoDisableSkill(trench, skillId)
        if not (XBrilliantWalkConfigs.GetPluginTrenchType(skillId) == XBrilliantWalkConfigs.GetTrenchConfig(trench).TrenchType) then
            XLog.Error("Trench Type Error! trench:" .. trench .. "   can't handle plugin:" .. skillId)
            return false;
        end
        local parentPluginDatas = XBrilliantWalkConfigs.GetPluginRoots(skillId)
        local moduleId = parentPluginDatas[1]
        local perkId = CurPluginData[trench][moduleId][skillId]
        if perkId and not (perkId == 0) then
            DoDisablePerk(trench, perkId)
        end
        CurPluginData[trench][moduleId][skillId] = nil
        XBrilliantWalkManager.CheckDisablePluginLockTrench(skillId)
        LocalStroageSavePluginData(CurPluginData)
    end
    --启用/关闭技能 end
    
    --启用/关闭模块(trench:槽位, moduleId:模块Id) begin
    function XBrilliantWalkManager.DoEnableModule(trench, moduleId)
        if not (XBrilliantWalkConfigs.GetPluginTrenchType(moduleId) == XBrilliantWalkConfigs.GetTrenchConfig(trench).TrenchType) then
            XLog.Error("Trench Type Error! trench:" .. trench .. "   can't handle plugin:" .. moduleId)
            return false;
        end
        --若已经激活 
        if CurPluginData[trench] and CurPluginData[trench][moduleId] then
            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkModuleActivated"))
            return false 
        end
        --若插件未解锁
        if not XBrilliantWalkManager.CheckPluginUnlock(moduleId) then
            XBrilliantWalkManager.ShowPluginUnlockMsg(moduleId)
            return false 
        end
        --一个模块同一时间只能在一个插槽上启动
        if XBrilliantWalkManager.CheckPluginEquiped(moduleId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkModuleEquiped"))
            return false 
        end
        --如果插槽上装备了其他模块 则卸载该模块
        local equipedModule = XBrilliantWalkManager.CheckTrenchEquipModule(trench)
        if equipedModule then
            XBrilliantWalkManager.DoDisableModule(trench,equipedModule)
        end
        --因为一个槽位只能装一个模块 所以清空
        CurPluginData[trench] = {}
        --装配模块
        CurPluginData[trench][moduleId] = {}
        LocalStroageSavePluginData(CurPluginData)
        return true
    end
    
    function XBrilliantWalkManager.DoDisableModule(trench)
        if CurPluginData[trench] == nil then return end
        local MID = nil
        for moduleId,skillList in pairs(CurPluginData[trench]) do
            if not (CurPluginData[trench][moduleId] == nil) then
                MID = moduleId
                for skillId,_ in pairs(CurPluginData[trench][moduleId]) do
                    XBrilliantWalkManager.DoDisableSkill(trench, skillId)
                end
            end
        end
        CurPluginData[trench] = nil
        XBrilliantWalkManager.CheckDisablePluginLockTrench(MID)
        LocalStroageSavePluginData(CurPluginData)
    end
    --启用/关闭模块(trench:槽位, moduleId:模块Id) end
    
    --11 02新需求 激活技能时 必须至少激活一个Perk(所以接口应该必须同时传入 技能和perk)
    function XBrilliantWalkManager.DoEnableSkillPerk(trench, skillId, perkId)
        if (not trench) or (not skillId) or (not perkId) then
            XLog.Error("DoEnableSkillPerk ParamentError ",trench,skillId,perkId)
            return
        end
        local result = DoEnableSkill(trench, skillId)
        if not result then return false end
        result = result and DoEnablePerk(trench, perkId)
        if not result then
            XBrilliantWalkManager.DoDisableSkill(trench, skillId) --因为Perk激活失败 所以技能不能激活
            return false 
        end
        return result
    end
    --判断指定Plugin是否会影响插槽开启，如果是则检查插槽是否开启，如果没开启，则写在该插槽上所有模块
    function XBrilliantWalkManager.CheckDisablePluginLockTrench(pluginId)
        if not pluginId then return end
        local trenchs = XBrilliantWalkConfigs.DictNeedPluginTrench[pluginId]
        if not trenchs then return end
        for _,trench in ipairs(trenchs) do
            if not XBrilliantWalkManager.CheckTrenchUnlock(trench) then
                XBrilliantWalkManager.DoDisableModule(trench)
            end
        end
    end
    --跳转到指定插件UI
    function XBrilliantWalkManager.SkipToPluginUi(pluginId)
        local config = XBrilliantWalkConfigs.GetBuildPluginConfig(pluginId)
        --不存在插件 return
        if not config then
            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkStagePluginNotExist"))
            return
        end
        --插件没解锁 return
        if not XBrilliantWalkManager.CheckPluginUnlock(pluginId) then
            XBrilliantWalkManager.ShowPluginUnlockMsg(pluginId)
            return
        end
        local trenchConfigs = XBrilliantWalkConfigs.GetTrenchConfigs()
        local trenchId = nil
        for id,trenchConfig in pairs(trenchConfigs) do
            --找到对应插槽 并且检查插槽有没有解锁
            if trenchConfig.TrenchType == config.TrenchType and XBrilliantWalkManager.CheckTrenchUnlock(id) then
                trenchId = id
            end
        end
        --没找到对应插槽 return
        if not trenchId then
            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkStagePluginHasntRelatedTrenchId"))
            return
        end
        local SubUI
        local UIData = {}
        if config.Type == XBrilliantWalkBuildPluginType.Module then
            SubUI = "UiBrilliantWalkModule"
            UIData["TrenchId"] = trenchId
            UIData["ModuleId"] = pluginId
        elseif config.Type == XBrilliantWalkBuildPluginType.Skill then
            SubUI = "UiBrilliantWalkModule"
            UIData["TrenchId"] = trenchId
            UIData["ModuleId"] = XBrilliantWalkConfigs.GetPluginRoots(pluginId)[1]
        elseif config.Type == XBrilliantWalkBuildPluginType.Perk then
            local root = XBrilliantWalkConfigs.GetPluginRoots(pluginId)
            SubUI = "UiBrilliantWalkPerk"
            UIData["TrenchId"] = trenchId
            UIData["ModuleId"] = root[2]
            UIData["SkillId"] = root[1]
        end
        XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_SKIP,SubUI,UIData)
    end
    --endregion
    
    --region 红点判断
    --检查玩法红点
    function XBrilliantWalkManager.CheckBrilliantWalkRed()
        return XBrilliantWalkManager.CheckBrilliantWalkTaskRed() or XBrilliantWalkManager.CheckBrilliantWalkPluginRed()
    end
    --检查任务奖励红点
    function XBrilliantWalkManager.CheckBrilliantWalkTaskRed()
        return XBrilliantWalkManager.CheckBrilliantWalkTaskRedByType(XBrilliantWalkTaskType.Daily) or XBrilliantWalkManager.CheckBrilliantWalkTaskRedByType(XBrilliantWalkTaskType.Accumulative)
    end
    --检查具体任务类型奖励红点
    function XBrilliantWalkManager.CheckBrilliantWalkTaskRedByType(taskType)
        local taskIdList = XBrilliantWalkConfigs.GetTaskListByType(taskType)
        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        for _, taskId in pairs(taskIdList) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData and taskData.State == achieved then
                return true
            end
        end
        return false
    end
    --检查某个新获得插件红点
    function XBrilliantWalkManager.CheckBrilliantWalkPluginRed()
        if ViewedUnlockPlugin == nil then
            ViewedUnlockPlugin = LocalStroageLoadNewPluginRedData()
        end
        for pluginId,_ in pairs(UnlockPlugin) do
            if not ViewedUnlockPlugin[pluginId] then
                return true
            end
        end
        return false
    end
    --检查某个机器人插槽的UI是否需要显示红点
    function XBrilliantWalkManager.CheckBrilliantWalkTrenchIsRed(trenchId)
        local tType = XBrilliantWalkConfigs.GetTrenchType(trenchId)
        local modulelist = XBrilliantWalkConfigs.ListModuleListInTrench[tType]
        for _,moduleId in ipairs(modulelist) do
            if XBrilliantWalkManager.CheckBrilliantWalkPluginIsRed(moduleId) then
                return true
            end
        end
        return false
    end
    --检查某个机器人插件的UI是否需要显示红点
    function XBrilliantWalkManager.CheckBrilliantWalkPluginIsRed(pluginId)
        if ViewedUnlockPlugin == nil then
            ViewedUnlockPlugin = LocalStroageLoadNewPluginRedData()
        end
        local checkPerkRed = function(perkId)
            if UnlockPlugin[perkId] and not ViewedUnlockPlugin[perkId] then
                return true;
            end
            return false
        end
        --UI界面里技能红点不包括他拥有的Perk，所以添加checkModule字段区分。
        local checkSkillRed = function(skillId,checkPerk) 
            if UnlockPlugin[skillId] and not ViewedUnlockPlugin[skillId] then
                return true;
            end
            if not checkPerk then return false end
            local perklist = XBrilliantWalkConfigs.ListPerkListInSkill[skillId] or {}
            for _,perkId in ipairs(perklist) do
                if checkPerkRed(perkId) then
                    return true
                end
            end
            return false
        end
        local checkModuleRed = function(moduleId)
            if UnlockPlugin[moduleId] and not ViewedUnlockPlugin[moduleId] then
                return true;
            end
            local skilllist = XBrilliantWalkConfigs.ListSkillListInModule[moduleId] or {}
            for _,skillId in ipairs(skilllist) do
                if checkSkillRed(skillId,true) then
                    return true
                end
            end
            return false
        end
        
        
        local pluginType = XBrilliantWalkConfigs.GetBuildPluginType(pluginId)
        if pluginType == XBrilliantWalkBuildPluginType.Module then
            return checkModuleRed(pluginId)
        elseif pluginType == XBrilliantWalkBuildPluginType.Skill then
            return checkSkillRed(pluginId,false)
        elseif pluginType == XBrilliantWalkBuildPluginType.Perk then
            return checkPerkRed(pluginId)
        end
        return false
    end
    --endregion
    
    --region 请求 和 副本相关
    -- 初始化关卡数据 设置关卡类型  （FubenManager调用）
    function XBrilliantWalkManager.InitStageInfo()
        local configs = XBrilliantWalkConfigs.GetStageConfigs()
        for stageId, config in pairs(configs) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.BrillientWalk
            end
        end
    end
    --FubenManager获取关卡是否通关 （FubenManager调用）
    function XBrilliantWalkManager.CheckPassedByStageId(stageId)
        return PassStageDict[stageId] or false
    end
    --desc: 请求进入关卡
    local RobotSallyAnimeCB;
    function XBrilliantWalkManager.EnterStage(stageId,animCB)
        RobotSallyAnimeCB = animCB
        local stage = XDataCenter.FubenManager.GetStageCfg(stageId)
        local bwStageConfig = XBrilliantWalkConfigs.GetStageConfig(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        stageInfo.Unlock = XBrilliantWalkManager.GetStageUnlockData(stageId)
        if XBrilliantWalkManager.CheckStageIsMovieStage(stageId) then
            local PlayMovie = function()
                if RobotSallyAnimeCB then
                    RobotSallyAnimeCB(function() XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId) end)
                else
                    XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
                end
            end
            --纯剧情关
            if PassStageDict[stageId] then
                PlayMovie()
            else
                XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
                    PlayMovie()
                end)
            end
        else
            --战斗关卡
            if bwStageConfig.Type == XBrilliantWalkStageModuleType.Custom then
                XBrilliantWalkManager.RequestModifyModuleSet(CurPluginData,function(state)
                    if state then
                        XDataCenter.FubenManager.EnterBrilliantWalkFight(stage)
                    end
                end)
            else
                XDataCenter.FubenManager.EnterBrilliantWalkFight(stage)
            end
        end
    end
    --desc: 添加战斗进入数据（FubenManager调用）
    function XBrilliantWalkManager.PreFight(stageData)
        local preFight = {}
        preFight.StageId = stageData.StageId
        preFight.CaptainPos = 1
        preFight.FirstFightPos = 1
        preFight.RobotIds = {XBrilliantWalkConfigs.GetActivityConfig(_CurActivityId).RobotId}
        return preFight
    end
    ---@desc 自定义进入战斗 （FubenManager调用）
    function XBrilliantWalkManager.CustomOnEnterFight(preFight, callback)
        local request = { PreFightData = preFight }
        XNetwork.Call(METHOD_NAME.PreFight, request, function(response)
            if response.Code == XCode.Success and RobotSallyAnimeCB  then
                RobotSallyAnimeCB(function() callback(response) end)
            else
                callback(response)
            end
        end)
    end
    --desc: 关卡结算（FubenManager调用）
    function XBrilliantWalkManager.FinishFight(settle)
        if settle.IsWin then
            --Boss关卡结算
            local stageId = settle.BrilliantWalkResult.StageId
            local bwStageType = XBrilliantWalkConfigs.GetStageType(stageId)
            if bwStageType == XBrilliantWalkStageType.Boss or bwStageType == XBrilliantWalkStageType.HardBoss then
                BossStageSettleData = settle.BrilliantWalkResult
                XLuaUiManager.Open("UiSettleWinBrilliantWalk")
            else
                XDataCenter.FubenManager.ChallengeWin(settle)
            end
        else
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end
    --主线关卡结算(FubenManager.ChallengeWin调用)
    function XBrilliantWalkManager.ShowReward(winData, playEndStory)
        local firstClean = winData.SettleData.BrilliantWalkResult.IsNewRecord
        if XBrilliantWalkManager.IsOpen() and firstClean then
            local stageId = winData.StageId
            local chapterId = MainChapterList[1]
            local firstStageId = XBrilliantWalkConfigs.GetChapterConfig(chapterId).MainStageIds[1]
            if stageId == firstStageId then
                XBrilliantWalkManager.SetUiMainClearCache()
            end
        end
        XLuaUiManager.Open("UiSettleWinBrilliantWalkChapter", winData)
    end
    -------------------------------
    --desc: 请求 装配改造插件
    --targetPlugInData : PluginData(结构请看文件顶部)
    -------------------------------
    function XBrilliantWalkManager.RequestModifyModuleSet(pluginData,callback)
        local serverPluginData = PlugInData2ServerPlugInData(pluginData)
        local requestDatas = {
            TrenchInfos = serverPluginData
        }
        XNetwork.Call(METHOD_NAME.BrilliantWalkBuildPluginRequest, requestDatas, function(response)
            if response.Code == XCode.Success then
                ServerPluginData = pluginData
                SynchronizePluginData()
                callback(true)
            else
                XUiManager.TipCode(response.Code)
                callback(false)
            end
        end)
        
    end
    --endregion

    
    
    return XBrilliantWalkManager
end


XRpc.NotifyBrilliantWalkData = function(data)
    XDataCenter.BrilliantWalkManager.NotifyBrilliantWalkData(data)
end