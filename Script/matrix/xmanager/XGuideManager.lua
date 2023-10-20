XGuideManagerCreator = function()

    ---@class XGuideManager 引导管理类
    ---@field
    local XGuideManager = {}

    -- 引导组记录状态
    XGuideManager.RecordState = {
        None = 0, --
        RequestRecord = 1, --请求记录中
        Record = 2, --已记录
    }

    XGuideManager.GuideType = {
        Default = 1,
        Fight = 2,
    }
    
    local PROTOCOL_REQUEST_NAME = {
        ReqOpenGuide = "GuideOpenRequest",
        ReqCompleteGuide = "GuideCompleteRequest",
        ReqCompleteGuideGroup = "GuideGroupFinishRequest",
    }
    
    local SKIP_CHECK_UI_NAME = {
        UiAutoFightTip      = "UiAutoFightTip",
        UiLeftPopupTip      = "UiLeftPopupTip",
        UiTipLayer          = "UiTipLayer",
        UiNoticeTips        = "UiNoticeTips",
        UiAchievementTips   = "UiAchievementTips",
        UiPortraitTip       = "UiPortraitTip",
        UiFightNieRTips     = "UiFightNieRTips",
        UiPartnerPopupTip   = "UiPartnerPopupTip",
        UiRestaurantRadio   = "UiRestaurantRadio",
        UiLeftPopupTips     = "UiLeftPopupTips",
        UiRogueSimComponent = "UiRogueSimComponent",
    }
    
    -- 该事件类型包括了引导的触发、完成类型
    XGuideManager.GuideEventType = {
        TeamLevel            = 1, --战队等级：等级
        PassStage            = 2, --副本相关：副本id， 是否通关
        CompleteTask        = 3, --完成任务：任务id
        FunctionOpen        = 4, --功能开启：功能id
        GainCharacter        = 5, --获得角色：角色id
        GainEquip            = 6, --获得装备：装备id
        GainItem            = 7, --获得道具：道具id，数量
        CharacterUpgrade    = 8, --角色培养：角色id，等级，改造阶段， 晋升等级
        CharacterUpgradeSkill = 9, --角色技能：角色id， 技能id， 等级
        EquipUpgrade        = 10, --装备升级：装备id， 等级，突破次数，觉醒等级
        CompleteGuide        = 11, --完成引导：引导组id
        CompleteGuideStep    = 12, --完成步骤：步骤id
        OpenPanel            = 13, --打开界面：Ui名
        ClosePanel            = 14, --关闭界面：UI名
        ClickSpecify        = 15, --点击指定区域
    }

    XGuideManager.GroupOpenType = {
        FightTeamLevel = 1, --战队等级：等级
        PassStage    = 2, --通过副本：副本id
        FunctionOpen    = 3, --功能开启：功能id
        GainCharacter = 4, --获得角色：角色id
        GainEquip    = 5, --获得装备：装备id
        GainItem        = 6, --获得道具：道具id
        CompleteGuide = 7, --完成引导：引导组id
        CompleteTask    = 8, --完成任务：任务id
    }

    XGuideManager.GroupCompleteType = {
        CompleteStep        = 1, --步骤结束：步骤id
        Stage            = 2, --副本相关：副本id， 是否通关
        CompleteTask        = 3, --完成任务：任务id
        CharacterDevelop    = 4, --角色培养：角色id，等级，改造阶段， 晋升等级
        CharacterSkill    = 5, --角色技能：角色id， 技能id， 等级
        EquipUpgrade        = 6, --装备升级：装备id， 等级，突破次数，觉醒等级
        GainItem            = 7, --获得道具：道具id， 数量
        EquipPutOn        = 8, --穿装备：装备id
        UseItem            = 9, --使用道具：道具id，数量
        PartUpgrade        = 10, --部件升级：角色id，部件id，部件等级
        TeamChanged        = 11, --战斗编队
        CompleteCourse    = 12, --完成历程：副本id
        GainReward        = 13, --领取奖励 ：奖励ID
    }

    XGuideManager.StepOpenType = {
        OpenPanel    = 1, --打开界面：Ui名
        ClosePanel    = 2, --关闭界面：UI名
        CompleteStep    = 3, --完成步骤：步骤id
        GainItem        = 4, --获得道具：道具id
        CompleteTask    = 5, --完成任务：任务id
        CustomEvent    = 6, --自定义消息 ：参数
        GainReward    = 7, --领取奖励 ：奖励ID
    }

    XGuideManager.StepCompleteType = {
        DefaultClick    = 0, --默认：点击
        OpenPanel    = 1, --打开界面：UI名
        ClosePanel    = 2, --关闭界面：UI名
        GainItem        = 3, --获得道具：道具id
        CompleteTask    = 4, --完成任务：任务id
        CustomEvent    = 5, --自定义消息 ：参数
        GainReward    = 6, --领取奖励 ：奖励ID
    }
    
    -- 埋点类型
    XGuideManager.BuryingPointType = {
        Start   = 1, --引导开始
        Skip    = 2, --引导跳过
        End     = 3, --引导结束
    }

    local GuideAgent = nil           --引导Agent

    -- local WaitingGuide = nil          --当前等激活的引导
    local ActiveGuide = nil          --当前引导
    local GuideData = {}             -- 玩家引导数据
    local DisableFunction = false    --功能屏蔽标记（调试模式时使用）
    local DisableGuide = false       -- 游戏内禁用引导(避免像三周年签到自动弹窗界面场景预览双开UiMain导致大多数引导可能开在预览上)
    local IsGuiding = false

    local WaitingGuideList = {}

    local NextGridCb = nil
    local CbProxy = nil

    function XGuideManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, XGuideManager.HandleSignOut)

        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, function(evt, ui)
            XGuideManager.HandleUiOpen(ui[0].UiData.UiName)
        end)

        --引导开启
        CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, XGuideManager.OnGuideStart)
        --引导结束
        CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_END, XGuideManager.OnGuideEnd)
    end

    --初始化
    function XGuideManager.InitGuideData(datas)
        ActiveGuide = nil -- 当前引导
        WaitingGuideList = {}
        DisableFunction = XMain.IsDebug and XGuideManager.CheckFuncDisable()
        DisableGuide = false
        for _, v in pairs(datas) do
            GuideData[v] = v
        end
    end

    function XGuideManager.OnGuideStart(guideId)
        IsGuiding = true
        XGuideManager.RecordBuryingPoint(XGuideManager.BuryingPointType.Start)
    end

    function XGuideManager.OnGuideEnd(guideId)
        XGuideManager.RecordBuryingPoint(XGuideManager.BuryingPointType.End)
        IsGuiding = false
        XGuideManager.ResetGuide()

        XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
    end

    --检测引导开启
    function XGuideManager.CheckGuideOpen()
        if DisableFunction then
            return false
        end
        if DisableGuide then
            return false
        end

        if ActiveGuide and IsGuiding then
            return true
        end
        
        XGuideManager.FindActiveGuide()

        local result = false
        local removeIndex = -1
        for i, v in ipairs(WaitingGuideList) do
            local waitingGuide = v
            if (waitingGuide and waitingGuide.GuideType == XGuideManager.GuideType.Default) then
                if XGuideManager.TryActiveGuide(waitingGuide) then
                    removeIndex = i
                    result = true
                    break
                end
            end
        end

        if removeIndex > 0 then
            table.remove(WaitingGuideList, removeIndex)
        end

        return result
    end

    --创建引导主体
    function XGuideManager:CreateGuideAgent()
        local guideAgent = CS.UnityEngine.GameObject("GuideAgent")
        --进入战斗后会销毁NormalScene, 所以放到DonDestroyOnLoad场景中,由引导统一控制
        CS.UnityEngine.Object.DontDestroyOnLoad(guideAgent)
        GuideAgent = guideAgent:AddComponent(typeof(CS.BehaviorTree.XAgent))
        GuideAgent.ProxyType = "Guide"
        GuideAgent:InitProxy()
    end

    --开始引导
    function XGuideManager:PlayGuide(id)
        if not GuideAgent or not GuideAgent:Exist() then
            XGuideManager:CreateGuideAgent()
        end

        GuideAgent.gameObject:SetActive(true)
        XLuaBehaviorManager.PlayId(id, GuideAgent)
    end

    -- 满足游戏内某些界面禁用引导所需接口
    function XGuideManager.SetDisableGuide(isDisable)
        DisableGuide = isDisable
    end

    --检测引导开关
    function XGuideManager.CheckFuncDisable()
        return XSaveTool.GetData(XPrefs.GuideTrigger)
    end

    function XGuideManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.GuideTrigger, DisableFunction)
    end

    --重置引导
    function XGuideManager.ResetGuide()
        if GuideAgent and GuideAgent:Exist() then
            GuideAgent.gameObject:SetActive(false)

            if GuideAgent.Proxy.LuaAgentProxy then
                GuideAgent.Proxy.LuaAgentProxy.UiGuide = nil
            end
        end

        if XMain.IsDebug then
            IsGuiding = false
        end

        ActiveGuide = nil -- 当前引导
        XLuaUiManager.Close("UiGuide")
    end

    --重载引导配置 即使重载资源 Agent还是会引用旧的内存 所以会不生效
    function XGuideManager.ReloadAgent()
        XGuideManager.ResetGuide()
        if GuideAgent and GuideAgent:Exist() then
            XUiHelper.Destroy(GuideAgent.gameObject)
            GuideAgent = nil
        end
    end
    
    function XGuideManager.HandleUiOpen(UiName)
        if IsGuiding then
            return
        end

        if XDataCenter.FunctionEventManager.IsPlaying() then
            return
        end

        if XUiManager.IsHideFunc or DisableGuide or DisableFunction
                or not XLoginManager.IsStartGuide() then
            return
        end

        XGuideManager.FindActiveGuide()
        
        local bActive = false

        local removeIndex = -1
        for i, v in ipairs(WaitingGuideList) do
            local activeUis = string.Split(v.ActiveUi, '|')
            for _, v2 in ipairs(activeUis) do
                if v2 == UiName then
                    bActive = true
                    break
                end
            end

            if bActive then
                if XGuideManager.TryActiveGuide(v) then
                    removeIndex = i
                    break
                end
            end

            bActive = false
        end
        if removeIndex > 0 then
            table.remove(WaitingGuideList, removeIndex)
        end
    end

    --尝试开启引导
    function XGuideManager.TryActiveGuide(guide)
        if guide == nil then
            return false
        end

        -- 远程配置屏蔽引导，除了新手关1、2、3（可以移到CheckGuideOpen方法中）
        if XUiManager.IsHideFunc then
            return
        end

        if DisableGuide then
            return
        end

        if not XLoginManager.IsStartGuide() then
            return
        end

        if guide.GuideType ~= XGuideManager.GuideType.Default then
            return false
        end

        local bActive = false
        
        local checkFunc = function(luaUi, nodes)
            if not luaUi then
                return false
            end
            --没有需要检查的节点，默认通过
            if XTool.IsTableEmpty(nodes) or string.IsNilOrEmpty(nodes) then
                return true
            end
            for _, node in ipairs(nodes or {}) do
                local findIndex = string.find(node, "/")
                local tmp
                --根据下标查找
                if findIndex then
                    tmp = luaUi.Transform:FindTransformWithSplit(node)
                else --根据名称查找
                    tmp = luaUi.Transform:FindTransform(node)
                end
                --存在且显示
                if not XTool.UObjIsNil(tmp) 
                        and tmp.gameObject.activeInHierarchy then
                    return true
                end
            end
            return false
        end

        local activeUis = string.Split(guide.ActiveUi, '|')
        local topUiName = CsXUiManager.Instance:GetTopUiName()
        local index = 1
        while true do
            if not SKIP_CHECK_UI_NAME[topUiName] then
                break
            end
            topUiName = CsXUiManager.Instance:GetTopXUiName(index)
            index = index + 1
        end
        for _, v in ipairs(activeUis) do
            --if CsXUiManager.Instance:IsUiShow(v) and CsXUiManager.Instance:FindTopUi(v) then
            --当前Ui正在展示 && 处于栈顶
            if CsXUiManager.Instance:IsUiShow(v) and topUiName == v then
                local luaUi = XLuaUiManager.GetTopLuaUi(v)
                local checkNodes = string.Split(guide.CheckNodeActive, '|')
                if checkFunc(luaUi, checkNodes) then
                    bActive = true
                    break
                end
            end
        end

        if not bActive then
            return false
        end

        ActiveGuide = guide
        XGuideManager:PlayGuide(ActiveGuide.Id)
        return true
    end

    ---查找激活的引导
    function XGuideManager.FindActiveGuide()
        local IsOpen = false

        WaitingGuideList = {}
        local guideGroupTemplates = XGuideConfig.GetGuideGroupTemplates()
        for _, temp in pairs(guideGroupTemplates) do
            if not XGuideManager.CheckIsGuide(temp.Id) and temp.Ignore == 0 then
                for _, v in pairs(temp.ConditionId) do
                    if v and v ~= 0 then
                        IsOpen = XConditionManager.CheckCondition(v)
                        if not IsOpen then
                            break
                        end
                    end
                end

                if IsOpen then
                    XGuideManager.SetActiveGuide(temp)
                    IsOpen = false
                end
            end
        end
    end

    --激活引导
    function XGuideManager.SetActiveGuide(guide)
        WaitingGuideList = WaitingGuideList or {}
        local insetIndex = -1
        if #WaitingGuideList <= 0 then
            insetIndex = 1
        end

        for i, v in ipairs(WaitingGuideList) do
            if guide.Priority < v.Priority then
                insetIndex = i
                break
            end
        end

        if insetIndex <= 0 then
            table.insert(WaitingGuideList, guide)
        else
            table.insert(WaitingGuideList, insetIndex, guide)
        end

        -- if (WaitingGuide == nil) then
        --     WaitingGuide = guide
        -- else
        --     if (guide.Priority < WaitingGuide.Priority) then
        --         WaitingGuide = guide
        --     end
        -- end
    end

    --完成引导
    -- function XGuideManager.CompleteGuide()
    --     if not ActiveGuide then
    --         return
    --     end

    --     if (IsRecord == XGuideManager.RecordState.Record) then
    --         local guideId = ActiveGuide.Id
    --         ActiveGuide = nil
    --         IsRecord = XGuideManager.RecordState.None
    --     end
    -- end

    -- 外部调用接口end --
    -- 查询相关begin --
    function XGuideManager.CheckIsGuide(guideId)
        if not GuideData then
            return false
        end

        for _, value in pairs(GuideData) do
            if value == guideId then
                return true
            end
        end

        return false
    end

    -- 查询相关end --
    -- 获取下一场新手战斗
    function XGuideManager.GetNextGuideFight()
        if DisableFunction then
            return false
        end
        if DisableGuide then
            return false
        end
        if ActiveGuide and IsGuiding then
            return false
        end

        XGuideManager.FindActiveGuide()

        local result = nil
        local removeIndex = -1
        for i, v in ipairs(WaitingGuideList) do
            local waitingGuide = v
            if (waitingGuide and waitingGuide.GuideType == XGuideManager.GuideType.Fight) then
                local cfg = XGuideConfig.GetGuideFightTemplatesById(waitingGuide.Id)
                if cfg then
                    removeIndex = i
                    result = cfg
                    break
                end
            end
        end

        if removeIndex > 0 then
            ActiveGuide = table.remove(WaitingGuideList, removeIndex)
        end

        return result
    end

    function XGuideManager.IsPrologueFight()
        local result = XGuideManager.GetNextGuideFight()
        if not result then
            return false
        end
        return result ~= nil
    end

    --是否是战斗引导
    function XGuideManager.CheckIsFightGuide()
        if ActiveGuide and ActiveGuide.GuideType == XGuideManager.GuideType.Fight then
            return true
        end

        return false
    end

    --是否正在引导
    --该接口在某些包强跳引导(ResetGuide)不会恢复IsGuiding
    function XGuideManager.CheckIsInGuide()
        return IsGuiding and ActiveGuide ~= nil
    end

    --处理登出
    function XGuideManager.HandleSignOut()
        XGuideManager.ResetGuide()
        if GuideAgent and GuideAgent:Exist() then
            CS.UnityEngine.GameObject.Destroy(GuideAgent.gameObject)
            GuideAgent = nil
        end
    end

    -- 消息相关begin --
    function XGuideManager.ReqGuideOpen(guideId, cb)
        XNetwork.Call(PROTOCOL_REQUEST_NAME.ReqOpenGuide, { GuideGroupId = guideId }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
            end

            if cb then
                cb()
            end
        end)
    end

    function XGuideManager.ReqGuideComplete(guideId, cb)
        XNetwork.Call(PROTOCOL_REQUEST_NAME.ReqCompleteGuide, { GuideGroupId = guideId }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
            else
                if response.RewardGoodsList then
                    XUiManager.OpenUiObtain(response.RewardGoodsList, nil)
                end

                XGuideManager.OnSyncGuideData(guideId)

            end

            if cb then
                cb()
            end
        end)
    end

    function XGuideManager.ReqCompleteGuideGroup(cb)
        if not ActiveGuide then
            if cb then
                cb()
            end
            return
        end

        local groupId = XGuideConfig.GetGuideGroupTemplatesById(ActiveGuide.Id).GroupId
        XNetwork.Call(PROTOCOL_REQUEST_NAME.ReqCompleteGuideGroup, { GroupId = groupId }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
            else
                if response.RewardGoodsList then
                    XUiManager.OpenUiObtain(response.RewardGoodsList, nil)
                end
                XGuideManager.OnSyncGuideGroupData(groupId)
            end
            if cb then
                cb()
            end
        end)
    end

    function XGuideManager.OnSyncGuideGroupData(groupId)
        local configData = XGuideConfig.GetGuideGroupTemplates()
        for k, v in pairs(configData) do
            if v.GroupId == groupId then
                GuideData[k] = k
            end
        end
        if ActiveGuide then
            local guideType = ActiveGuide.GuideType
            if guideType ~= XGuideManager.GuideType.Default then
                XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
            end
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUIDE_COMPLETED_SUCCESS)
    end

    function XGuideManager.OnSyncGuideData(guideId)
        if DisableFunction then
            return
        end
        if DisableGuide then
            return
        end

        GuideData[guideId] = guideId
        if ActiveGuide and (ActiveGuide.Id == guideId) then
            local guideType = ActiveGuide.GuideType
            if guideType ~= XGuideManager.GuideType.Default then
                XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
            end
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUIDE_COMPLETED_SUCCESS, guideId)
    end
    -- 消息相关end --

    -- V1.30 新动态列表(大量动画)兼容相关
    function XGuideManager.SetGridNextCb(cb, proxy)
        -- 设置侧边栏点击回调（因为指引会截断侧边栏滚动结束的函数，所以提前存储结束后的函数，在指引点击的时候就调用）
        NextGridCb = cb
        CbProxy = proxy
    end

    function XGuideManager.GetGridNextCb(cb, proxy)
        return NextGridCb
    end

    function XGuideManager.DoNextGridCb(...)
        if NextGridCb and CbProxy then
            NextGridCb(CbProxy, ...)
        end
    end
    
    -- 记录埋点
    function XGuideManager.RecordBuryingPoint(buryingPointType)
        if not ActiveGuide or not IsGuiding then
            return
        end
        local dict = {}
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["guide_id"] = ActiveGuide.Id
        dict["ui_name"] = XLuaUiManager.GetTopUiName()
        dict["type"] = buryingPointType
        CS.XRecord.Record(dict, "200014", "Guide")
    end

    XGuideManager.Init()

    return XGuideManager
end

XRpc.NotifyGuide = function(data)
    XDataCenter.GuideManager.OnSyncGuideData(data.GuideGroupId)
end