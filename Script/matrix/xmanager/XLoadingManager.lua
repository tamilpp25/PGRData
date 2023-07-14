LoadingType = {
    Fight = "10101", --战斗
    Dormitory = "902", --宿舍
    Restaurant = "903", --餐厅
    GuildDorm = "1901", --工会宿舍
}

XLoadingManagerCreator = function()
    local XLoadingManager = {}

    local CustomLoadingList = {}
    local ChangedFlag = false
    local CustomLoadingState = XSetConfigs.LoadingType.Default

    --初始化
    function XLoadingManager.Init()

    end

    --根据类型以及权重取出loading的tab数据
    function XLoadingManager.GetLoadingTab(type)
        if not type then
            return
        end

        if XUiManager.IsHideFunc then
            CustomLoadingState = XSetConfigs.LoadingType.Default
            type = XLoadingConfig.DEFAULT_TYPE
        end
        if CustomLoadingState == XSetConfigs.LoadingType.Custom
                and XLoadingConfig.CheckCustomAllowType(type)
                and #CustomLoadingList >= 1
                and math.random(1, 10000) <= XLoadingConfig.GetCustomRate() then
            local id = CustomLoadingList[math.random(#CustomLoadingList)]
            return XDataCenter.ArchiveManager.GetArchiveCgEntity(id), XSetConfigs.LoadingType.Custom
        else
            local loadingList = XLoadingConfig.GetCfgByType(type)

            if not loadingList then
                XLog.Error("不存在该类型的LoadingList配置，type =", type)
                return
            end

            return XTool.WeightRandomSelect(loadingList), XSetConfigs.LoadingType.Default
        end
    end

    function XLoadingManager.NotifyCustomLoadingData(data)
        if not data then return end
        CustomLoadingState = data.LoadingType
        CustomLoadingList = data.CgIds or {}
    end

    function XLoadingManager.SaveCustomLoading(list)
        CustomLoadingState = XSetConfigs.LoadingType.Custom
        CustomLoadingList = list
        XLoadingManager.RemoteSave()
        ChangedFlag = true
    end

    function XLoadingManager.GetCustomLoadingChanged()
        return ChangedFlag
    end

    function XLoadingManager.SetCustomLoadingChanged()
        ChangedFlag = false
    end

    function XLoadingManager.GetCustomLoadingList()
        return XTool.Clone(CustomLoadingList)
    end

    function XLoadingManager.GetCustomLoadingState()
        return CustomLoadingState
    end

    function XLoadingManager.SetCustomLoadingState(value)
        if CustomLoadingState == value then return end
        CustomLoadingState = value
        XLoadingManager.RemoteSave()
    end

    function XLoadingManager.RemoteSave()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive) then
            return
        end
        XNetwork.Call("SettingLoadingOptionRequest", { LoadingData = {
            LoadingType = CustomLoadingState,
            CgIds = CustomLoadingList,
        }}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end

    XLoadingManager.Init()

    return XLoadingManager
end

XRpc.NotifySettingLoadingOption = function(data)
    XDataCenter.LoadingManager.NotifyCustomLoadingData(data.LoadingData)
end
