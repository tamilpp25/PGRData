local XUiGridDoomsdayPlace = require("XUi/XUiDoomsday/XUiGridDoomsdayPlace")
local XUiGridDoomsdayResource = require("XUi/XUiDoomsday/XUiGridDoomsdayResource")
local XUiGridDoomsdayInhabitantAttr = require("XUi/XUiDoomsday/XUiGridDoomsdayInhabitantAttr")
local XUiDoomsdayDragZoomProxy = require("XUi/XUiDoomsday/XUiDoomsdayDragZoomProxy")

local MAX_PLACE_COUNT = 42 --最大探索地点数量
local EXPLORE_TEAM_NUM = 2 --探索小队数量
local ANIM_TIME = 0.5 --镜头移动动画时间
local PATH_GENERATOR_TIME = 0.8 --新地点生成，路径动画时长

local CSVector2 = CS.UnityEngine.Vector2
local CSVector3 = CS.UnityEngine.Vector3
local CSQuaternion = CS.UnityEngine.Quaternion

local PATH_NAME = "Line" --路径物体名

local XUiDoomsdayExplore = XLuaUiManager.Register(XLuaUi, "UiDoomsdayExplore")

function XUiDoomsdayExplore:OnAwake()
    self.BtnInhabitant = self.PanelInhabitant:GetComponent("XUiButton")
    self:AutoAddListener()
    
    self.GridDoomsdayStageCamp.gameObject:SetActiveEx(false)
    self.GridDoomsdayStage.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.DragProxy = XUiDoomsdayDragZoomProxy.New(self.PanelDrag)
    self.Effect = self.Transform:Find("SafeAreaContentPane/Effect")
    self.Line = {}
end

function XUiDoomsdayExplore:OnStart(stageId, focusPlaceId)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.PlaceGrids = {}
    self.TeamGrids = {}
    self.FocusPlaceId = focusPlaceId or XDoomsdayConfigs.StageConfig:GetProperty(stageId, "FirstPlace")
    local prefab = self.PanelStages:LoadPrefab(XDoomsdayConfigs.StageConfig:GetProperty(stageId, "PrefabPath"))
    self.MapPrefab = {}
    XTool.InitUiObjectByUi(self.MapPrefab, prefab)
    self.Waiting2AddPlace = {}
    self:InitView()
end

function XUiDoomsdayExplore:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.DoomsdayManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateView()
end

function XUiDoomsdayExplore:OnGetEvents()
    return {
        XEventId.EVENT_DOOMSDAY_ACTIVITY_END
    }
end

function XUiDoomsdayExplore:OnNotify(evt, ...)
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

function XUiDoomsdayExplore:AutoAddListener()
    self:BindHelpBtn()
    self:BindExitBtns()
    self.BtnTask.CallBack = handler(self, self.OnClickBtnTarget)
    self.BtnPosition.CallBack = handler(self, self.OnClickBtnPosition)
    self.BtnInhabitant.CallBack = handler(self, self.OnClickBtnInhabitant)
    for i = 1, EXPLORE_TEAM_NUM do
        self["BtnTeam0" .. i].CallBack = function()
            self:OnClickBtnTeam(i)
        end
    end
    
end

function XUiDoomsdayExplore:InitView()
    local stageId = self.StageId

    self.TxtTitle.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Name")

    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    self.BtnTask:SetName(XDoomsdayConfigs.TargetConfig:GetProperty(mainTargetId, "Desc"))
end

function XUiDoomsdayExplore:UpdateView()
    local stageId = self.StageId
    local stageData = self.StageData
    
    self:BindViewModelPropertyToObj(
            stageData,
            function(curWeatherId)
                local effectPath = XDoomsdayConfigs.WeatherConfig:GetProperty(curWeatherId, "EffectPath")
                if not string.IsNilOrEmpty(effectPath) then
                    self.Effect.gameObject:LoadUiEffect(effectPath)
                end
            end,
            "_CurWeatherId"
    )

    --剩余天数
    self:BindViewModelPropertyToObj(
        stageData,
        function(day)
            self.TxtTitleDate.text = CsXTextManagerGetText("DoomsdayFubenMainLeftDaySimple", day)
        end,
        "_Day"
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
            self.GridAttrList.gameObject:SetActiveEx(not isEmpty)
            --只显示不健康状态下的属性
            self:RefreshTemplateGrids(
                self.PanelAttr,
                unhealthyInhabitantInfoList,
                self.GridAttrList,
                XUiGridDoomsdayInhabitantAttr,
                "InhabitantAttrGrids"
            )
        end,
        "_UnhealthyInhabitantInfoList"
    )

    --探索地点
    self:BindViewModelPropertyToObj(
        stageData,
        function(unlockPlaceIds)
            self:RefreshPlaceGrid(unlockPlaceIds)
        end,
        "_UnlockPlaceIds"
    )

    --探索地点附加随机事件
    local placeEventDic = stageData:GetPlaceEventDic()
    for placeId, event in pairs(placeEventDic) do
        local grid = self.PlaceGrids[placeId]
        if grid then
            grid:SetEvent(event)
        end
    end

    --探索小队状态
    self:BindViewModelPropertiesToObj(
        stageData,
        function()
            for teamId = 1, EXPLORE_TEAM_NUM do
                local btn = self["BtnTeam0" .. teamId]
                local unlock = stageData:CanCreateTeam(teamId)

                local grid = self.TeamGrids[teamId]
                if not grid then
                    grid = XTool.InitUiObjectByUi({}, btn)
                    self.TeamGrids[teamId] = grid
                end

                local teamExist = stageData:CheckTeamExist(teamId)
                grid.PanelUnlock.gameObject:SetActiveEx(teamExist)
                grid.PanelCreat.gameObject:SetActiveEx(unlock and not teamExist)

                if teamExist then
                    local team = stageData:GetTeam(teamId)
                    self:BindViewModelPropertiesToObj(
                        team,
                        function(placeId, targetPlaceId, state)
                            --探索路径画线
                            if placeId ~= targetPlaceId then
                                self:DrawMoveLine(placeId, targetPlaceId,teamId)
                            end

                            grid.PanelStatuMove.gameObject:SetActiveEx(state == XDoomsdayConfigs.TEAM_STATE.MOVING)
                            grid.PanelStatuEvent.gameObject:SetActiveEx(state == XDoomsdayConfigs.TEAM_STATE.BUSY)
                            grid.PanelStatuStand.gameObject:SetActiveEx(state == XDoomsdayConfigs.TEAM_STATE.WAITING)
                        end,
                        "_PlaceId",
                        "_TargetPlaceId",
                        "_State"
                    )
                end

                self["BtnTeam0" .. teamId]:SetDisable(not unlock and not teamExist)
            end
        end,
        "_UnlockTeamCount",
        "_TeamCount"
    )

    self:UpdateFocusPlace()
end

function XUiDoomsdayExplore:RefreshPlaceGrid(unlockPlaceIds)
    for _, placeId in pairs(unlockPlaceIds) do
        local isCamp = XDoomsdayConfigs.CheckPlaceIsCamp(self.StageId, placeId)
        local grid = self.PlaceGrids[placeId]
        if not grid then
            local pos =  XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "Pos")
            local go = isCamp and self.GridDoomsdayStageCamp or self.GridDoomsdayStage
            local parent = self.MapPrefab["Stage" .. pos]

            grid =
            XUiGridDoomsdayPlace.New(XUiHelper.Instantiate(go, parent), self.StageId, self,
                    handler(self, self.OnClickPlace))
            self.PlaceGrids[placeId] = grid

            local prePlaceId = XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "PrePlaceId")
            if XTool.IsNumberValid(prePlaceId) then --拥有前置节点
                local prePos = XDoomsdayConfigs.PlaceConfig:GetProperty(prePlaceId, "Pos")
                local preParent = self.MapPrefab["Stage" .. prePos]
                local posStart, posEnd = preParent.anchoredPosition, parent.anchoredPosition
                posStart = CSVector2(posStart.x, posStart.y)
                posEnd   = CSVector2(posEnd.x, posEnd.y)
                local _, width, angle =
                XUiHelper.CalculateLineWithTwoPosition(
                        posStart,
                        posEnd,
                        posStart.y > posEnd.y and CSVector3(0, 0, -1) or CSVector3(0, 0, 1)
                )
                local line = CS.UnityEngine.GameObject.Instantiate(self.PathLine, preParent, false)
                line.localScale = CSVector3.one
                line.localRotation = angle
                line.localPosition = CSVector3.zero
                line.gameObject:SetActiveEx(true)
                line.gameObject.name = PATH_NAME
                local deltaY = self.PathLine.sizeDelta.y
                line.sizeDelta = CSVector2.zero
                if self.IsAnimation then
                    table.insert(self.Waiting2AddPlace, {grid, placeId, width, line, deltaY})
                else
                    line.sizeDelta = CSVector2(width, deltaY)
                    grid.GameObject:SetActiveEx(true)
                end

                local uiLine = parent.transform:Find(PATH_NAME)
                if uiLine then
                    uiLine.gameObject:SetActiveEx(false)
                    uiLine.gameObject.name = "UiLine"
                end
            end 
            if isCamp then --营地，没有前置
                local line = parent.transform:Find(PATH_NAME)
                if line then
                    line.gameObject:SetActiveEx(false)
                    line.gameObject.name = "UiLine"
                end
                grid.GameObject:SetActiveEx(true)
            end
        end
        grid:Refresh(placeId, isCamp)
    end
    --首次进入界面不播放动画
    self.IsAnimation = true
    self:AddPlaceWithAnim()
end

function XUiDoomsdayExplore:AddPlaceWithAnim()
    if XTool.IsTableEmpty(self.Waiting2AddPlace) then
        return
    end
    local index = 1
    RunAsyn(function()
        while true do
            --避免函数被多次执行
            if (XLuaUiManager.IsUiShow("UidoomsdayEvent")) or self.IsDrawPath then
                asynWaitSecond(0.02) --避免界面打开后不关，while true 浪费性能，事件界面可能打开多次
                goto continue
            end
            XLuaUiManager.SetMask(true)
            local item = self.Waiting2AddPlace[index]
            if not item then
                self.Waiting2AddPlace = {}
                XLuaUiManager.SetMask(false)
                break
            end
           
            self.IsDrawPath = true
            local grid, placeId, width, line, deltaY = table.unpack(item)
            local asyncAnim = asynTask(grid.PlayEnable, grid)
            
            XUiHelper.Tween(PATH_GENERATOR_TIME, function(dt)
                local tmpWidth = width * dt
                line.sizeDelta = CSVector2(tmpWidth, deltaY)
            end, function()
                self:FocusStage(grid, nil, nil, ANIM_TIME)
            end)

            XUiManager.TipMsg(XUiHelper.GetText("DoomsdayPlaceUnLockTips", XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "Name")))
            
            asynWaitSecond(2) -- 等待提示关闭
            
            grid.GameObject:SetActiveEx(true)
            if grid.GameObject.activeInHierarchy 
                    and self.GameObject.activeInHierarchy then
                asyncAnim()
            end
            index = index + 1
            self.IsDrawPath = false
            XLuaUiManager.SetMask(false)
            ::continue::
        end
        
    end)
end

--探索路径画线
function XUiDoomsdayExplore:DrawMoveLine(placeId, targetPlaceId, teamId)
    if not XTool.IsNumberValid(placeId) or not XTool.IsNumberValid(targetPlaceId) then
        return
    end

    local gridA = self.PlaceGrids[placeId]
    if not gridA then
        XLog.Error(string.format("DrawMoveLine error:当前地点未解锁或不在配置中 placeId:%s", placeId))
        return
    end
    local gridB = self.PlaceGrids[targetPlaceId]
    if not gridB then
        XLog.Error(string.format("DrawMoveLine error:目标地点未解锁或不在配置中 targetPlaceId:%s", targetPlaceId))
        return
    end

    -----@type UnityEngine.Vector2
    --local positionA, positionB =
    --    self.PlaceGrids[placeId].Transform.parent.anchoredPosition,
    --    self.PlaceGrids[targetPlaceId].Transform.parent.anchoredPosition
    --positionA = Vector2(positionA.x, positionA.y)
    --positionB = Vector2(positionB.x, positionB.y)
    --local position, width, angle =
    --    XUiHelper.CalculateLineWithTwoPosition(
    --    positionB,
    --    positionA,
    --    positionA.y > positionB.y and CSVector3(0, 0, 1) or CSVector3(0, 0, -1)
    --)
    local transform = self.Line[teamId]
    if not transform then
        ---@type UnityEngine.RectTransform
        --transform = CS.UnityEngine.GameObject.Instantiate(self:FindTransform("Line25_28").gameObject).transform
        local lineParent = CS.UnityEngine.GameObject.Instantiate(self.LinePrefab.gameObject, self.PanelStages.transform, false).transform
        lineParent.gameObject:SetActiveEx(true)
        local linEffect = lineParent.gameObject:LoadUiEffect(XDoomsdayConfigs.GetExplorePathFx())
        transform = {}
        XTool.InitUiObjectByUi(transform, linEffect)
        self.Line[teamId] = transform
    end
    --transform.parent = self.PanelStages.transform
    --transform.localPosition = CSVector3(position.x, position.y, 0)
    --transform.localScale = CSVector3.one
    --transform.localRotation = angle
    --transform.sizeDelta = CSVector2(width, transform.sizeDelta.y)
    --transform.gameObject:SetActiveEx(true)
    transform.Start.position = self.PlaceGrids[placeId].Transform.position
    transform.Target.position = self.PlaceGrids[targetPlaceId].Transform.position
end

function XUiDoomsdayExplore:OnClickPlace(placeId)
    --if XDoomsdayConfigs.CheckPlaceIsCamp(self.StageId, placeId) then
    --    self:Close()
    --    return
    --end

    for inId, grid in pairs(self.PlaceGrids) do
        local isShow = placeId == inId
        grid:SetSelect(isShow)
        grid.Transform.parent.gameObject:SetActiveEx(isShow)
        if isShow then
            self:FocusStage(grid, 0.382, 0.5, 0.5)
        end
    end
    self:SetSelectLineState(placeId, false)
    for _, obj in pairs(self.Line) do
        obj.GameObject:SetActiveEx(false)
    end
    self.PanelHide.gameObject:SetActiveEx(false)
    XLuaUiManager.Open("UiDoomsdayExploreTcanchuang", self.StageId, placeId, handler(self, self.OnStageDetailClose))
end

function XUiDoomsdayExplore:OnStageDetailClose(placeId)
    self.PanelHide.gameObject:SetActiveEx(true)
    for inId, grid in pairs(self.PlaceGrids) do
        grid:SetSelect(false)
        grid.Transform.parent.gameObject:SetActiveEx(true)
        if self.AnimOffset then
            self.PanelStages:DOLocalMove(self.PanelStages.localPosition - self.AnimOffset, 0.5)
            self.AnimOffset = nil
        end
    end
    self:SetSelectLineState(placeId, true)
    for _, obj in pairs(self.Line) do
        obj.GameObject:SetActiveEx(true)
    end
end

function XUiDoomsdayExplore:SetSelectLineState(placeId, state)
    local selectGrid = self.PlaceGrids[placeId]
    if selectGrid then
        local parent = selectGrid.Transform.parent
        local count = parent.transform.childCount
        for i = 0, count - 1 do
            local child = parent:GetChild(i)
            if child and child.name == PATH_NAME then
                child.gameObject:SetActiveEx(state)
            end
        end
    end
end

function XUiDoomsdayExplore:OnClickBtnTeam(teamIndex)
    local stageId = self.StageId
    local stageData = self.StageData

    if self.StageData:IsFinishEndAndTips() then
        return
    end

    local teamExist = stageData:CheckTeamExist(teamIndex)
    if not teamExist and not stageData:CanCreateTeam(teamIndex) then
        XUiManager.TipText("DoomsdayTeamLock")
        return
    end

    local event = stageData:GetTeamEvent(teamIndex)
    if event then
        XDataCenter.DoomsdayManager.EnterEventUi(stageId, event)
    else
        XLuaUiManager.Open("UiDoomsdayTeamTip", stageId, teamIndex)
    end
end

function XUiDoomsdayExplore:OnClickBtnPosition()
    local stageId = self.StageId
    local stageData = self.StageData
    if self.StageData:IsFinishEndAndTips() then
        return
    end

    local findPlaceId
    local teamList = stageData:GetAlreadySetUpTeamList()
    local teamMember = #teamList
    for _, team in ipairs(teamList) do
        local placeId = team:GetProperty("_PlaceId")
        if teamMember > 1 and placeId ~= self.FocusPlaceId then
            findPlaceId = placeId
        end
    end

    if not findPlaceId and teamMember > 0 then
        local team = teamList[1]
        local placeId = team:GetProperty("_PlaceId")
        findPlaceId = placeId
    end

    if findPlaceId then
        self.FocusPlaceId = findPlaceId
        self:UpdateFocusPlace()
    end

    local eventPlaceId = findPlaceId or self.FocusPlaceId
    local event = stageData:GetPlaceEvent(eventPlaceId)
    if event then
        XDataCenter.DoomsdayManager.EnterEventUi(stageId, event)
    end
end

function XUiDoomsdayExplore:UpdateFocusPlace()
    local grid = self.PlaceGrids[self.FocusPlaceId]
    if not grid then
        return
    end
    grid.GameObject.name = "Focus"
    self:FocusStage(grid, nil, nil, ANIM_TIME)
end

function XUiDoomsdayExplore:OnClickBtnTarget()
    if self.StageData:IsFinishEndAndTips() then
        return
    end
    XLuaUiManager.Open("UiDoomsdayFubenTask", self.StageId)
end

function XUiDoomsdayExplore:OnClickBtnInhabitant()
    XLuaUiManager.Open("UiDoomsdayPeople", self.StageId)
end

function XUiDoomsdayExplore:FocusStage(grid, widthOffset, heightOffset, duration, easeType)
    widthOffset = widthOffset or 0.5
    heightOffset = heightOffset or 0.5
    duration = duration or 0
    easeType = easeType or CS.DG.Tweening.Ease.Linear
    local stageObj = grid.Transform
    local midScreenPos =
        CS.UnityEngine.Vector2(CS.UnityEngine.Screen.width * widthOffset, CS.UnityEngine.Screen.height * heightOffset)
    local _, midPos =
        CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        self.PanelStages,
        midScreenPos,
        CS.UnityEngine.Camera.main
    )
    local offset = CSVector3(midPos.x, midPos.y, 0) - stageObj.parent.localPosition
    -- 避免缩放影响
    offset.x = offset.x * self.PanelStages.localScale.x
    offset.y = offset.y * self.PanelStages.localScale.y
    self.AnimOffset = offset
    self.PanelStages:DOLocalMove(self.PanelStages.localPosition + offset, duration)
end

return XUiDoomsdayExplore
