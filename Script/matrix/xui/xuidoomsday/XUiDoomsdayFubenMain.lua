local XUiGridDoomsdayBuilding = require("XUi/XUiDoomsday/XUiGridDoomsdayBuilding")
local XUiGridDoomsdayResource = require("XUi/XUiDoomsday/XUiGridDoomsdayResource")
local XUiGridDoomsdayInhabitantAttr = require("XUi/XUiDoomsday/XUiGridDoomsdayInhabitantAttr")
local XUiDoomsdayDragZoomProxy = require("XUi/XUiDoomsday/XUiDoomsdayDragZoomProxy")
local MAX_BUILDING_NUM = 31 --最大建筑数量

local XUiDoomsdayFubenMain = XLuaUiManager.Register(XLuaUi, "UiDoomsdayFubenMain")

function XUiDoomsdayFubenMain:OnAwake()
    self.RemindBtns = {
        [XDoomsdayConfigs.EVENT_TYPE.MAIN] = self.BtnRemindMain,
        [XDoomsdayConfigs.EVENT_TYPE.NORMAL] = self.BtnRemindNormal,
        [XDoomsdayConfigs.EVENT_TYPE.EXPLORE] = self.BtnRemindExplore
    }

    self.BtnExplore:ShowReddot(false)
    self.BtnPeople.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp = self:FindComponent("BtnHelp", "XUiButton")
    self.BtnTarget:ShowReddot(false)
    self.DragPanel = self:FindComponent("PanelDrag","XDragZoomComponent")
    self.DragProxy = XUiDoomsdayDragZoomProxy.New(self.DragPanel)
    self:AutoAddListener()
end

function XUiDoomsdayFubenMain:OnStart(stageId)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.RemindEventTypeDic = {}

    self.BuildingParents = {}
    local count = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MaxBuildingCount")
    for index = 1, count do
        if index > MAX_BUILDING_NUM then
            XLog.Error(
                string.format(
                    "XUiDoomsdayFubenMain:OnStart error: 关卡最大建筑数量错误, 超出UI上限:%d, stageId:%d, 配置路径:%s",
                    MAX_BUILDING_NUM,
                    stageId,
                    XDoomsdayConfigs.StageConfig:GetPath()
                )
            )
            return
        end
        self.BuildingParents[index] = self["Stage" .. index]
    end
    for index = count + 1, MAX_BUILDING_NUM do
        self.BuildingParents[index] = self["Stage" .. index]
    end

    self:InitView()
end

function XUiDoomsdayFubenMain:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.DoomsdayManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateView()
end

function XUiDoomsdayFubenMain:OnGetEvents()
    return {
        XEventId.EVENT_DOOMSDAY_ACTIVITY_END
    }
end

function XUiDoomsdayFubenMain:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_DOOMSDAY_ACTIVITY_END then
        if XDataCenter.DoomsdayManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiDoomsdayFubenMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:BindHelpBtn()
    self.BtnNextDay.CallBack = handler(self, self.OnClickBtnNextDay)
    self.BtnExplore.CallBack = handler(self, self.OnClickBtnExplore)
    self.BtnTarget.CallBack = handler(self, self.OnClickBtnTarget)
    self.BtnInhabitant.CallBack = handler(self, self.OnClickBtnInhabitant)
    for eventType, btn in pairs(self.RemindBtns) do
        btn.CallBack = function()
            self:OnClickBtnEvent(eventType)
        end
    end
end

function XUiDoomsdayFubenMain:InitView()
    local stageId = self.StageId

    self.TxtChapter.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Order")
    self.TxtChapterName.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Name")

    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    self.TxtMainTarget.text = XDoomsdayConfigs.TargetConfig:GetProperty(mainTargetId, "Desc")

    --关卡事件按钮
    for eventType, btn in pairs(self.RemindBtns) do
        btn:SetNameByGroup(0, XDoomsdayConfigs.GetEventTypeRemindDesc(eventType))
    end
end

function XUiDoomsdayFubenMain:UpdateView()
    local stageId = self.StageId
    local stageData = self.StageData

    --剩余天数
    self:BindViewModelPropertyToObj(
        stageData,
        function(leftDay)
            self.TxtLeftTime.text = CsXTextManagerGetText("DoomsdayFubenMainLeftDay", leftDay)
        end,
        "_LeftDay"
    )

    --关卡目标
    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    self:BindViewModelPropertiesToObj(
        stageData:GetTarget(mainTargetId),
        function(value, maxValue)
            self.TxtTargetProgress.text = string.format("%d/%d", value, maxValue)
            self.ImgProgressTarget.fillAmount = XUiHelper.GetFillAmountValue(value, maxValue)
        end,
        "_Value",
        "_MaxValue"
    )

    --关卡事件
    self:BindViewModelPropertyToObj(
        stageData,
        function(remindDic)
            for _, eventType in pairs(XDoomsdayConfigs.EVENT_TYPE) do
                local btn = self.RemindBtns[eventType]
                btn.gameObject:SetActiveEx(remindDic[eventType] and true or false)
            end
            self.RemindEventTypeDic = remindDic
        end,
        "_EventTypeRemindDic"
    )

    --资源栏
    self:RefreshTemplateGrids(
        self.GridResource,
        XDoomsdayConfigs.GetResourceIds(),
        self.PanelResource,
        function()
            return XUiGridDoomsdayResource.New(stageId)
        end,
        "ResourceGrids"
    )

    --居民信息
    self:BindViewModelPropertiesToObj(
        stageData,
        function(idleCount, count)
            self.TxtInhabitantCount.text = string.format("%d/%d", idleCount, count)
        end,
        "_IdleInhabitantCount",
        "_InhabitantCount"
    )

    --居民异常状态
    self:BindViewModelPropertyToObj(
        stageData,
        function(unhealthyInhabitantInfoList)
            --只显示不健康状态下的属性
            self:RefreshTemplateGrids(
                self.GridAttr,
                unhealthyInhabitantInfoList,
                self.PanelInhabitant,
                XUiGridDoomsdayInhabitantAttr,
                "InhabitantAttrGrids"
            )
        end,
        "_UnhealthyInhabitantInfoList"
    )

    --建筑
    self.BuildingIndexList = stageData:GetBuildingIndexList()
    self:RefreshTemplateGrids(
        self.GridDoomsdayBuild,
        self.BuildingIndexList,
        self.BuildingParents,
        function()
            return XUiGridDoomsdayBuilding.New(stageId, handler(self, self.OnClickBuilding))
        end,
        "BuildingGrids"
    )
    for index = #self.BuildingIndexList + 1, #self.BuildingParents do
        self.BuildingParents[index].gameObject:SetActiveEx(false)
    end

    --建筑附加随机事件
    local buidingEventDic = stageData:GetBuildingEventDic()
    for buildingIndex, event in pairs(buidingEventDic) do
        self:GetGrid(buildingIndex, "BuildingGrids"):SetEvent(event)
    end

    --探索按钮
    self:BindViewModelPropertyToObj(
        stageData,
        function(unlock)
            self.BtnExplore:SetDisable(not unlock)
        end,
        "_CanExplore"
    )
end

function XUiDoomsdayFubenMain:OnBtnBackClick()
    local title = CSXTextManagerGetText("DoomsdayBackConfirmTitle")
    local content = CSXTextManagerGetText("DoomsdayBackConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, handler(self, self.Close))
end

function XUiDoomsdayFubenMain:OnClickBuilding(buildingIndex)
    for index, inId in pairs(self.BuildingIndexList) do
        self:GetGrid(index, "BuildingGrids"):SetSelect(inId == buildingIndex)
    end

    XLuaUiManager.Open("UiDoomsdayFubenLineDetail", self.StageId, buildingIndex, handler(self, self.OnStageDetailClose))
end

function XUiDoomsdayFubenMain:OnStageDetailClose()
    for index, inStageId in pairs(self.BuildingIndexList) do
        self:GetGrid(index, "BuildingGrids"):SetSelect(false)
    end
end

function XUiDoomsdayFubenMain:OnClickBtnEvent(eventType)
    local event = self.RemindEventTypeDic[eventType]
    if not event then
        return
    end

    XDataCenter.DoomsdayManager.EnterEventUi(self.StageId, event)
end

function XUiDoomsdayFubenMain:OnClickBtnNextDay()
    XDataCenter.DoomsdayManager.EnterNextDay(self.StageId)
end

function XUiDoomsdayFubenMain:OnClickBtnInhabitant()
    XLuaUiManager.Open("UiDoomsdayPeople", self.StageId)
end

function XUiDoomsdayFubenMain:OnClickBtnTarget()
    XLuaUiManager.Open("UiDoomsdayFubenTask", self.StageId)
end

function XUiDoomsdayFubenMain:OnClickBtnExplore()
    if not self.StageData:GetProperty("_CanExplore") then
        XUiManager.TipText("DoomsdayExploreLock")
        return
    end
    XLuaUiManager.Open("UiDoomsdayExplore", self.StageId)
end

return XUiDoomsdayFubenMain
