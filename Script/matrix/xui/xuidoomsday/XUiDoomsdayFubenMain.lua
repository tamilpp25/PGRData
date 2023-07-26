local XUiGridDoomsdayBuilding = require("XUi/XUiDoomsday/XUiGridDoomsdayBuilding")
local XUiGridDoomsdayResource = require("XUi/XUiDoomsday/XUiGridDoomsdayResource")
local XUiGridDoomsdayInhabitantAttr = require("XUi/XUiDoomsday/XUiGridDoomsdayInhabitantAttr")
local XUiDoomsdayDragZoomProxy = require("XUi/XUiDoomsday/XUiDoomsdayDragZoomProxy")
local MAX_BUILDING_NUM = 31 --最大建筑数量
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3

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
    self.PanelBroadCast.gameObject:SetActiveEx(false)
    self.BtnTarget:ShowReddot(false)
    self.DragProxy = XUiDoomsdayDragZoomProxy.New(self.PanelDrag, true)
    self.PanelStageContentOriginPos = self.PanelStageContent.localPosition
    self.Effect = self.Transform:Find("FullScreenBackground/Effect")
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

    self.FutureWeatherGirds = { self.ImgHerald }
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
    self:UpdateCorner()
end

function XUiDoomsdayFubenMain:OnDisable()
    self.PanelBroadCast.gameObject:SetActiveEx(false)
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
    self.PanelToday.CallBack = handler(self, self.OnClickPanelToday)
    self:RegisterClickEvent(self.PanelHeraldList, self.OnClickPanelToday)
    for eventType, btn in pairs(self.RemindBtns) do
        btn.CallBack = function()
            self:OnClickBtnEvent(eventType)
        end
    end
end

function XUiDoomsdayFubenMain:InitView()
    local stageId = self.StageId
    local stageData = self.StageData
    --self.TxtChapter.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Order")
    --self.TxtChapterName.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Name")

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
        function(curDay)
            --self.TxtLeftTime.text = CsXTextManagerGetText("DoomsdayFubenMainLeftDay", leftDay)
            self.TxtStayTime.text = CsXTextManagerGetText("DoomsdayFubenMainLeftDaySimple", curDay)
        end,
        "_Day"
    )
    
    --达成结局
    self:BindViewModelPropertyToObj(
            stageData,
            function(finishEndingId)
                local isEnd = XTool.IsNumberValid(finishEndingId)
                self.IsFinishEnd = isEnd
                if isEnd then
                    self.BtnNextDay:SetNameByGroup(0, CsXTextManagerGetText("DoomsdayEndCurStage"))
                else
                    self.BtnNextDay:SetNameByGroup(0, CsXTextManagerGetText("DoomsdayEndToday"))
                end
            end,
            "_FinishEndingId"
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
            local isEmpty = XTool.IsTableEmpty(unhealthyInhabitantInfoList)
            self.GridAttr.gameObject:SetActiveEx(not isEmpty)
            --只显示不健康状态下的属性
            self:RefreshTemplateGrids(
                self.PanelAttr,
                unhealthyInhabitantInfoList,
                self.GridAttr,
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
    
    --天气
    self:BindViewModelPropertiesToObj(
        stageData,
        function(curWeatherId, futureWeathers)
            self.TxtWeatherToday.text = XDoomsdayConfigs.WeatherConfig:GetProperty(curWeatherId, "Name")
            self.ImgWeatherToday:SetSprite(XDoomsdayConfigs.WeatherConfig:GetProperty(curWeatherId, "Icon"))
            local effectPath = XDoomsdayConfigs.WeatherConfig:GetProperty(curWeatherId, "EffectPath")
            if not string.IsNilOrEmpty(effectPath) then
                self.Effect.gameObject:LoadUiEffect(effectPath)
            end
            for _, grid in ipairs(self.FutureWeatherGirds) do
                grid.gameObject:SetActiveEx(false)
            end
            for idx, wId in ipairs(futureWeathers) do
                local grid = self.FutureWeatherGirds[idx]
                if not grid then
                    grid = CSObjectInstantiate(self.ImgHerald, self.PanelHeraldList, false)
                    self.FutureWeatherGirds[idx] = grid
                end
                grid.gameObject:SetActiveEx(true)
                grid:SetSprite(XDoomsdayConfigs.WeatherConfig:GetProperty(wId, "Icon"))
            end
            
        end,
        "_CurWeatherId",
        "_FutureWeathers"
    )

    --播报
    self:BindViewModelPropertyToObj (
            stageData,
            function(broadcast)
                if not broadcast then return end
                if self.IsPlayBroadCast then return end
                local asyncAnim = asynTask(self.PlayAnimation, self)
                local icon, info = self.ImgBroadCastIcon, self.TxtBroadCastInfo
                local panelBroadCast = self.PanelBroadCast
                local selfGameObject = self.GameObject
                RunAsyn(function()
                    if not (icon and info and panelBroadCast and selfGameObject) then
                        return
                    end
                    while true do
                        if not XLuaUiManager.IsUiShow("UidoomsdayEvent") then
                            break
                        end
                        asynWaitSecond(0.1)
                    end
                    self.IsPlayBroadCast = true
                    icon:SetSprite(broadcast:GetIcon())
                    info.text = broadcast:GetDesc()
                    panelBroadCast.gameObject:SetActiveEx(true)
                    stageData:PopBroadcast()
                    asyncAnim("PanelBroadCastEnable")
                    asynWaitSecond(broadcast:GetDuration())
                    if selfGameObject.activeInHierarchy
                            and panelBroadCast.gameObject.activeInHierarchy then
                        asyncAnim("PanelBroadCastDisable")
                    end
                    panelBroadCast.gameObject:SetActiveEx(false)
                    stageData:UpdateCurBroadcast()
                    self.IsPlayBroadCast = false

                end)
            end,
            "_Broadcast"
    )
end

--==============================
 ---@desc 更新建筑MinX, MinY, MaxX, MaxY
 ---@return CS.UnityEngine.Vector2, CS.UnityEngine.Vector2
--==============================
function XUiDoomsdayFubenMain:UpdateCorner()
    local minX, minY, maxX, maxY = 0, 0, 0, 0
    --找到建筑的四边
    for index, _ in pairs(self.BuildingIndexList) do
        local tmpBuild = self["Stage"..index]
        local tmpMinX, tmpMinY = tmpBuild.localPosition.x, tmpBuild.localPosition.y - tmpBuild.sizeDelta.y / 2
        local tmpMaxX, tmpMaxY = tmpBuild.localPosition.x + tmpBuild.sizeDelta.x, tmpBuild.localPosition.y + tmpBuild.sizeDelta.y / 2
        minX = math.min(tmpMinX, minX)
        minY = math.min(tmpMinY, minY)
        maxX = math.max(tmpMaxX, maxX)
        maxY = math.max(tmpMaxY, maxY)
    end
    --计算Content的宽高
    local width = math.abs(minX) + math.abs(maxX)
    local height = math.abs(minY) + math.abs(maxY)
    --设置宽高
    self.PanelStageContent.sizeDelta = Vector2(width, height)
    --根据 左/上 边将所有建筑的偏移对齐 左/上
    for index, _ in pairs(self.BuildingIndexList) do
        local tmpBuild = self["Stage"..index]
        local pos = tmpBuild.localPosition
        pos.x = pos.x - (width / 2 - math.abs(minX))
        pos.y = pos.y + (height / 2 - math.abs(maxY))
        tmpBuild.localPosition = pos
    end
end

function XUiDoomsdayFubenMain:OnBtnBackClick()
    local title = CSXTextManagerGetText("DoomsdayBackConfirmTitle")
    local content = CSXTextManagerGetText("DoomsdayBackConfirmContent")
    --退出清除弹出事件缓存
    local closeFunc = function() 
        local stageData = self.StageData
        stageData:ClearPoppedEvent()
        self:Close()
    end
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, closeFunc)
end

function XUiDoomsdayFubenMain:OnClickBuilding(buildingIndex)
    local tmpBuild
    for index, inId in pairs(self.BuildingIndexList) do
        local isSelect = inId == buildingIndex
        if isSelect then
            tmpBuild = self["Stage"..index]
        end
        self:GetGrid(index, "BuildingGrids"):SetSelect(isSelect)
    end
    self:FocusBuilding(tmpBuild)

    XLuaUiManager.Open("UiDoomsdayFubenLineDetail", self.StageId, buildingIndex, handler(self, self.OnStageDetailClose))
end

function XUiDoomsdayFubenMain:OnStageDetailClose()
    for index, inStageId in pairs(self.BuildingIndexList) do
        self:GetGrid(index, "BuildingGrids"):SetSelect(false)
    end
    self:CancelFocus()
end

function XUiDoomsdayFubenMain:FocusBuilding(buildingTrans, widthRatio, heightRatio)
    if not buildingTrans then return end
    widthRatio = widthRatio or 0.27
    heightRatio = heightRatio or 0.5
    local duration = XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration
    local minScreenPos = Vector2(CS.UnityEngine.Screen.width * widthRatio, CS.UnityEngine.Screen.height * heightRatio)
    local _, midPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.PanelStageContent, minScreenPos, CS.UnityEngine.Camera.main)
    local offset = Vector3(midPos.x, midPos.y, 0) - buildingTrans.localPosition
    
    offset.x = offset.x * self.PanelStageContent.localScale.x
    offset.y = offset.y * self.PanelStageContent.localScale.y
    self.TargetBuildPos = self.PanelStageContent.localPosition
    self.PanelStageContent.transform:DOLocalMove(self.TargetBuildPos + offset, duration)
end

function XUiDoomsdayFubenMain:CancelFocus()
    if not self.TargetBuildPos then
        return
    end
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStageContent, self.TargetBuildPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function ()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiDoomsdayFubenMain:OnClickBtnEvent(eventType)
    local event = self.RemindEventTypeDic[eventType]
    if not event then
        return
    end

    XDataCenter.DoomsdayManager.EnterEventUi(self.StageId, event)
end

function XUiDoomsdayFubenMain:OnClickBtnNextDay()
    if self.IsFinishEnd then
        --结束本关
        XDataCenter.DoomsdayManager.FinishStage(self.StageId)
    else
        --结束当天
        XDataCenter.DoomsdayManager.EnterNextDay(self.StageId)
    end
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

function XUiDoomsdayFubenMain:OnClickPanelToday()
    
    XLuaUiManager.Open("UidoomsdayWeather", self.StageId)
end

return XUiDoomsdayFubenMain
