local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
local XPlanetViewModel = require("XEntity/XPlanet/XPlanetViewModel")
local XPlanetStageData = require("XEntity/XPlanet/XData/XPlanetStageData")
local XPlanetMainScene = require("XEntity/XPlanet/XGameObject/XPlanetMainScene")
local XPlanetStageScene = require("XEntity/XPlanet/XGameObject/XPlanetStageScene")
local XPlanetTalentTeamData = require("XEntity/XPlanet/XData/XPlanetTalentTeamData")
local XPlanetSceneCamera = require("XEntity/XPlanet/XData/XPlanetSceneCamera")

XPlanetManagerCreator = function()
    ---@class XPlanetManager
    local XPlanetManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.PlanetRunning, "PlanetManager")

    ---@type XPlanetViewModel
    local PlanetViewModel
    ---@type XPlanetStageData
    local PlanetStageData
    ---@type XPlanetMainScene
    local PlanetMainScene
    ---@type XPlanetStageScene
    local PlanetStageScene
    ---@type XPlanetTalentTeamData
    local PlanetTalentTeam = XPlanetTalentTeamData.New()

    ---@type table<number,CS.XIResource>
    local FloorMaterialDir = {}
    ---@type table<number,CS.XIResource>
    local FloorEffectMaterialDir = {}
    local SceneCameraDir = {}

    local IsOpenActivity = false
    local IsSceneLoaded = true   ---场景是否加载完成，用于loading展示延时
    local StageQuickBuildMode = false
    local ReformCardFilter = XPlanetTalentConfigs.TalentCardFilter.All
    local CurBuildingId = 0
    local CurBuildSelectFloorId = 0
    local CurFloorSelectBuildMode = XPlanetConfigs.FloorBuildingBuildMode.Point
    local CurStageFloorSelectBuildMode = XPlanetConfigs.FloorBuildingBuildMode.Point
    local IsReformBuyBuildTip = false
    local IsNotCountinueEnterGame = false

    local ActivityTimer = nil
    local _SceneOpenReason = XPlanetConfigs.SceneOpenReason.None
    local _SceneReleaseTimer = nil
    local _LuaMemoryTimer
    local _EnterLuaMemory = 0
    local _LuaMemoryLimit = 200 * 1024 --进入玩法增加200M后会GC一次

    ---建筑操作请求
    local BuildingOperation = {
        Delete = 1, -- 删除
        Insert = 2, -- 添加
        Update = 3, -- 更新
    }

    ---星球模式
    local BuildingOperationMode = {
        Talent = 0, -- 天赋球
        Stage = 1, -- 关卡
    }


    --region 本地缓存
    local function GetCacheKey(key)
        local activityId = XPlanetManager.IsOpen() and PlanetViewModel:GetProperty("_ActivityId") or 0
        return string.format("PlanetRunning_%s_PlayId_%s_%s", activityId, XPlayer.Id, key)
    end

    --首次进入缓存
    local function SetFirstOpenRed()
        local key = GetCacheKey("FirstOpen")
        XSaveTool.SaveData(key, true)
    end

    local function GetFirstOpenRed()
        local key = GetCacheKey("FirstOpen")
        return XSaveTool.GetData(key)
    end

    --首次剧情缓存
    local function SetFirstMovie()
        local key = GetCacheKey("FirstMovie")
        XSaveTool.SaveData(key, true)
    end

    local function GetFirstMovie()
        local key = GetCacheKey("FirstMovie")
        return XSaveTool.GetData(key)
    end

    --天赋建筑缓存
    local function SetTalentBuildUnlockRed(buildingId)
        local key = GetCacheKey("TalentBuildUnlock" .. buildingId)
        XSaveTool.SaveData(key, true)
    end

    local function GetTalentBuildUnlockRed(buildingId)
        local key = GetCacheKey("TalentBuildUnlock" .. buildingId)
        return XSaveTool.GetData(key)
    end
    --天赋建筑建造上限缓存
    local function SetTalentBuildLimitUnlockRed(buildingId, stageId)
        local key = GetCacheKey("TalentBuildLimitUnlock" .. buildingId .. "Limit" .. stageId)
        XSaveTool.SaveData(key, true)
    end

    local function GetTalentBuildLimitUnlockRed(buildingId, stageId)
        local key = GetCacheKey("TalentBuildLimitUnlock" .. buildingId .. "Limit" .. stageId)
        return XSaveTool.GetData(key)
    end
    --角色解锁提示缓存
    local function SetCharacterUnlockTip(characterId)
        local key = GetCacheKey("CharacterUnlockTip" .. characterId)
        XSaveTool.SaveData(key, true)
    end

    local function GetCharacterUnlockTip(characterId)
        local key = GetCacheKey("CharacterUnlockTip" .. characterId)
        return XSaveTool.GetData(key)
    end
    --角色解锁红点缓存
    local function SetCharacterUnlockRed(characterId)
        local key = GetCacheKey("CharacterUnlock" .. characterId)
        XSaveTool.SaveData(key, true)
    end

    local function GetCharacterUnlockRed(characterId)
        local key = GetCacheKey("CharacterUnlock" .. characterId)
        return XSaveTool.GetData(key)
    end
    --关卡建筑解锁提示缓存
    local function SetStageBuildUnlockTip(buildingId)
        local key = GetCacheKey("StageBuildUnlockTip" .. buildingId)
        XSaveTool.SaveData(key, true)
    end

    local function GetStageBuildUnlockTip(buildingId)
        local key = GetCacheKey("StageBuildUnlockTip" .. buildingId)
        return XSaveTool.GetData(key)
    end
    --关卡建筑解锁红点缓存
    local function SetStageBuildUnlockRed(buildingId)
        local key = GetCacheKey("StageBuildUnlock" .. buildingId)
        XSaveTool.SaveData(key, true)
    end

    local function GetStageBuildUnlockRed(buildingId)
        local key = GetCacheKey("StageBuildUnlock" .. buildingId)
        return XSaveTool.GetData(key)
    end
    --章节缓存
    local function SetChapterOpenRed(chapterId)
        local key = GetCacheKey("ChapterOpen" .. chapterId)
        XSaveTool.SaveData(key, true)
    end

    local function GetChapterOpenRed(chapterId)
        local key = GetCacheKey("ChapterOpen" .. chapterId)
        return XSaveTool.GetData(key)
    end

    local function SetChapterUnlockRed(chapterId)
        local key = GetCacheKey("ChapterUnlock" .. chapterId)
        XSaveTool.SaveData(key, true)
    end

    local function GetChapterUnlockRed(chapterId)
        local key = GetCacheKey("ChapterUnlock" .. chapterId)
        return XSaveTool.GetData(key)
    end
    --天气缓存
    local function SetWeatherUnlockRed(weatherId)
        local key = GetCacheKey("WeatherUnlock" .. weatherId)
        XSaveTool.SaveData(key, true)
    end

    local function GetWeatherUnlockRed(weatherId)
        local key = GetCacheKey("WeatherUnlock" .. weatherId)
        return XSaveTool.GetData(key)
    end

    function XPlanetManager.SetBtnStoryCache(state)
        local key = GetCacheKey("BtnStory")
        return XSaveTool.SaveData(key, state)
    end

    function XPlanetManager.GetBtnStoryCache()
        local key = GetCacheKey("BtnStory")
        return XSaveTool.GetData(key)
    end
    --endregion


    function XPlanetManager.Init()
        IsOpenActivity = false
        IsReformBuyBuildTip = false
        CurBuildSelectFloorId = 0
        CurFloorSelectBuildMode = XPlanetConfigs.FloorBuildingBuildMode.Point
        CurStageFloorSelectBuildMode = XPlanetConfigs.FloorBuildingBuildMode.Point

        ActivityTimer = nil

        _SceneOpenReason = XPlanetConfigs.SceneOpenReason.None
        XPlanetManager._StopReleaseTimer()
    end

    function XPlanetManager.IsInGame()
        if not PlanetStageData then
            return false
        end
        return XTool.IsNumberValid(PlanetStageData:GetStageId())
    end

    function XPlanetManager.GetIsNotCountinueEnterGame()
        return IsNotCountinueEnterGame
    end

    ---踢人下线
    function XPlanetManager.KickLogin(title, content)
        XUiManager.DialogTip(
                title,
                content,
                XUiManager.DialogType.OnlySure,
                nil,
                function()
                    CS.XNetwork.Disconnect()
                    XLoginManager.DoDisconnect()
                end
        )
    end


    --region 引导
    local GuideCardClickCountDir = {}
    ---清除可重复触发的引导缓存
    function XPlanetManager.ClearRepeatGuideCache()
        XPlanetManager.SetGuideEnterMovie(false)
        XPlanetManager.SetGuideFirstGetMoney(false)
        XPlanetManager.SetGuideFirstFight(false)
        XPlanetManager.SetGuideFirstHunt(false)
        XPlanetManager.ClearGuideEndRecord()
        GuideCardClickCountDir = {}
    end

    function XPlanetManager.CheckGuideOpen()
        return XDataCenter.GuideManager.CheckGuideOpen()
    end

    ---关卡结算清空该关引导记录确保下次重进
    function XPlanetManager.ClearGuideEndRecord()
        local key = GetCacheKey("GuildEndRecord")
        XSaveTool.SaveData(key, { })
    end

    ---本次引导播放完毕记录
    function XPlanetManager.SetGuideEnd(guideId)
        local key = GetCacheKey("GuildEndRecord")
        local table = XSaveTool.GetData(key)
        if not table then
            table = {}
        end
        table[guideId] = true
        XSaveTool.SaveData(key, table)
        return true
    end

    function XPlanetManager.GetGuideEnd(guideId)
        local key = GetCacheKey("GuildEndRecord")
        local table = XSaveTool.GetData(key)
        if not table then
            return false
        end
        return table[guideId]
    end

    ---引导中点击计数
    function XPlanetManager.AddGuideCardClickCount(buildingId)
        if not XTool.IsNumberValid(GuideCardClickCountDir[buildingId]) then
            GuideCardClickCountDir[buildingId] = 0
        end
        GuideCardClickCountDir[buildingId] = GuideCardClickCountDir[buildingId] + 1
    end

    function XPlanetManager.GetGuideCardClickCount(buildingId)
        if not XTool.IsNumberValid(GuideCardClickCountDir[buildingId]) then
            GuideCardClickCountDir[buildingId] = 0
        end
        return GuideCardClickCountDir[buildingId]
    end

    ---1-1入场剧情结束(可重复)
    function XPlanetManager.SetGuideEnterMovie(value)
        local key = GetCacheKey("GuildEnterMovie")
        if not value then
            XSaveTool.SaveData(key, false)
            return
        end
        if XPlanetManager.GetGuideEnterMovie() then
            return
        end
        XSaveTool.SaveData(key, true)
        return true
    end

    function XPlanetManager.GetGuideEnterMovie()
        local key = GetCacheKey("GuildEnterMovie")
        return XSaveTool.GetData(key)
    end

    ---1-1首次路过矿车引导(可重复)
    function XPlanetManager.SetGuideFirstGetMoney(value)
        local key = GetCacheKey("GuildFirstGetMoney")
        if not value then
            XSaveTool.SaveData(key, false)
            return
        end
        if XPlanetManager.GetGuideFirstGetMoney() then
            return
        end
        XSaveTool.SaveData(key, true)
        return true
    end

    function XPlanetManager.GetGuideFirstGetMoney()
        local key = GetCacheKey("GuildFirstGetMoney")
        return XSaveTool.GetData(key)
    end

    ---1-1首次战斗引导(可重复)
    function XPlanetManager.SetGuideFirstFight(value)
        local key = GetCacheKey("GuildFirstFight")
        if not value then
            XSaveTool.SaveData(key, false)
            return
        end
        if XPlanetManager.GetGuideFirstFight() then
            return
        end
        XSaveTool.SaveData(key, true)
        return true
    end

    function XPlanetManager.GetGuideFirstFight()
        local key = GetCacheKey("GuildFirstFight")
        return XSaveTool.GetData(key)
    end

    ---1-2首次掉血(可重复)
    function XPlanetManager.SetGuideFirstHunt(value)
        local key = GetCacheKey("GuildFirstHunt")
        if not value then
            XSaveTool.SaveData(key, false)
            return
        end
        if XPlanetManager.GetGuideFirstHunt() then
            return
        end
        XSaveTool.SaveData(key, true)
        return true
    end

    function XPlanetManager.GetGuideFirstHunt()
        local key = GetCacheKey("GuildFirstHunt")
        return XSaveTool.GetData(key)
    end
    --endregion


    --region PlanetTalentTeam
    function XPlanetManager.GetTeam()
        return PlanetTalentTeam
    end
    --endregion


    --region PlanetSceneCamera
    ---@return XPlanetSceneCamera
    function XPlanetManager.GetCamera(cameraId)
        if not SceneCameraDir[cameraId] then
            ---@type XPlanetSceneCamera
            local camera = XPlanetSceneCamera.New()
            camera:SetCameraId(cameraId)
            SceneCameraDir[cameraId] = camera
        end
        return SceneCameraDir[cameraId]
    end
    --endregion


    --region PlanetViewModel
    ---@return XPlanetViewModel
    function XPlanetManager.GetViewModel()
        return PlanetViewModel
    end

    function XPlanetManager.IsOpen()
        if not PlanetViewModel then
            return false
        end
        return PlanetViewModel:IsOpen()
    end

    function XPlanetManager.IsOnActivity(isInActivity)
        IsOpenActivity = isInActivity
    end

    function XPlanetManager.OnActivityEnd()
        if XPlanetManager.IsOpen() then
            return
        end
        if PlanetMainScene and PlanetMainScene:Exist() then
            XLuaUiManager.RunMain()
            XUiManager.TipText("CommonActivityEnd")
        end
        XPlanetManager.OnRelease()
    end

    function XPlanetManager._StartActivityTimer()
        XPlanetManager._StopActivityTimer()
        ActivityTimer = XScheduleManager.ScheduleForever(function()
            local endTime = PlanetViewModel:GetEndTime()
            local time = XTime.GetServerNowTimestamp()
            if time > endTime then
                XPlanetManager._StopActivityTimer()
                XPlanetManager.OnActivityEnd(true)
            end
        end, XScheduleManager.SECOND, 0)
    end

    function XPlanetManager._StopActivityTimer()
        if ActivityTimer then
            XScheduleManager.UnSchedule(ActivityTimer)
            ActivityTimer = nil
        end
    end

    ---活动是否开启基础判断
    function XPlanetManager.BaseCheckActivity(isTip)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PlanetRunning, false, not isTip) then
            return false
        end
        --活动未开启
        if not XPlanetManager.IsOpen() and isTip then
            XUiManager.TipText("CommonActivityNotStart")
            return false
        end
        --功能未开启
        if not PlanetViewModel then
            return false
        end
        return true
    end

    --天赋球(Reform or Talent)
    --============================================================

    function XPlanetManager.GetReformQuickRecycleMode()
        local key = GetCacheKey("QuickRecycleMode")
        return XSaveTool.GetData(key, false)
    end

    function XPlanetManager.SetReformQuickRecycleMode(isOn)
        local key = GetCacheKey("QuickRecycleMode")
        if isOn then
            XUiManager.TipErrorWithKey("PlanetRunningQuickBuildOpen")
        else
            XUiManager.TipErrorWithKey("PlanetRunningQuickBuildClose")
        end
        return XSaveTool.SaveData(key, isOn)
    end

    function XPlanetManager.GetReformQuickBuildMode()
        local key = GetCacheKey("QuickBuildMode")
        return XSaveTool.GetData(key, false)
    end

    function XPlanetManager.SetReformQuickBuildMode(isOn)
        local key = GetCacheKey("QuickBuildMode")
        return XSaveTool.SaveData(key, isOn)
    end

    function XPlanetManager.GetTalentBuildData()
        return PlanetViewModel:GetReformBuildingData()
    end

    function XPlanetManager.GetTalentBuildGuid()
        return PlanetViewModel:GetReformModeIncId()
    end

    ---@param filter number XPlanetTalentConfigs.TalentCardFilter
    function XPlanetManager.SetTalentBuildCardFilter(filter)
        ReformCardFilter = filter
    end

    function XPlanetManager.GetTalentBuildCardList(isAll)
        local result = {}
        local isAllFilter = ReformCardFilter == XPlanetTalentConfigs.TalentCardFilter.All
        local isBuildFilter = ReformCardFilter == XPlanetTalentConfigs.TalentCardFilter.Build
        local isFloorFilter = ReformCardFilter == XPlanetTalentConfigs.TalentCardFilter.Floor
        for _, config in pairs(XPlanetTalentConfigs.GetTalentBuildingConfigs()) do
            local isFloor = XPlanetWorldConfigs.CheckBuildingIsType(config.Id, XPlanetWorldConfigs.BuildType.FloorBuild)
            if XPlanetTalentConfigs.GetTalentBuildingIsCard(config.Id) then
                if isAllFilter or (isBuildFilter and not isFloor) or (isFloorFilter and isFloor) or isAll then
                    table.insert(result, config.Id)
                end
            end
        end
        table.sort(result, function(a, b)
            local lockValueA, lockValueB = 0, 0
            if PlanetViewModel:CheckReformBuildCardIsUnLock(a) then
                lockValueA = 1
            end
            if PlanetViewModel:CheckReformBuildCardIsUnLock(b) then
                lockValueB = 1
            end
            if lockValueA ~= lockValueB then
                return lockValueA > lockValueB
            end
            return a < b
        end)
        return result
    end

    function XPlanetManager.CheckTalentCardCanBuild(talentBuildId)
        if not XTool.IsNumberValid(talentBuildId) then
            return true
        end
        if not XPlanetManager.CheckTalentCardIsUnLock(talentBuildId) then
            return true
        end
        if XPlanetManager.CheckTalentCurBuildCardIsLimit(talentBuildId) then
            XUiManager.TipErrorWithKey("PlanetRunningMaxBuild")
            return true
        end
        return false
    end

    function XPlanetManager.CheckTalentCurBuildCardIsLimit(talentBuildId)
        local curCount = PlanetMainScene:GetBuildingCount(talentBuildId)
        local maxCount = PlanetViewModel:GetReformBuildMaxBuyCount(talentBuildId)
        return curCount >= maxCount
    end

    function XPlanetManager.CheckTalentCardIsUnLock(talentBuildId)
        if not PlanetViewModel:CheckReformBuildCardIsUnLock(talentBuildId) then
            local preStageId = XPlanetTalentConfigs.GetTalentBuildingUnlockStageId(talentBuildId)
            local stageName = XPlanetStageConfigs.GetStageFullName(preStageId)
            XUiManager.TipError(XUiHelper.GetText("PlanetRunningTalentCardLock", stageName))
            return false
        end
        return true
    end

    function XPlanetManager.GetCurFloorSelectBuildMode(isTalent)
        if isTalent then
            return XPlanetManager.GetCurBuildSelectBuildMode()
        else
            return XPlanetManager.GetCurStageBuildSelectBuildMode()
        end
    end

    function XPlanetManager.SetCurFloorSelectBuildMode(isTalent, mode)
        if isTalent then
            return XPlanetManager.SetCurBuildSelectBuildMode(mode)
        else
            return XPlanetManager.SetCurStageBuildSelectBuildMode(mode)
        end
    end

    function XPlanetManager.GetCurBuildSelectBuildMode()
        return CurFloorSelectBuildMode
    end

    function XPlanetManager.SetCurBuildSelectBuildMode(mode)
        CurFloorSelectBuildMode = mode
    end

    function XPlanetManager.GetCurStageBuildSelectBuildMode()
        return CurStageFloorSelectBuildMode
    end

    function XPlanetManager.SetCurStageBuildSelectBuildMode(mode)
        CurStageFloorSelectBuildMode = mode
    end

    function XPlanetManager.GetCurBuildSelectFloorId()
        return CurBuildSelectFloorId
    end

    function XPlanetManager.SetCurBuildSelectFloorId(floorId, buildingId)
        CurBuildSelectFloorId = floorId
        CurBuildingId = buildingId
    end

    function XPlanetManager.SetTalentCurBuildDefaultFloorId(buildingId)
        if buildingId == CurBuildingId then
            return
        end
        CurBuildSelectFloorId = XPlanetManager.GetTalentBuildingCanUseFloorId(buildingId)[1]
        CurBuildingId = buildingId
    end

    function XPlanetManager.GetTalentBuildingCanUseFloorId(talentBuildId)
        return PlanetViewModel:GetReformBuildCanUseFloorId(talentBuildId)
    end

    ---章节界面奖励统计信息
    function XPlanetManager.GetChapterRewardRecord(chapterId)
        local stageIdList = XPlanetStageConfigs.GetStageListByChapterId(chapterId)
        local rewards = {}
        local isFinish = {}
        local recordDir = {}
        if XTool.IsTableEmpty(stageIdList) then
            return rewards, isFinish
        end
        for _, stageId in ipairs(stageIdList) do
            local rewardId = XPlanetStageConfigs.GetStageRewardId(stageId)
            local tempRewardIds = {}
            if rewardId > 0 then
                tempRewardIds = XRewardManager.GetRewardList(rewardId)
            end
            for _, item in pairs(tempRewardIds) do
                if not recordDir[item.TemplateId] then
                    table.insert(rewards, item)
                    table.insert(isFinish, true)
                    recordDir[item.TemplateId] = #rewards
                end
                if not PlanetViewModel:CheckStageIsPass(stageId) then
                    isFinish[recordDir[item.TemplateId]] = false
                end
            end
        end
        return rewards, isFinish
    end

    ---显示的章节
    function XPlanetManager.GetShowChapterList()
        local result = {}
        local chapterList = XPlanetStageConfigs.GetChapterIdList()
        -- 上一个章节是否解锁
        local beforeIsUnlock = true
        for _, chapterId in ipairs(chapterList) do
            if PlanetViewModel:CheckChapterIsUnlock(chapterId) or beforeIsUnlock then
                table.insert(result, chapterId)
            end
            beforeIsUnlock = PlanetViewModel:CheckChapterIsUnlock(chapterId)
        end
        return result
    end

    function XPlanetManager.SetIsReformBuyBuildTip(isOn)
        IsReformBuyBuildTip = isOn
    end

    function XPlanetManager.GetIsReformBuyBuildTip()
        return IsReformBuyBuildTip
    end

    --关卡
    --============================================================

    ---@return XPlanetStageData
    function XPlanetManager.GetStageBuildData()
        return PlanetStageData:GetStageBuildingData()
    end

    function XPlanetManager.GetStageBuildIncId()
        return PlanetStageData:GetBuildIncId()
    end

    ---@return XPlanetStageData
    function XPlanetManager.GetStageData()
        return PlanetStageData
    end

    function XPlanetManager.ClearStageData()
        PlanetStageData:UpdateData()
    end

    function XPlanetManager.GetStageQuickBuildMode()
        local key = GetCacheKey("StageQuickBuildMode")
        return XSaveTool.GetData(key, false)
    end

    function XPlanetManager.SetStageQuickBuildMode(isOn)
        local key = GetCacheKey("StageQuickBuildMode")
        return XSaveTool.SaveData(key, isOn)
    end

    function XPlanetManager.GetStageSkipFight()
        local key = GetCacheKey("StageSkipFight")
        return XSaveTool.GetData(key, false)
    end

    function XPlanetManager.SetStageSkipFight(isOn)
        local key = GetCacheKey("StageSkipFight")
        return XSaveTool.SaveData(key, isOn)
    end

    function XPlanetManager.CheckBuildingIsUnLock(buildingId)
        local unlockStage = XPlanetWorldConfigs.GetBuildingUnlockStageId(buildingId)
        local unlockTimeId = XPlanetWorldConfigs.GetBuildingUnlockTimeId(buildingId)
        if not unlockStage and not unlockTimeId then
            return true
        end
        return PlanetViewModel:CheckStageIsPass(unlockStage) and XFunctionManager.CheckInTimeByTimeId(unlockTimeId, true)
    end
    --endregion


    --region 入口
    function XPlanetManager.CheckMainIsExit()
        if PlanetMainScene then
            return PlanetMainScene:Exist()
        end
        return false
    end

    ---加载场景,避免意外进入传统战斗时返回玩法场景报错
    function XPlanetManager.ResumeMainScene(cb)
        PlanetMainScene = PlanetMainScene or XPlanetMainScene.New(nil, XPlanetWorldConfigs.GetTalentStageId())
        PlanetMainScene:Load(cb)
    end

    function XPlanetManager.GetIsSceneLoad()
        return IsSceneLoaded
    end

    function XPlanetManager.CloseLoading()
        if XLuaUiManager.IsUiLoad("UiPlanetLoading") then
            XLuaUiManager.Remove("UiPlanetLoading")
        end
    end

    ---进入玩法
    function XPlanetManager.EnterUiMain(uiName)
        if not XPlanetManager.BaseCheckActivity(true) then
            return
        end
        IsSceneLoaded = false
        local loadingStartCb = function()
            --清除第一次红点
            if XPlanetManager.CheckFirstOpenActivityRedPoint() then
                SetFirstOpenRed()
            end
            --设置全局光
            PlanetMainScene = PlanetMainScene or XPlanetMainScene.New(nil, XPlanetWorldConfigs.GetTalentStageId())

            CS.UnityEngine.Resources.UnloadUnusedAssets()   -- 释放无用资源
            LuaGC() -- 手动执行GC
            _EnterLuaMemory = CS.XLuaEngine.Env.Memroy
            XPlanetManager._StartAutoLuaGC()
            --XPlanetManager._StartActivityTimer()

            PlanetMainScene:Load(function()
                IsSceneLoaded = true
            end)
        end
        local loadingCloseCb = function()
            local movieId = XPlanetConfigs.GetFirstOpenMovie()
            if movieId and not GetFirstMovie() then
                if PlanetMainScene then
                    PlanetMainScene:SetActive(false)
                end
                -- 不销毁方式播放剧情防止剧情结束镜头穿帮
                XDataCenter.MovieManager.PlayMovie(movieId, function()
                    SetFirstMovie()
                    XLuaUiManager.Open(uiName or "UiPlanetMain")
                end, nil, nil, false)
            else
                XLuaUiManager.Open(uiName or "UiPlanetMain")
            end
        end
        local onCallBack = function()
            XLuaUiManager.Open("UiPlanetLoading", loadingStartCb, loadingCloseCb)
        end

        if not IsOpenActivity then
            XPlanetManager.RequestEnterActivity(onCallBack)
        else
            onCallBack()
        end
    end

    ---进入关卡
    function XPlanetManager.EnterStage(uiName, stageId, selectCharacters, selectBuildings, callback)
        if not XPlanetManager.BaseCheckActivity() then
            callback()
            return
        end
        if XPlanetManager.IsInGame() then
            callback()
            XUiManager.TipErrorWithKey("PlanetRunningTipHaveGame")
            return
        end

        local onCallBack = function()
            XPlanetManager.LoadStageScene(uiName)
        end

        IsNotCountinueEnterGame = true
        XPlanetManager.ClearRepeatGuideCache()
        XPlanetManager.RequestEnterNewStage(stageId, selectCharacters, selectBuildings, onCallBack, callback)
    end

    ---继续关卡
    function XPlanetManager.ContinueStage(uiName)
        if not XPlanetManager.BaseCheckActivity() then
            return
        end
        if not XPlanetManager.IsInGame() then
            XUiManager.TipErrorWithKey("PlanetRunningTipNoGame")
            return
        end

        IsNotCountinueEnterGame = false
        XPlanetManager.LoadStageScene(uiName)
    end

    ---退出关卡
    function XPlanetManager.ExitStage()
        if PlanetMainScene then
            PlanetMainScene:SetActive(true)
        end
        if PlanetStageScene then
            PlanetStageScene:SetActive(false)
            PlanetStageScene:Release()
            PlanetStageScene = nil
        end
        CS.UnityEngine.Resources.UnloadUnusedAssets()   -- 释放无用资源
        LuaGC() -- 手动执行GC
    end

    ---中途结算关卡
    function XPlanetManager.SettleStage(cb)
        if not XPlanetManager.IsInGame() then
            XUiManager.TipErrorWithKey("PlanetRunningTipNoGame")
            return
        end
        XPlanetManager.RequestQuitStage(cb)
    end

    function XPlanetManager.LoadStageScene(uiName, cb)
        IsSceneLoaded = false
        local isSkipLoading = false
        --local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform
        --local UnityApplication = CS.UnityEngine.Application
        --if UnityApplication.platform == UnityRuntimePlatform.WindowsEditor then
        --    isSkipLoading = true
        --end

        local openFunc = function()
            if PlanetMainScene then
                PlanetMainScene:SetActive(false)
            end
            PlanetStageScene = PlanetStageScene or XPlanetStageScene.New(nil, PlanetStageData:GetStageId())
            --进入关卡默认不快速建造
            StageQuickBuildMode = false
            --进入关卡地块建造默认单格
            CurStageFloorSelectBuildMode = XPlanetConfigs.FloorBuildingBuildMode.Point

            PlanetStageScene:Load(function()
                IsSceneLoaded = true
                if isSkipLoading then
                    XLuaUiManager.Open(uiName or "UiPlanetBattleMain")
                end
            end)

            CS.UnityEngine.Resources.UnloadUnusedAssets()   -- 释放无用资源
            LuaGC() -- 手动执行GC
        end

        if isSkipLoading then
            openFunc()
            return
        end

        XLuaUiManager.Open("UiPlanetLoading", openFunc, function()
            XLuaUiManager.Open(uiName or "UiPlanetBattleMain")
            if cb then
                cb()
            end
        end)
    end
    --endregion


    --region 资源管理
    ---场景自动销毁,避免意外跳转
    function XPlanetManager.SceneOpen(reason)
        if reason then
            _SceneOpenReason = _SceneOpenReason | reason
            XPlanetManager._StopReleaseTimer()
        end
    end
    function XPlanetManager.SceneRelease(reason)
        if reason then
            _SceneOpenReason = _SceneOpenReason & (~reason)
        end
        if _SceneOpenReason ~= XPlanetConfigs.SceneOpenReason.None then
            return
        end
        XPlanetManager._StartReleaseTimer()
    end
    function XPlanetManager._StartReleaseTimer()
        XPlanetManager._StopReleaseTimer()
        XPlanetManager.SetSceneActive(false)
        _SceneReleaseTimer = XScheduleManager.ScheduleOnce(function()
            XPlanetManager.OnRelease()
        end, 30 * XScheduleManager.SECOND)
    end
    function XPlanetManager._StopReleaseTimer()
        if _SceneReleaseTimer then
            XScheduleManager.UnSchedule(_SceneReleaseTimer)
            XPlanetManager.SetSceneActive(true)
        end
        _SceneReleaseTimer = nil
    end

    function XPlanetManager.SetSceneActive(active)
        if PlanetMainScene then
            PlanetMainScene:SetActive(active)
        end
        if PlanetStageScene then
            if active and PlanetMainScene then
                PlanetMainScene:SetActive(false)
            end
            PlanetStageScene:SetActive(active)
        end
    end

    function XPlanetManager.OnRelease()
        if PlanetMainScene then
            PlanetMainScene:Release()
        end
        if PlanetStageScene then
            PlanetStageScene:Release()
        end
        XPlanetManager.ReleaseFloorMaterial()
        XPlanetManager.ReleaseEffectMaterial()
        XPlanetManager._StopAutoLuaGC()
        XPlanetManager._StopActivityTimer()
        PlanetStageScene = nil
        PlanetMainScene = nil

        CS.UnityEngine.Resources.UnloadUnusedAssets()   -- 释放无用资源
        LuaGC() -- 手动执行GC
    end

    ---读取地板材质
    function XPlanetManager.GetMaterialByFloorId(floorId)
        if FloorMaterialDir[floorId] then
            return FloorMaterialDir[floorId].Asset
        else
            local assetPath = XPlanetWorldConfigs.GetFloorMaterialUrl(floorId)
            local resource = CS.XResourceManager.LoadAsync(assetPath)
            FloorMaterialDir[floorId] = resource
            return FloorMaterialDir[floorId].Asset
        end
    end

    ---释放地板材质资源
    function XPlanetManager.ReleaseFloorMaterial()
        if not XTool.IsTableEmpty(FloorMaterialDir) then
            for _, floorMaterial in pairs(FloorMaterialDir) do
                floorMaterial:Release()
            end
            FloorMaterialDir = {}
        end
    end

    ---读取地板效果材质
    function XPlanetManager.GetEffectMaterial(key)
        if FloorEffectMaterialDir[key] then
            --if FloorEffectMaterialDir[key].Asset:HasProperty("_ZOffset") then
            --    FloorEffectMaterialDir[key].Asset:SetFloat("_ZOffset", 0.1)
            --end
            return FloorEffectMaterialDir[key].Asset
        else
            local assetPath = XPlanetConfigs.GetTileEffectMat(key)
            local resource = CS.XResourceManager.LoadAsync(assetPath)
            FloorEffectMaterialDir[key] = resource
            return FloorEffectMaterialDir[key].Asset
        end
    end

    ---释放地板效果材质资源
    function XPlanetManager.ReleaseEffectMaterial()
        if not XTool.IsTableEmpty(FloorEffectMaterialDir) then
            for _, floorMaterial in pairs(FloorEffectMaterialDir) do
                floorMaterial:Release()
            end
            FloorEffectMaterialDir = {}
        end
    end
    --endregion


    --region Memory
    function XPlanetManager._StartAutoLuaGC()
        if not _LuaMemoryTimer then
            _LuaMemoryTimer = XScheduleManager.ScheduleForever(function()
                XPlanetManager._AutoLuaGC()
            end, XScheduleManager.SECOND, 0)
        end
    end

    function XPlanetManager._StopAutoLuaGC()
        if _LuaMemoryTimer then
            XScheduleManager.UnSchedule(_LuaMemoryTimer)
            _LuaMemoryTimer = nil
        end
        LuaGC()
    end

    function XPlanetManager._AutoLuaGC()
        if CS.XLuaEngine.Env.Memroy - _EnterLuaMemory > _LuaMemoryLimit then
            LuaGC()
        end
    end
    --endregion


    --region Scene
    function XPlanetManager.GetPlanetMainScene()
        return PlanetMainScene
    end

    function XPlanetManager.GetPlanetStageScene()
        return PlanetStageScene
    end
    --endregion


    --region RedPoint
    ---首次进入
    function XPlanetManager.CheckFirstOpenActivityRedPoint()
        if not XPlanetManager.BaseCheckActivity() then
            return false
        end
        return not GetFirstOpenRed()
    end

    ---新商品道具
    function XPlanetManager.CheckShopRedPoint()
        if not XPlanetManager.BaseCheckActivity() then
            return false
        end

        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
            return false
        end

        local res = false
        local shopIdList = XPlanetManager.GetViewModel():GetActivityShopIdList()
        for _, id in pairs(shopIdList) do
            local goodsList = XShopManager.GetShopGoodsList(id, true)
            for _, data in pairs(goodsList) do
                -- 检测每个商品
                local key = XPlayer.Id .. "PlanetShopId" .. data.Id
                local isCurrLock = nil -- 此次是否上锁
                local isLastLockAndThisShow = nil -- 该商品是否为上次检测上锁，此次检测解锁
                local allCdPass = true
                local conditionIds = data.ConditionIds
                -- 检测此次该商品是否解锁
                if conditionIds and #conditionIds > 0 then
                    for _, cId in pairs(conditionIds) do
                        local ret, desc = XConditionManager.CheckCondition(cId)
                        if not ret then
                            allCdPass = false
                        end
                    end
                end

                local isLastLock = XSaveTool.GetData(key)
                isCurrLock = not allCdPass
                isLastLockAndThisShow = isLastLock and not isCurrLock
                if isLastLockAndThisShow then
                    res = true
                end
            end
        end

        return res
    end

    ---奖励可领
    function XPlanetManager.CheckTaskRedPoint()
        if not XPlanetManager.BaseCheckActivity() then
            return false
        end

        local taskGroupId = XDataCenter.PlanetManager.GetViewModel():GetActivityTimeLimitTaskId()
        local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
        for k, taskData in pairs(taskList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end

        return false
    end

    ---新章节开启
    function XPlanetManager.CheckNewChapterRedPoint()
        if not XPlanetManager.BaseCheckActivity() then
            return false
        end

        local isHaveNewChapter, _ = XPlanetManager.CheckChapterOpenRedPoint()
        return isHaveNewChapter
    end

    function XPlanetManager.CheckChapterOpenRedPoint()
        local chapterIdList = XPlanetManager.GetShowChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            local isNeedUnlock = XTool.IsNumberValid(XPlanetStageConfigs.GetChapterPreStageId(chapterId))
            if isNeedUnlock and PlanetViewModel:CheckChapterIsInTime(chapterId) and not GetChapterOpenRed(chapterId) then
                return true
            end
        end
        return false
    end

    function XPlanetManager.ClearChapterOpenRedPoint()
        local chapterIdList = XPlanetManager.GetShowChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            local isNeedUnlock = XTool.IsNumberValid(XPlanetStageConfigs.GetChapterPreStageId(chapterId))
            if isNeedUnlock and PlanetViewModel:CheckChapterIsInTime(chapterId) and not GetChapterOpenRed(chapterId) then
                SetChapterOpenRed(chapterId)
            end
        end
    end

    ---章节解锁
    function XPlanetManager.CheckChapterUnlockRedPoint()
        local chapterIdList = XPlanetManager.GetShowChapterList()
        local bePlayRedPointDir = {}   -- 待播放列表
        for _, chapterId in ipairs(chapterIdList) do
            local isNeedUnlock = XTool.IsNumberValid(XPlanetStageConfigs.GetChapterPreStageId(chapterId))
            if isNeedUnlock and PlanetViewModel:CheckChapterIsUnlock(chapterId) and not GetChapterUnlockRed(chapterId) then
                bePlayRedPointDir[chapterId] = true
            end
        end
        return not XTool.IsTableEmpty(bePlayRedPointDir), bePlayRedPointDir
    end

    function XPlanetManager.ClearChapterUnlockRedPoint()
        local chapterIdList = XPlanetManager.GetShowChapterList()
        for _, chapterId in ipairs(chapterIdList) do
            local isNeedUnlock = XTool.IsNumberValid(XPlanetStageConfigs.GetChapterPreStageId(chapterId))
            if isNeedUnlock and PlanetViewModel:CheckChapterIsUnlock(chapterId) and not GetChapterUnlockRed(chapterId) then
                SetChapterUnlockRed(chapterId)
            end
        end
    end

    ---天赋球总红点(解锁,新建筑,新建筑上限,新天气)
    function XPlanetManager.CheckTalentRedPoint()
        if not XPlanetManager.BaseCheckActivity() then
            return false
        end

        if not PlanetViewModel:CheckStageIsPass(XPlanetConfigs.GetTalentUnLockStage()) then
            return false
        end

        if XPlanetManager.CheckTalentBuildRedPoint() then
            return true
        end

        if XPlanetManager.CheckAllWeatherUnlockRedPoint() then
            return true
        end

        return false
    end

    ---天赋球建筑总红点(新建筑,新建筑上限)
    function XPlanetManager.CheckTalentBuildRedPoint()
        if not XPlanetManager.BaseCheckActivity() then
            return false
        end

        if XPlanetManager.CheckTalentBuildUnlockRedPoint() then
            return true
        end

        if XPlanetManager.CheckTalentBuildLimitUnlockRedPoint() then
            return true
        end

        return false
    end

    ---天气解锁提示&红点
    ---[策划设计思路:Ui缓存+本地缓存,打开Ui清除本地缓存,不硬性要求玩家全部点击,天赋建筑同理]
    function XPlanetManager.CheckAllWeatherUnlockRedPoint()
        for _, weatherId in pairs(XPlanetWorldConfigs.GetWeatherIdList()) do
            if XPlanetManager.CheckOneWeatherUnlockRedPoint(weatherId) then
                return true
            end
        end
        return false
    end

    function XPlanetManager.CheckOneWeatherUnlockRedPoint(weatherId)
        if not XTool.IsNumberValid(weatherId) then
            return false
        end
        local stageId = XPlanetWorldConfigs.GetWeatherUnlockStageId(weatherId)
        local isNeedUnlock = XTool.IsNumberValid(stageId)
        if isNeedUnlock and
                PlanetViewModel:CheckStageIsPass(stageId) and
                XPlanetWorldConfigs.GetWeatherIsTalentShow(weatherId) and
                not GetWeatherUnlockRed(weatherId)
        then
            return true
        end
        return false
    end

    function XPlanetManager.ClearAllWeatherUnlockRedPoint()
        for _, weatherId in pairs(XPlanetWorldConfigs.GetWeatherIdList()) do
            local stageId = XPlanetWorldConfigs.GetWeatherUnlockStageId(weatherId)
            local isNeedUnlock = XTool.IsNumberValid(stageId)
            if isNeedUnlock and
                    PlanetViewModel:CheckStageIsPass(stageId) and
                    XPlanetWorldConfigs.GetWeatherIsTalentShow(weatherId) and
                    not GetWeatherUnlockRed(weatherId)
            then
                SetWeatherUnlockRed(weatherId)
            end
        end
    end

    ---天赋建筑解锁提示&红点
    function XPlanetManager.CheckTalentBuildUnlockRedPoint()
        local talentBuildList = XPlanetManager.GetTalentBuildCardList(true)
        local bePlayRedPointDir = {}   -- 待播放特效列表
        for _, id in ipairs(talentBuildList) do
            if XPlanetManager.CheckOneTalentBuildUnlockRedPoint(id) then
                bePlayRedPointDir[id] = true
            end
        end
        return not XTool.IsTableEmpty(bePlayRedPointDir), bePlayRedPointDir
    end

    function XPlanetManager.CheckOneTalentBuildUnlockRedPoint(buildId)
        if PlanetViewModel:CheckReformBuildCardIsUnLock(buildId) and not GetTalentBuildUnlockRed(buildId) then
            return true
        end
        return false
    end

    function XPlanetManager.ClearTalentBuildUnlockRedPoint()
        local talentBuildList = XPlanetManager.GetTalentBuildCardList(true)
        for _, id in ipairs(talentBuildList) do
            if PlanetViewModel:CheckReformBuildCardIsUnLock(id) and not GetTalentBuildUnlockRed(id) then
                SetTalentBuildUnlockRed(id)
            end
        end
    end

    ---天赋建筑建造上限解锁提示&红点
    function XPlanetManager.CheckTalentBuildLimitUnlockRedPoint()
        local talentBuildList = XPlanetManager.GetTalentBuildCardList(true)
        local bePlayRedPointList = {}   -- 待播放特效列表
        for _, id in ipairs(talentBuildList) do
            if XPlanetManager.CheckOneTalentBuildLimitUnlockRedPoint(id) then
                table.insert(bePlayRedPointList, id)
            end
        end
        return not XTool.IsTableEmpty(bePlayRedPointList), bePlayRedPointList
    end

    function XPlanetManager.CheckOneTalentBuildLimitUnlockRedPoint(buildId)
        local unlockStageId = XPlanetTalentConfigs.GetTalentBuildingUnlockCountStageIds(buildId)
        for _, stageId in ipairs(unlockStageId) do
            if PlanetViewModel:CheckStageIsPass(stageId) and
                    PlanetViewModel:CheckReformBuildCardIsUnLock(buildId) and
                    not GetTalentBuildLimitUnlockRed(buildId, stageId) then
                return true
            end
        end
        return false
    end

    function XPlanetManager.ClearTalentBuildLimitUnlockRedPoint()
        local talentBuildList = XPlanetManager.GetTalentBuildCardList(true)
        for _, id in ipairs(talentBuildList) do
            local unlockStageId = XPlanetTalentConfigs.GetTalentBuildingUnlockCountStageIds(id)
            for _, stageId in ipairs(unlockStageId) do
                if PlanetViewModel:CheckStageIsPass(stageId) and
                        PlanetViewModel:CheckReformBuildCardIsUnLock(id) and
                        not GetTalentBuildLimitUnlockRed(id, stageId) then
                    SetTalentBuildLimitUnlockRed(id, stageId)
                end
            end
        end
    end

    ---关卡建筑解锁提示
    ---[策划设计思路:红点和提示分开本地缓存,硬性要求玩家全部点击,角色解锁同理]
    function XPlanetManager.CheckStageBuildUnlockTip()
        local buildCfgList = XPlanetWorldConfigs.GetBuildingCanBring()
        local bePlayRedPointDir = {}   -- 待播放列表
        for _, id in ipairs(buildCfgList) do
            if XPlanetManager.CheckOneStageBuildUnlockTip(id) then
                bePlayRedPointDir[id] = true
            end
        end
        return not XTool.IsTableEmpty(bePlayRedPointDir), bePlayRedPointDir
    end

    function XPlanetManager.CheckOneStageBuildUnlockTip(buildId)
        local isNeedUnlock = XTool.IsNumberValid(XPlanetWorldConfigs.GetBuildingUnlockStageId(buildId))
        if isNeedUnlock and XPlanetManager.CheckBuildingIsUnLock(buildId) and not GetStageBuildUnlockTip(buildId) then
            return true
        end
        return false
    end

    function XPlanetManager.ClearStageBuildUnlockTip()
        local buildCfgList = XPlanetWorldConfigs.GetBuildingCanBring()
        for _, id in ipairs(buildCfgList) do
            XPlanetManager.ClearOneStageBuildUnlockTip(id)
        end
    end

    function XPlanetManager.ClearOneStageBuildUnlockTip(buildId)
        local isNeedUnlock = XTool.IsNumberValid(XPlanetWorldConfigs.GetBuildingUnlockStageId(buildId))
        if isNeedUnlock and XPlanetManager.CheckBuildingIsUnLock(buildId) and not GetStageBuildUnlockTip(buildId) then
            SetStageBuildUnlockTip(buildId)
        end
    end

    ---关卡建筑解锁红点
    function XPlanetManager.CheckAllStageBuildUnlockRed()
        local buildCfgList = XPlanetWorldConfigs.GetBuildingCanBring()
        for _, id in ipairs(buildCfgList) do
            if XPlanetManager.CheckOneStageBuildUnlockRed(id) then
                return true
            end
        end
        return false
    end

    function XPlanetManager.CheckOneStageBuildUnlockRed(buildId)
        local isNeedUnlock = XTool.IsNumberValid(XPlanetWorldConfigs.GetBuildingUnlockStageId(buildId))
        if isNeedUnlock and XPlanetManager.CheckBuildingIsUnLock(buildId) and not GetStageBuildUnlockRed(buildId) then
            return true
        end
        return false
    end

    function XPlanetManager.ClearOneStageBuildUnlockRed(buildId)
        if XPlanetManager.CheckOneStageBuildUnlockRed(buildId) then
            SetStageBuildUnlockRed(buildId)
        end
    end

    ---角色解锁提示
    function XPlanetManager.CheckCharacterUnlockTip()
        local characterList = XDataCenter.PlanetExploreManager.GetAllCharacter()
        local bePlayRedPointList = {}   -- 待播放列表
        for _, character in ipairs(characterList) do
            local id = character:GetCharacterId()
            local isNeedUnlock = not XTool.IsNumberValid(XPlanetCharacterConfigs.GetCharacterDefaultUnlock(id))
            if isNeedUnlock and PlanetViewModel:CheckCharacterIsUnlock(id) and not GetCharacterUnlockTip(id) then
                table.insert(bePlayRedPointList, id)
            end
        end
        return not XTool.IsTableEmpty(bePlayRedPointList), bePlayRedPointList
    end

    function XPlanetManager.ClearCharacterUnlockTip()
        local characterList = XDataCenter.PlanetExploreManager.GetAllCharacter()
        for _, character in ipairs(characterList) do
            local id = character:GetCharacterId()
            local isNeedUnlock = not XTool.IsNumberValid(XPlanetCharacterConfigs.GetCharacterDefaultUnlock(id))
            if isNeedUnlock and PlanetViewModel:CheckCharacterIsUnlock(id) and not GetCharacterUnlockTip(id) then
                SetCharacterUnlockTip(id)
            end
        end
    end

    ---角色解锁红点
    function XPlanetManager.CheckAllCharacterUnlockRed()
        local characterList = XDataCenter.PlanetExploreManager.GetAllCharacter()
        for _, character in ipairs(characterList) do
            if XPlanetManager.CheckOneCharacterUnlockRed(character:GetCharacterId()) then
                return true
            end
        end
        return false
    end

    function XPlanetManager.CheckOneCharacterUnlockRed(characterId)
        local isNeedUnlock = not XTool.IsNumberValid(XPlanetCharacterConfigs.GetCharacterDefaultUnlock(characterId))
        if isNeedUnlock and PlanetViewModel:CheckCharacterIsUnlock(characterId) and not GetCharacterUnlockRed(characterId) then
            return true
        end
        return false
    end

    function XPlanetManager.ClearOneCharacterUnlockRed(characterId)
        if XPlanetManager.CheckOneCharacterUnlockRed(characterId) then
            SetCharacterUnlockRed(characterId)
        end
    end
    --endregion


    --region ExManager
    function XPlanetManager.ExGetProgressTip()
    end
    --endregion


    --region 协议
    ---活动数据 + 天赋球数据
    function XPlanetManager.NotifyPlanetRunningDataDb(data)
        local activityId = data.ActivityId
        if XTool.IsNumberValid(activityId) then
            PlanetViewModel = PlanetViewModel or XPlanetViewModel.New(activityId)
            PlanetViewModel:NotifyPlanetRunningDataDb(data)
            PlanetStageData = PlanetStageData or XPlanetStageData.New()
            PlanetStageData:UpdateData(data.StageData)
            PlanetTalentTeam:SetInitData(PlanetViewModel:GetReformCharacterIds())
            XDataCenter.PlanetExploreManager.OnNotifyData(data)
        else
            XPlanetManager.OnActivityEnd()
        end

        XPlanetManager.RefreshShopInfo(nil, true)
    end

    -- 刷新商店信息
    function XPlanetManager.RefreshShopInfo(cb, notTip)
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, notTip) then
            local viewModel = XDataCenter.PlanetManager.GetViewModel()
            if not viewModel then
                return
            end
            local shopIdList = viewModel:GetActivityShopIdList()
            XShopManager.GetShopInfoList(shopIdList, cb, XShopManager.ActivityShopType.PlanetShop, notTip)
        end
    end

    ---配置修改
    function XPlanetManager.NotifyPlanetRunningClearByConfigChange(data)
        XPlanetManager.KickLogin(XUiHelper.GetText("PlanetConfigChangeKickOutTitle"), XUiHelper.GetText("PlanetConfigChangeKickOutContext"))
        XPlanetManager.ClearStageData()
    end

    ---准备建筑数据
    function XPlanetManager.PrepareBuildingData(buildingList, isTalentPlanet)
        local dataList = {}
        for _, data in ipairs(buildingList) do
            local occupyType = XPlanetWorldConfigs.GetBuildingGridOccupyType(data:GetBuildingId())
            -- 7格占地只发中心点
            local occupy = occupyType == XPlanetWorldConfigs.GridOccupyType.Occupy7 and { data:GetOccupyTileList()[1] } or data:GetOccupyTileList()

            local buildData = {
                Occupy = occupy,
                Rotate = data:GetBuildingDirection(),
                MaterialId = data:GetFloorId(),
            }
            table.insert(dataList, {
                Guid = data:GetGuid(),
                BuildingId = data:GetBuildingId(),
                RoadGrid = data:GetInRangeRoadList(),
                TalentBuilding = isTalentPlanet and buildData or {},
                Building = not isTalentPlanet and buildData or {}
            })
        end
        return dataList
    end

    ---进入玩法
    function XPlanetManager.RequestEnterActivity(cb)
        XNetwork.Call("PlanetRunningOnEnableRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            IsOpenActivity = true
            if cb then
                cb()
            end
        end)
    end

    ---天赋球:清空建筑
    function XPlanetManager.RequestTalentBuildClear(cb)
        XNetwork.Call("PlanetRunningReformClearRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            PlanetViewModel:UpdateReformMode(res)
            PlanetMainScene:ClearBuilding()
            if cb then
                cb()
            end
        end)
    end

    ---天赋球:建筑添加
    function XPlanetManager.RequestTalentInsertBuild(buildingList, cb)
        local buildDataDir = XPlanetManager.PrepareBuildingData(buildingList, true)
        local req = {
            Operation = {
                OperationType = BuildingOperation.Insert,
                OperationModeType = BuildingOperationMode.Talent,
                BuildingOperationInfo = buildDataDir,
            }
        }
        local func = function()
            XNetwork.Call("PlanetRunningBuildingOperationRequest", req, function(res)
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
                if res.Code ~= XCode.Success then
                    PlanetMainScene:RemoveCurBuildingList()
                    XUiManager.TipCode(res.Code)
                    return
                end
                for _, data in ipairs(buildDataDir) do
                    PlanetViewModel:AddReformBuildData(data)
                end
                PlanetViewModel:UpdateReformBuildBuyCount(res.Result.BuildBuyCount)
                PlanetViewModel:UpdateReformModeIncId(res.Result.IncId)
                if cb then
                    cb()
                end
            end)
        end
        -- 未持有天赋建筑发送二次弹窗
        local buildId = buildingList[1]:GetBuildingId()
        local curHaveCount = PlanetViewModel:GetReformCardCurHaveCount(buildId)
        if curHaveCount == 0 and not IsReformBuyBuildTip then
            XLuaUiManager.Open("UiPlanetPopover", buildId, #buildingList, function()
                local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PlanetRunningTalent)
                if count < XPlanetTalentConfigs.GetTalentBuildingBuyPrices(buildId) * #buildingList then
                    PlanetMainScene:RemoveCurBuildingList()
                    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
                    XUiManager.TipErrorWithKey("PlanetRunningNoEnoughCoin")
                else
                    func()
                end
            end, function()
                XPlanetManager.SetIsReformBuyBuildTip(false)
                PlanetMainScene:RemoveCurBuildingList()
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
            end)
        else
            func()
        end
    end

    ---天赋球:建筑删除
    function XPlanetManager.RequestTalentDeleteBuild(buildingList, cb)
        local buildDataDir = XPlanetManager.PrepareBuildingData(buildingList, true)
        local req = {
            Operation = {
                OperationType = BuildingOperation.Delete,
                OperationModeType = BuildingOperationMode.Talent,
                BuildingOperationInfo = buildDataDir,
            }
        }
        XNetwork.Call("PlanetRunningBuildingOperationRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            for _, data in ipairs(buildDataDir) do
                PlanetViewModel:RemoveReformBuildData(data.BuildingId, data.Guid)
            end
            PlanetViewModel:UpdateReformModeIncId(res.Result.IncId)
            if cb then
                cb()
            end
        end)
    end

    ---天赋球:建筑更新
    function XPlanetManager.RequestTalentUpdateBuild(buildingList, cb)
        local buildDataDir = XPlanetManager.PrepareBuildingData(buildingList, true)
        local req = {
            Operation = {
                OperationType = BuildingOperation.Update,
                OperationModeType = BuildingOperationMode.Talent,
                BuildingOperationInfo = buildDataDir,
            }
        }
        XNetwork.Call("PlanetRunningBuildingOperationRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            PlanetViewModel:UpdateReformModeIncId(res.Result.IncId)
            if cb then
                cb()
            end
        end)
    end

    ---天赋球:天气切换
    function XPlanetManager.RequestTalentUpdateWeather(weatherId, cb)
        local req = {
            WeatherId = weatherId,
        }
        XNetwork.Call("PlanetRunningReformChangeWeatherRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            PlanetViewModel:UpdateReformWeather(weatherId)
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_REFROM_WEATHER)
            if cb then
                cb()
            end
        end)
    end

    ---天赋球:角色切换
    function XPlanetManager.RequestTalentChangeCharacter(cb)
        local req = {
            Characters = PlanetTalentTeam:GetData4Request(),
        }
        XNetwork.Call("PlanetRunningReformChangeCharacterRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            PlanetViewModel:UpdateReformBuildCharacterIds(PlanetTalentTeam:GetData4Request())
            PlanetTalentTeam:SetData(PlanetViewModel:GetReformCharacterIds())
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_REFROM_TEAM)
            if cb then
                cb()
            end
        end)
    end

    ---关卡:进入关卡
    function XPlanetManager.RequestEnterNewStage(stageId, selectCharacters, selectBuildings, cb, callbackEvenFail)
        local req = {
            StageId = stageId,
            GridId = XPlanetWorldConfigs.GetRoadStartPointByStageId(stageId), -- 道路起点
            SelectCharacters = selectCharacters,
            SelectBuildings = selectBuildings,
        }
        XNetwork.Call("PlanetRunningEnterNewStageRequest", req, function(res)
            if res.Code ~= XCode.Success then
                if callbackEvenFail then
                    callbackEvenFail()
                end
                XUiManager.TipCode(res.Code)
                return
            end

            PlanetStageData:UpdateData(res.ResultStageData)
            if cb then
                cb()
            end
            if callbackEvenFail then
                callbackEvenFail()
            end
        end)
    end

    ---关卡:中断结算
    function XPlanetManager.RequestQuitStage(cb)
        local req = {}
        XNetwork.Call("PlanetRunningQuitStageRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDataCenter.PlanetExploreManager.OnNotifyResult(res)
            XDataCenter.PlanetExploreManager.HandleResult()
            XPlanetManager.ClearStageData()
            if cb then
                cb()
            end
        end)
    end

    ---关卡:建筑添加
    function XPlanetManager.RequestStageInsertBuild(buildingList, cb)
        local cast = 0
        local buildDataDir = XPlanetManager.PrepareBuildingData(buildingList)
        for _, building in ipairs(buildingList) do
            cast = cast + XPlanetWorldConfigs.GetBuildingCast(building:GetBuildingId())
        end
        if cast > PlanetStageData:GetCoin() then
            PlanetStageScene:RemoveCurBuildingList()
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
            XUiManager.TipErrorWithKey("PlanetRunningNoEnoughCoin")
            return
        end
        local req = {
            Operation = {
                OperationType = BuildingOperation.Insert,
                OperationModeType = BuildingOperationMode.Stage,
                BuildingOperationInfo = buildDataDir,
            }
        }
        XNetwork.Call("PlanetRunningBuildingOperationRequest", req, function(res)
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
            if res.Code ~= XCode.Success then
                PlanetStageScene:RemoveCurBuildingList()
                XUiManager.TipCode(res.Code)
                return
            end
            for _, data in ipairs(buildDataDir) do
                PlanetStageData:AddStageBuildData(data)
            end
            PlanetStageData:SetCoin(res.Result.StageCoin)
            PlanetStageData:SetBuildIncId(res.Result.IncId)
            PlanetStageScene:DebugDrawBuffDependence()
            if cb then
                cb()
            end
        end)
    end

    ---关卡:建筑删除
    function XPlanetManager.RequestStageDeleteBuild(buildingList, cb)
        local buildDataDir = XPlanetManager.PrepareBuildingData(buildingList)
        local req = {
            Operation = {
                OperationType = BuildingOperation.Delete,
                OperationModeType = BuildingOperationMode.Stage,
                BuildingOperationInfo = buildDataDir,
            }
        }
        XNetwork.Call("PlanetRunningBuildingOperationRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            for _, data in ipairs(buildDataDir) do
                PlanetStageData:RemoveStageBuildData(data.BuildingId, data.Guid)
            end
            PlanetStageData:SetCoin(res.Result.StageCoin)
            PlanetStageScene:DebugDrawBuffDependence()
            if cb then
                cb()
            end
        end)
    end

    ---关卡:到达起点
    function XPlanetManager.RequestArriveBeginGrid(stageId, cb)
        local req = {
            GridId = XPlanetWorldConfigs.GetRoadStartPointByStageId(stageId),
        }
        XNetwork.Call("PlanetRunningArriveBeginGridRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    ---关卡:角色移动
    function XPlanetManager.RequestDoMove(grid, cb)
        local req = {
            Grid = grid,
        }
        XNetwork.CallWithAutoHandleErrorCode("PlanetRunningDoMoveRequest", req, cb)
    end

    ---查看详情请求需要延时请求
    local _DataDetail = {}
    local _BuildDataDetail = {}
    local _RequestTime = 0
    local _RequestDuration = 1

    ---关卡:打开建筑详情查询效果激活
    function XPlanetManager.RequestStageOpenBuildDetial(buildId, guid, isCard, cb)
        if not PlanetStageScene or not PlanetStageScene:Exist() then
            return
        end
        local time = XTime.GetServerNowTimestamp()
        if _RequestTime + _RequestDuration < time then
            _RequestTime = time
            local req = {
                Guid = guid,
                CfgId = buildId,
            }
            XNetwork.CallWithAutoHandleErrorCode("PlanetRunningLookBuildingRequest", req, function(res)
                _BuildDataDetail[guid] = res
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_DETAIL)
            end)
        end
        XLuaUiManager.Open("UiPlanetBuildDetail", buildId, false, isCard, guid, nil, nil, cb)
    end

    function XPlanetManager.GetBuildDataDetail(guid)
        return _BuildDataDetail[guid]
    end

    ---关卡:打开角色详情查询效果激活
    ---@param character XPlanetCharacter
    ---@param characterList XPlanetCharacter[]
    function XPlanetManager.RequestStageOpenRoleDetial(character, characterList)
        if not PlanetStageScene or not PlanetStageScene:Exist() then
            return
        end
        if not character then
            return
        end
        local characterId = character:GetCharacterId()
        local time = XTime.GetServerNowTimestamp()
        if _RequestTime + _RequestDuration < time then
            _RequestTime = time

            local characterIdList
            if characterList then
                characterIdList = {}
                for i = 1, #characterList do
                    local characterOther = characterList[i]
                    characterIdList[#characterIdList + 1] = characterOther:GetCharacterId()
                end
            else
                characterIdList = { characterId }
            end
            local req = {
                CharacterId = characterIdList
            }
            XNetwork.CallWithAutoHandleErrorCode("PlanetRunningLookCharacterRequest", req, function(res)
                local infoList = res.FightCharacterInfo
                for i = 1, #infoList do
                    local info = infoList[i]
                    local characterOther = characterList[i]
                    _DataDetail[characterOther:GetUid()] = info
                end

                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_DETAIL)
            end)
        end

        XLuaUiManager.Open("UiPlanetDetail02", character, characterList)
    end

    function XPlanetManager.RequestUpdateDetailCharacter(character)
        if not PlanetStageScene or not PlanetStageScene:Exist() then
            return
        end
        local characterId = character:GetCharacterId()
        local time = XTime.GetServerNowTimestamp()
        if _RequestTime + _RequestDuration < time then
            _RequestTime = time
            local req = {
                CharacterId = { characterId },
            }
            XNetwork.CallWithAutoHandleErrorCode("PlanetRunningLookCharacterRequest", req, function(res)
                _DataDetail[character:GetUid()] = res.FightCharacterInfo[1]
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_DETAIL)
            end)
        end
    end

    function XPlanetManager.GetDataDetailRole(characterId)
        return _DataDetail[characterId]
    end

    ---@param role XPlanetRoleBase
    function XPlanetManager.GetExploreAttr(role)
        local uid = role:GetUid()
        local detail = _DataDetail[uid]
        if detail then
            if detail.BaseAttribute then
                return detail.BaseAttribute.Attribute
            end
        end
        return {}
    end

    ---关卡:打开怪物详情查询效果激活
    ---@param boss XPlanetBoss
    ---@param bossList XPlanetBoss[]
    function XPlanetManager.RequestStageOpenMonsterDetial(boss, bossList)
        if not PlanetStageScene or not PlanetStageScene:Exist() then
            return
        end
        local bossIdList
        if bossList then
            bossIdList = {}
            for i = 1, #bossList do
                local bossOther = bossList[i]
                bossIdList[#bossIdList + 1] = bossOther:GetIdFromServer()
            end
        else
            bossIdList = { boss:GetIdFromServer() }
        end
        local time = XTime.GetServerNowTimestamp()
        if _RequestTime + _RequestDuration < time then
            _RequestTime = time
            local req = {
                Grid = boss:GetGridId(),
                MonsterGuid = bossIdList,
            }
            XNetwork.CallWithAutoHandleErrorCode("PlanetRunningLookMonsterRequest", req, function(res)
                local infoList = res.FightMonsterInfo
                if bossList then
                    for i = 1, #infoList do
                        local info = infoList[i]
                        local bossOther = bossList[i]
                        _DataDetail[bossOther:GetUid()] = info
                    end
                else
                    _DataDetail[boss:GetUid()] = infoList[1]
                end
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_DETAIL)
            end)
        end
        XLuaUiManager.Open("UiPlanetDetail02", boss, bossList)
    end

    ---@param boss XPlanetBoss
    function XPlanetManager.RequestUpdateDetailMonster(boss)
        if not PlanetStageScene or not PlanetStageScene:Exist() then
            return
        end
        local time = XTime.GetServerNowTimestamp()
        if _RequestTime + _RequestDuration < time then
            _RequestTime = time
            local req = {
                Grid = boss:GetGridId(),
                MonsterGuid = { boss:GetIdFromServer() },
            }
            XNetwork.CallWithAutoHandleErrorCode("PlanetRunningLookMonsterRequest", req, function(res)
                _DataDetail[boss:GetUid()] = res.FightMonsterInfo[1]
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_DETAIL)
            end)
        end
    end
    --endregion


    --region 回合制
    function XPlanetManager.DebugFight(data, result)
        XNetwork.Call("XPlanetRunningDebugFightSettleRequest", {
            FightData = data,
            ResultData = result,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("Success")
        end)
    end
    --endregion


    --region Debug
    function XPlanetManager.RequestDrawCollisionData(cb)
        if not PlanetStageScene or not PlanetStageScene:Exist() then
            return
        end
        XNetwork.CallWithAutoHandleErrorCode("PlanetRunningDebugDrawCollisionRequest", {}, function(res)
            if cb then
                cb(res)
            end
        end)
    end
    --endregion

    function XPlanetManager.OnNotifyStageData(data)
        PlanetStageData:UpdateData(data.StageData)
    end

    local XPlanetRunningStageDataChangeType = {
        Character = 1,
        Monster = 2,
        Building = 3,
        Weather = 4,
        Coin = 5,
        Prop = 6,
        AddEvents = 7
    }

    function XPlanetManager.OnNotifyChangeStageData(data)
        local change = data.EventChange
        local changeList = change.DataChangeTypeList
        if XTool.IsTableEmpty(changeList) then
            return
        end
        for _, type in ipairs(changeList) do
            if type == XPlanetRunningStageDataChangeType.Monster then
                PlanetStageData:SetMonsterData(change.Monsters)

            elseif type == XPlanetRunningStageDataChangeType.Character then
                PlanetStageData:OnEffectAdd(change.CharacterEffectRecords)
                PlanetStageData:SetCharacterData(change.Characters)

            elseif type == XPlanetRunningStageDataChangeType.Prop then
                PlanetStageData:SetRunningItem(change.RunningItems)
                PlanetStageData:SetCoin(change.Coin)

            elseif type == XPlanetRunningStageDataChangeType.Weather then
                PlanetStageData:SetWeatherId(change.WeatherId)

            elseif type == XPlanetRunningStageDataChangeType.Coin then
                PlanetStageData:SetCoin(change.Coin)
                local bubbleId = XPlanetConfigs.GetPlanetMoneyBubbleId()
                if bubbleId then
                    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PLAY_BUBBLE, bubbleId)
                end

            elseif type == XPlanetRunningStageDataChangeType.AddEvents then
                PlanetStageData:SetAddEvents(change.AddEvents)

            end
        end
    end

    function XPlanetManager.ClearEnableState()
        IsOpenActivity = false
    end

    XPlanetManager.Init()
    return XPlanetManager
end

XRpc.NotifyPlanetRunningDataDb = function(data)
    XDataCenter.PlanetManager.NotifyPlanetRunningDataDb(data.DataDb)
end

XRpc.NotifyPlanetRunningNewMonsterInfo = function(data)
    local stageData = XDataCenter.PlanetManager.GetStageData()
    if stageData then
        stageData:NewMonsterData(data.MonsterInfos)
    end
end

XRpc.NotifyPlanetRunningStageData = function(data)
    XDataCenter.PlanetManager.OnNotifyStageData(data)
end

XRpc.NotifyPlanetRunningEventChange = function(data)
    XDataCenter.PlanetManager.OnNotifyChangeStageData(data)
end

XRpc.NotifyPlanetRunningClearByConfigChange = function(data)
    XDataCenter.PlanetManager.NotifyPlanetRunningClearByConfigChange(data)
end