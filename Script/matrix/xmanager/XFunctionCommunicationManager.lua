XFunctionCommunicationManagerCreator = function()
    local XFunctionCommunicationManager = {}

    local CommunicationQueen = {}
    local CommunicationActiveList = {}
    local IsCommunicating = false
    local DisableFunction = false     --功能屏蔽标记（调试模式时使用）
    local FestivalCommunication = {}
    XFunctionCommunicationManager.Type = { Normal = 1, Medal = 2 }
    XFunctionCommunicationManager.FestivalType = { Love = 1, SixOne = 2 }
    XFunctionCommunicationManager.InitiativeType = { GiveItem = 1,GameStory = 2}
    function XFunctionCommunicationManager.Init()
        DisableFunction = XMain.IsDebug and XFunctionCommunicationManager.CheckFuncDisable()
    end

    --处理战斗结算
    function XFunctionCommunicationManager.HandleFunctionEvent()

        local result = XFunctionCommunicationManager.CheckCommunication(XFunctionCommunicationManager.Type.Normal)
        -- if result then
        --     if not IsCommunicating then
        --         IsCommunicating = true
        --         XFunctionCommunicationManager.ShowNextCommunication()
        --     end
        -- end
        return result
    end

    --检查开启的通讯
    function XFunctionCommunicationManager.SetCommunication()
        local FunctionCommunicationConfig = XCommunicationConfig.GetFunctionCommunicationConfig()

        if FunctionCommunicationConfig then
            for k, v in pairs(FunctionCommunicationConfig) do
                if not XPlayer.IsCommunicationMark(v.Id) and (not CommunicationActiveList[v.Id]) then

                    local isOpen = true
                    for _, condition in ipairs(v.ConditionIds) do
                        if not XConditionManager.CheckCondition(condition) then
                            isOpen = false
                            break
                        end
                    end

                    if isOpen then
                        if not CommunicationQueen[v.Type] then CommunicationQueen[v.Type] = {} end
                        CommunicationActiveList[v.Id] = true
                        table.insert(CommunicationQueen[v.Type], v)
                        CommunicationQueen[v.Type].Type = v.Type
                    end
                end
            end

            for _, v in pairs(CommunicationQueen) do
                table.sort(v, function(a, b)
                    return a.Priority < b.Priority
                end)
            end

        end
    end

    function XFunctionCommunicationManager.SetFestivalCommunication()
        local FunctionFestivalCommunicationConfig = XCommunicationConfig.GetFunctionFestivalCommunicationConfig()

        if FunctionFestivalCommunicationConfig then
            for _, v in pairs(FunctionFestivalCommunicationConfig) do
                local curTime = XTime.GetServerNowTimestamp()
                local startStr = XTime.ParseToTimestamp(v.StartTimeStr)
                local endStr = XTime.ParseToTimestamp(v.EndTimeStr)
                local isOpen = true

                for _, condition in ipairs(v.ConditionIds) do
                    if not XConditionManager.CheckCondition(condition) then
                        isOpen = false
                        break
                    end
                end

                if curTime < startStr or curTime > endStr then
                    isOpen = false
                end

                if isOpen then
                    if not FestivalCommunication[v.Type] then
                        FestivalCommunication[v.Type] = v
                    end
                end
            end
        end
    end

    function XFunctionCommunicationManager.CheckCommunication(type)
        if #CommunicationQueen[type] <= 0 then
            return false
        end
        return true
    end

    --显示
    function XFunctionCommunicationManager.ShowNextCommunication(type)
        if DisableFunction then return false end
        if not CommunicationQueen[type] or #CommunicationQueen[type] <= 0 then
            return false
        end

        local communicationData = XFunctionCommunicationManager.GetNextCommunication(type)

        XLuaUiManager.Open("UiFunctionalOpen", communicationData, type ~= XFunctionCommunicationManager.Type.Medal, true)

        return true
    end


    function XFunctionCommunicationManager.ShowFestivalCommunication()
        if DisableFunction then return false end
        for _, festival in pairs(FestivalCommunication) do
            if festival then
                local festivalCommunication = XCommunicationConfig.GetFunctionFestivalCommunicationDicByType(festival.Type)
                local IsMark = false
                for _,communication in pairs(festivalCommunication) do
                    if XPlayer.IsCommunicationMark(communication.Id) then
                        IsMark = true
                        break
                    end
                end

                if not IsMark then
                    XFunctionCommunicationManager.ReqMarkCommunication(festival.Id)
                    XLuaUiManager.Open("UiFunctionalOpen", festival, true, false)
                    return true
                end
            end
        end

        return false
    end

    -- 播放生日剧情动画
    function XFunctionCommunicationManager.ShowBirthdayStory()
        local state = XPlayer.PlayBirthdayStory()
        return state
    end


    function XFunctionCommunicationManager.ShowItemCommunication(CharacterId)
        local initiativeConfig = XCommunicationConfig.GetFunctionInitiativeCommunicationConfig()
        local firstIndex = 1
        for _, initiative in pairs(initiativeConfig) do
            local conditionId = initiative.ConditionIds[firstIndex]
            if initiative.Type == XFunctionCommunicationManager.InitiativeType.GiveItem and XTool.IsNumberValid(conditionId) then
                local ret, _ = XConditionManager.CheckCondition(conditionId)
                local template = XConditionManager.GetConditionTemplate(conditionId)
                if ret and template.Params[firstIndex] and template.Params[firstIndex] == CharacterId then
                    XFunctionCommunicationManager.ReqMarkCommunication(initiative.Id)
                    XLuaUiManager.Open("UiFunctionalOpen", initiative, true, false)
                end
            end
        end
    end

    function XFunctionCommunicationManager.ShowGameStoryCommunication(CommuId, callback)
        if not CommuId then return end
        local config = XCommunicationConfig.GetFunctionInitiativeCommunicationConfigById(CommuId)
        if not config then return end
        XFunctionCommunicationManager.ReqMarkCommunication(config.Id)
        XLuaUiManager.Open("UiFunctionalOpen", config, true, false, callback)
    end

    function XFunctionCommunicationManager.SetFestivalCommunicationTrigger(type)
        local key = string.format("%s%s%d", tostring(XPlayer.Id), "_FestivalCommunicationTrigger_", type)
        CS.UnityEngine.PlayerPrefs.SetInt(key, 1)
    end

    function XFunctionCommunicationManager.GetFestivalCommunicationTrigger(type)
        local key = string.format("%s%s%d", tostring(XPlayer.Id), "_FestivalCommunicationTrigger_", type)
        local result = CS.UnityEngine.PlayerPrefs.GetInt(key, 0)
        return result
    end


    --获取下一个
    function XFunctionCommunicationManager.GetNextCommunication(type)
        if not CommunicationQueen[type] or #CommunicationQueen[type] <= 0 then
            return nil
        end

        local communication = table.remove(CommunicationQueen[type], 1)
        XFunctionCommunicationManager.ReqMarkCommunication(communication.Id)

        return communication
    end


    function XFunctionCommunicationManager.IsCommunicating()
        return IsCommunicating
    end


    function XFunctionCommunicationManager.SetCommunicating(isCommunicating)
        IsCommunicating = isCommunicating
    end

    --请求记录
    function XFunctionCommunicationManager.ReqMarkCommunication(id)
        XPlayer.ChangeCommunicationMarks(id)
    end

    --检测功能开关
    function XFunctionCommunicationManager.CheckFuncDisable()
        return XSaveTool.GetData(XPrefs.CommunicationTrigger)
    end

    function XFunctionCommunicationManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.CommunicationTrigger, DisableFunction)
    end

    XFunctionCommunicationManager.Init()
    return XFunctionCommunicationManager
end