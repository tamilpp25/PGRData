XActivityBriefManagerCreator = function()
    local MethodName = {
        FinishBrirfStory = "FinishBriefStoryRequest"
    }

    local PlayedStoryDic = {}
    local OldSpecialActivityTemplates = {}

    local SpecialActivityMaxEndTime = 0
    local pairs = pairs
    local ParseToTimestamp = XTime.ParseToTimestamp
    local CSUnityEnginePlayerPrefs = CS.UnityEngine.PlayerPrefs

    local ActivityConfig = XActivityBriefConfigs.GetActivityConfig()
    local FirstOpenUi = nil
    local FirstConditionalOpenUi = nil
    local COOKIE_FIRSTOPENUI_KEY = "IsFirstOpen"
    local COOKIE_FIRSTCONDITIONALOPENUI_KEY = "IsFirstConditionalOpen"
    local XActivityBriefManager = {}
    local MAX_MODEL_NUMBER
    local ModelRankIndex

    local CheckIsNewSpecialActivityTemplates = function(nowSpecialActivityTemplates)
        if #OldSpecialActivityTemplates ~= #nowSpecialActivityTemplates then
            OldSpecialActivityTemplates = nowSpecialActivityTemplates
            return true
        end
        return false
    end

    local function Init()
        for _, v in pairs(XActivityBriefConfigs.GetAllActivityEntryConfig()) do
            local endTime = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
            if SpecialActivityMaxEndTime < endTime then
                SpecialActivityMaxEndTime = endTime
            end
        end
        --游戏一开始随机获取其中一个数，用于活动界面随机显示一个模型
        -- local models = XActivityBriefConfigs.GetActivityModels()
        -- MAX_MODEL_NUMBER = #models == 0 and 1 or #models
        -- math.randomseed(os.time())
        -- ModelRankIndex = math.random(MAX_MODEL_NUMBER) 
    end

    function XActivityBriefManager.GetSpecialActivityMaxEndTime()
        return SpecialActivityMaxEndTime
    end

    function XActivityBriefManager.GetEntryBtnName(activityGroupId)
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        return config.BtnName
    end

    function XActivityBriefManager.GetBtnTimeId(activityGroupId)
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        return config.TimeId
    end

    function XActivityBriefManager.GetActivityStoryConfig()
        local storyConfig = XActivityBriefConfigs.GetActivityStoryConfig()
        return storyConfig
    end

    function XActivityBriefManager.InitPlayedStoryTemplates(ids)
        XActivityBriefConfigs.InitPlayedStoryTemplates(ids)
    end

    function XActivityBriefManager.AddPlayedStoryId(id)
        XActivityBriefConfigs.AddPlayedStoryId(id)
    end

    function XActivityBriefManager.GetActivityConditionDescById(id)
        local desc = XActivityBriefConfigs.GetActivityConditionDescById(id)
        return desc
    end

    function XActivityBriefManager.GetActivityShopIds()
        local shopIds = {}

        local shopInfoIds = ActivityConfig.ShopInfoId
        for index, shopInfoId in ipairs(shopInfoIds) do
            shopIds[index] = XActivityBriefConfigs.GetActivityShopByInfoId(shopInfoId).ShopId
        end

        return shopIds
    end

    function XActivityBriefManager.GetActivityShopNameByShopId(shopId)
        return XShopManager.GetShopName(shopId)
    end

    function XActivityBriefManager.GetActivityShopIdByIndex(index)
        return XActivityBriefConfigs.GetActivityShopByInfoId(ActivityConfig.ShopInfoId[index]).ShopId
    end

    function XActivityBriefManager.GetActivityShopConditionByShopId(shopId)
        return XShopManager.GetShopConditionIdList(shopId)
    end

    function XActivityBriefManager.GetActivityShopItemBgByIndex(index)
        return XActivityBriefConfigs.GetActivityShopByInfoId(ActivityConfig.ShopInfoId[index]).ShopItemBg
    end

    function XActivityBriefManager.GetActivityShopBgByIndex(index)
        return XActivityBriefConfigs.GetActivityShopByInfoId(ActivityConfig.ShopInfoId[index]).ShopBg
    end

    function XActivityBriefManager.GetActivityShopIconByIndex(index)
        return XActivityBriefConfigs.GetActivityShopByInfoId(ActivityConfig.ShopInfoId[index]).ShopIcon
    end

    function XActivityBriefManager.GetActivityMain3DBg()
        return ActivityConfig.Main3DBg
    end

    function XActivityBriefManager.GetActivityTaskBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskBg
    end

    function XActivityBriefManager.GetActivityTaskGotBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGotBg
    end

    function XActivityBriefManager.GetActivityTaskVipBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskVipBg
    end

    function XActivityBriefManager.GetActivityTaskVipGotBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskVipGotBg
    end

    function XActivityBriefManager.GetActivityActivityPointId()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).ActivityPointId
    end

    function XActivityBriefManager.CheckTaskIsInMark(Id)
        local MaskTaskIds = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).MarkTaskId
        for _, v in pairs(MaskTaskIds or {}) do
            if v == Id then
                return true
            end
        end
        return false
    end

    function XActivityBriefManager.GetActivityShopGoodsByShopIndex(index)
        local shopId = XActivityBriefManager.GetActivityShopIdByIndex(index)
        local goods = XShopManager.GetShopGoodsList(shopId)
        return goods
    end

    function XActivityBriefManager.GetActivityTaskTime()
        local taskGroupId = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGroupId
        if taskGroupId == 0 then return end
        return XTaskConfig.GetTimeLimitTaskTime(taskGroupId)
    end

    function XActivityBriefManager.IsActivityTaskInTime()
        local taskGroupId = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGroupId
        if taskGroupId == 0 then return false end
        return XTaskConfig.IsTimeLimitTaskInTime(taskGroupId)
    end

    function XActivityBriefManager.GetActivityTaskDatas()
        local taskGroupId = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGroupId
        if taskGroupId == 0 then return {} end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    end

    function XActivityBriefManager.CheckAnyTaskFinished()
        local taskDatas = XActivityBriefManager.GetActivityTaskDatas()

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        for _, taskData in pairs(taskDatas) do
            if taskData.State == achieved then
                return true
            end
        end

        return false
    end

    function XActivityBriefManager.GetNowActivityEntryConfig()
        local nowSpecialActivityTemplates = {}
        for _,v in pairs(XActivityBriefConfigs.GetAllActivityEntryConfig()) do
            if XFunctionManager.CheckInTimeByTimeId(v.TimeId) and
                    (v.Condition == 0 or XConditionManager.CheckCondition(v.Condition)) then
                table.insert(nowSpecialActivityTemplates, v)
            end
        end

        local isNewActivity = CheckIsNewSpecialActivityTemplates(nowSpecialActivityTemplates)
        return nowSpecialActivityTemplates, isNewActivity
    end

    function XActivityBriefManager.CheckActivityBriefOpen()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityBrief) then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        return XFunctionManager.CheckInTimeByTimeId(ActivityConfig.TimeId)
    end

    function XActivityBriefManager.IsFirstOpen()
        if FirstOpenUi == nil then
            FirstOpenUi = not XActivityBriefManager.ReadCookie(COOKIE_FIRSTOPENUI_KEY)
        end
        return FirstOpenUi
    end

    function XActivityBriefManager.SetNotFirstOpen()
        FirstOpenUi = false
        CSUnityEnginePlayerPrefs.SetInt(XActivityBriefManager.GetCookieKeyStr(COOKIE_FIRSTOPENUI_KEY), 1)
        CSUnityEnginePlayerPrefs.Save()
    end

    function XActivityBriefManager.IsAnimConditionPassed()
        local conditionId = ActivityConfig.AnimConditionId
        if conditionId == 0 or conditionId == nil then
            return false
        end
        return XConditionManager.CheckCondition(conditionId)
    end

    function XActivityBriefManager.IsFirstConditionalOpen()
        if FirstConditionalOpenUi == nil then
            FirstConditionalOpenUi = not XActivityBriefManager.ReadCookie(COOKIE_FIRSTCONDITIONALOPENUI_KEY)
        end
        return FirstConditionalOpenUi
    end

    function XActivityBriefManager.SetNotFirstConditionalOpen()
        FirstConditionalOpenUi = false
        CSUnityEnginePlayerPrefs.SetInt(XActivityBriefManager.GetCookieKeyStr(COOKIE_FIRSTCONDITIONALOPENUI_KEY), 1)
        CSUnityEnginePlayerPrefs.Save()
    end

    function XActivityBriefManager.GetCookieKeyStr(key)
        return string.format("%s%s%s", ActivityConfig.EndTimeStr, XPlayer.Id, key)
    end

    function XActivityBriefManager.ReadCookie(key)
        return CSUnityEnginePlayerPrefs.HasKey(XActivityBriefManager.GetCookieKeyStr(key))
    end


    function XActivityBriefManager.InitPlayedStoryDic(ids)
        for key, value in pairs(ids) do
            for id, playedStoryId in pairs(value) do
                PlayedStoryDic[playedStoryId] = true
            end
        end
    end

    function XActivityBriefManager.AddPlayedStoryId(id)
        PlayedStoryDic[id] = true
    end

    function XActivityBriefManager.GetPlayedStoryDic()
        return PlayedStoryDic
    end

    function XActivityBriefManager.SendStoryId(storyId)
        XNetwork.Call(MethodName.FinishBrirfStory, { Id = storyId }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            XActivityBriefManager.AddPlayedStoryId(storyId)
        end)
    end

    function XActivityBriefManager.QueryStatistics(storyId)
        local playeds = XActivityBriefManager.GetPlayedStoryDic()
        if playeds[storyId] == true then
            return
        end
        XActivityBriefManager.SendStoryId(storyId)
    end
    --@endregion  

    function XActivityBriefManager.GetModelRankIndex()
        ModelRankIndex = ModelRankIndex + 1
        if ModelRankIndex > MAX_MODEL_NUMBER then
            ModelRankIndex = 1
        end

        return ModelRankIndex
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, Init)
    return XActivityBriefManager
end

XRpc.NotifyBriefStoryData = function(storyData)
    XDataCenter.ActivityBriefManager.InitPlayedStoryDic(storyData)
end