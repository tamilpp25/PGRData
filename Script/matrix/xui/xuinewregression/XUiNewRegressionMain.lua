local XUiNewRegressionMain = XLuaUiManager.Register(XLuaUi, "UiReturnActivity")

function XUiNewRegressionMain:OnAwake()
    self.NewRegressionManager = XDataCenter.NewRegressionManager
    -- 活动子管理器
    self.ChildDatas = {}
    -- 活动子面板信息
    self.ChildPanelInfoDic = {}
    -- 当前打开的子页面下标
    self.CurrentIndex = 1
    -- 注册资源面板
    XUiHelper.NewPanelActivityAsset(self.NewRegressionManager.GetAssetItemIds(), self.PanelAssetitems)
    self:RegisterUiEvents()
end

function XUiNewRegressionMain:OnStart()
    -- 刷新时间范围
    self:SetTimeRange()
    -- 设置自动关闭和倒计时
    self:SetAutoCloseInfo(self.NewRegressionManager.GetEndTime(), function(isClose)
        self:EmitSignal("UpdateWithSecond", isClose)
        if isClose then
            self.NewRegressionManager.HandleActivityEndTime()
            return
        else
            self:SetTime()
        end
        -- 检查子活动是否过期
        local childData = self.ChildDatas[self.CurrentIndex]
        if (childData) and not childData.Manager:GetIsOpen() then
            XUiManager.TipErrorWithKey("NewRegressChildActivityTimeout")
            -- 隐藏掉过期活动的入口
            childData.Button.gameObject:SetActiveEx(false)
            -- 找到没有过期的活动，打开他
            for index, data in ipairs(self.ChildDatas) do
                if data.Manager:GetIsOpen() then
                    self.PanelBtnTab:SelectIndex(index)
                    return
                end
            end
            -- 如果都过期了，直接关闭主页面
            self.NewRegressionManager.HandleActivityEndTime()
        end
    end, nil, 1)
    -- 刷新标题
    local currentActivityState = self.NewRegressionManager.GetActivityState()
    -- 回归
    self.PanelRegression.gameObject:SetActiveEx(currentActivityState == XNewRegressionConfigs.ActivityState.InRegression)
    -- 活跃
    self.PanelActive.gameObject:SetActiveEx(currentActivityState == XNewRegressionConfigs.ActivityState.NotInRegression or currentActivityState == XNewRegressionConfigs.ActivityState.RegressionEnded)
    -- 创建活动按钮tabs
    self:CreateBtnTabs()
    -- 检查自动播放剧情
    XDataCenter.NewRegressionManager.CheckAutoPlayStory()
end

function XUiNewRegressionMain:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshBtnsRedPoint()
    for _, data in pairs(self.ChildPanelInfoDic) do
        if data.instanceProxy and data.instanceProxy.OnEnable then
            data.instanceProxy:OnEnable()
        end
    end
end

function XUiNewRegressionMain:OnDisable()
    for _, data in pairs(self.ChildPanelInfoDic) do
        if data.instanceProxy and data.instanceProxy.OnDisable then
            data.instanceProxy:OnDisable()
        end
    end
    self.Super.OnDisable(self)
end

function XUiNewRegressionMain:OnDestroy()
    for _, data in pairs(self.ChildPanelInfoDic) do
        if data.instanceProxy and data.instanceProxy.OnDestroy then
            data.instanceProxy:OnDestroy()
        end
    end
    self.Super.OnDestroy(self)
end

--######################## 私有方法 ########################

function XUiNewRegressionMain:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
end

function XUiNewRegressionMain:CreateBtnTabs()
    self.BtnTabPrefab.gameObject:SetActiveEx(false)
    -- 创建所有子活动的入口按钮
    local buttons = {}
    local managers = self.NewRegressionManager.GetEnableChildManagers()
    local go, button
    for index, manager in ipairs(managers) do
        go = XUiHelper.Instantiate(self.BtnTabPrefab, self.PanelBtnTab.transform)
        go.gameObject:SetActiveEx(true)
        button = go:GetComponent("XUiButton")
        button:SetNameByGroup(0, manager:GetButtonName())
        table.insert(buttons, button)
        self.ChildDatas[index] = {
            Manager = manager,
            Button = button
        }
    end
    self.PanelBtnTab:Init(buttons, function(tabIndex)
        self:RefreshContainer(tabIndex)
    end)
    if #self.ChildDatas > 0 then
        self.PanelBtnTab:SelectIndex(1)
    end
end

function XUiNewRegressionMain:RefreshBtnsRedPoint()
    for _, data in ipairs(self.ChildDatas) do
        data.Button:ShowReddot(data.Manager:GetIsShowRedPoint())
    end
end

-- 刷新容器
function XUiNewRegressionMain:RefreshContainer(index)
    if self._CopyPanelContainer == nil then
        self._CopyPanelContainer = XUiHelper.Instantiate(self.PanelContainer, self.Transform)
    end
    local manager = self.ChildDatas[index].Manager
    self.ChildPanelInfoDic = self.ChildPanelInfoDic or {}
    -- 隐藏其他的子面板
    for key, data in pairs(self.ChildPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == index)
    end
    local childPanelData = self.ChildPanelInfoDic[index]
    local parent = self._CopyPanelContainer
    -- 创建子管理器提供的面板数据
    if childPanelData == nil then
        childPanelData = manager:GetPanelContrlData()
        local copyParent = XUiHelper.Instantiate(parent, self.PanelContainer.transform).transform
        -- copyParent:SetParent(self.PanelContainer)
        childPanelData.uiParent = copyParent
        self.ChildPanelInfoDic[index] = childPanelData
    end
    -- 加载子面板实体
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载子面板代理
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo, self)
        childPanelData.instanceProxy = instanceProxy
        if CheckClassSuper(instanceProxy, XSignalData) then
            -- 对子信号数据的管理
            self:AddChildSignalData(instanceProxy)
            -- 连接子信号刷新红点通知
            instanceProxy:ConnectSignal("RefreshRedPoint", self, self.RefreshBtnsRedPoint)
        end
    end
    -- 清除旧计时器
    self:GetSignalData():RemoveConnectSignalWithName("UpdateWithSecond")
    -- 注册代理计时器
    if instanceProxy.UpdateWithSecond then
        self:GetSignalData():ConnectSignal("UpdateWithSecond", instanceProxy, instanceProxy.UpdateWithSecond)
    end
    -- 设置子面板代理参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    if #proxyArgs <= 0 then
        instanceProxy:SetData(manager)    
    else
        instanceProxy:SetData(table.unpack(proxyArgs), manager)
    end
    --重新注册资源面板
    if manager.IsDiscount and manager:IsDiscount() then
        XUiHelper.NewPanelActivityAsset({XDataCenter.ItemManager.ItemId.HongKa}, self.PanelAssetitems)
    else
        XUiHelper.NewPanelActivityAsset(self.NewRegressionManager.GetAssetItemIds(), self.PanelAssetitems)
    end
    --海外修改，屏蔽虹卡资源显示
    if manager:GetButtonName() == "復帰プレゼント" then
        self.PanelAssetitems.gameObject:SetActiveEx(false)
    else
        self.PanelAssetitems.gameObject:SetActiveEx(true)
    end
    self.CurrentIndex = index
    -- 播放切换动画
    if self.AnimSwitch then self.AnimSwitch:Play() end
end

function XUiNewRegressionMain:SetTimeRange()
    local beginTime = self.NewRegressionManager.GetStartTime()
    local endTime = self.NewRegressionManager.GetEndTime()
    local content = string.format( "%s-%s"
        , XTime.TimestampToGameDateTimeString(beginTime, "yyyy.MM.dd")
        , XTime.TimestampToGameDateTimeString(endTime, "MM.dd"))
    self.TxtRegressionTimeRange.text = content
    self.TxtActiveTimeRange.text = content
end

function XUiNewRegressionMain:SetTime()
    local content = self.NewRegressionManager.GetLeaveTimeStr()
    self.TxtRegressionTime.text = content
    self.TxtActiveTime.text = content
end

return XUiNewRegressionMain