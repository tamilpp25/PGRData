local XUiGridDoomsdayPlace = require("XUi/XUiDoomsday/XUiGridDoomsdayPlace")
local XUiGridDoomsdayResource = require("XUi/XUiDoomsday/XUiGridDoomsdayResource")
local XUiGridDoomsdayInhabitantAttr = require("XUi/XUiDoomsday/XUiGridDoomsdayInhabitantAttr")
local XUiDoomsdayDragZoomProxy = require("XUi/XUiDoomsday/XUiDoomsdayDragZoomProxy")

local MAX_PLACE_COUNT = 42 --最大探索地点数量
local EXPLORE_TEAM_NUM = 2 --探索小队数量
local ANIM_TIME = 0.5 --镜头移动动画时间

local CSVector2 = CS.UnityEngine.Vector2
local CSVector3 = CS.UnityEngine.Vector3
local CSQuaternion = CS.UnityEngine.Quaternion

local XUiDoomsdayExplore = XLuaUiManager.Register(XLuaUi, "UiDoomsdayExplore")

function XUiDoomsdayExplore:OnAwake()
    self:AutoAddListener()

    self.GridDoomsdayStageCamp.gameObject:SetActiveEx(false)
    self.GridDoomsdayStage.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    ---@type UnityEngine.RectTransform
    self.PanelStages = self:FindTransform("PanelStages")
    self.DragPanel = self:FindComponent("PanelDrag", "XDragZoomComponent")
    self.DragProxy = XUiDoomsdayDragZoomProxy.New(self.DragPanel)
    self.Line = {}
end

function XUiDoomsdayExplore:OnStart(stageId, focusPlaceId)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    self.PlaceGrids = {}
    self.TeamGrids = {}
    self.FocusPlaceId = focusPlaceId or XDoomsdayConfigs.StageConfig:GetProperty(stageId, "FirstPlace")

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

    --剩余天数
    self:BindViewModelPropertyToObj(
        stageData,
        function(leftDay)
            self.TxtTitleDate.text = CsXTextManagerGetText("DoomsdayFubenMainLeftDaySimple", leftDay)
        end,
        "_LeftDay"
    )

    --资源栏
    self:RefreshTemplateGrids(
        self.PanelTool1,
        XDoomsdayConfigs.GetResourceIds(),
        self.PanelAsset,
        function()
            return XUiGridDoomsdayResource.New(stageId)
        end,
        "ResourceGrids"
    )

    --居民信息
    self:BindViewModelPropertiesToObj(
        stageData,
        function(idleCount, count)
            self.TxtInhabitantNum.text = string.format("%d/%d", idleCount, count)
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
                self.PanelTool6,
                unhealthyInhabitantInfoList,
                self.PanelList,
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
            for _, placeId in pairs(unlockPlaceIds) do
                local isCamp = XDoomsdayConfigs.CheckPlaceIsCamp(stageId, placeId)
                local grid = self.PlaceGrids[placeId]
                if not grid then
                    local pos = XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "Pos")
                    local go = isCamp and self.GridDoomsdayStageCamp or self.GridDoomsdayStage
                    grid =
                        XUiGridDoomsdayPlace.New(
                        XUiHelper.Instantiate(go, self["Stage" .. pos]),
                        stageId,
                        self,
                        handler(self, self.OnClickPlace)
                    )
                    self.PlaceGrids[placeId] = grid
                end

                grid:Refresh(placeId, isCamp)
                grid.GameObject:SetActiveEx(true)
            end
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

--探索路径画线
function XUiDoomsdayExplore:DrawMoveLine(placeId, targetPlaceId,teamId)
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

    ---@type UnityEngine.Vector2
    local positionA, positionB =
        self.PlaceGrids[placeId].Transform.parent.anchoredPosition,
        self.PlaceGrids[targetPlaceId].Transform.parent.anchoredPosition
    positionA = Vector2(positionA.x, positionA.y)
    positionB = Vector2(positionB.x, positionB.y)
    local position, width, angle =
        XUiHelper.CalculateLineWithTwoPosition(
        positionA,
        positionB,
        positionA.y > positionB.y and CSVector3(0, 0, -1) or CSVector3(0, 0, 1)
    )
    local transform = self.Line[teamId]
    if not transform then
        ---@type UnityEngine.RectTransform
        transform = CS.UnityEngine.GameObject.Instantiate(self:FindTransform("Line25_28").gameObject).transform
        self.Line[teamId] = transform
    end
    transform.parent = self.PanelStages.transform
    transform.localPosition = CSVector3(position.x, position.y, 0)
    transform.localScale = CSVector3.one
    transform.localRotation = angle
    transform.sizeDelta = CSVector2(width, transform.sizeDelta.y)
    transform.gameObject:SetActiveEx(true)
end

function XUiDoomsdayExplore:OnClickPlace(placeId)
    if XDoomsdayConfigs.CheckPlaceIsCamp(self.StageId, placeId) then
        self:Close()
        return
    end

    for inId, grid in pairs(self.PlaceGrids) do
        local isShow = placeId == inId
        grid:SetSelect(isShow)
        grid.Transform.parent.gameObject:SetActiveEx(isShow)
        if isShow then
            self:FocusStage(grid, 0.382, 0.5, 0.5)
        end
    end
    for _, obj in pairs(self.Line) do
        obj.gameObject:SetActiveEx(false)
    end
    self.PanelHide.gameObject:SetActiveEx(false)
    XLuaUiManager.Open("UiDoomsdayExploreTcanchuang", self.StageId, placeId, handler(self, self.OnStageDetailClose))
end

function XUiDoomsdayExplore:OnStageDetailClose()
    self.PanelHide.gameObject:SetActiveEx(true)
    for inId, grid in pairs(self.PlaceGrids) do
        grid:SetSelect(false)
        grid.Transform.parent.gameObject:SetActiveEx(true)
        if self.AnimOffset then
            self.PanelStages:DOLocalMove(self.PanelStages.localPosition - self.AnimOffset, 0.5)
            self.AnimOffset = nil
        end
    end
    for _, obj in pairs(self.Line) do
        obj.gameObject:SetActiveEx(true)
    end
end

function XUiDoomsdayExplore:OnClickBtnTeam(teamIndex)
    local stageId = self.StageId
    local stageData = self.StageData

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

    local findPlaceId
    for teamId = 1, EXPLORE_TEAM_NUM do
        local teamExist = stageData:CheckTeamExist(teamId)
        if teamExist then
            local team = stageData:GetTeam(teamId)
            local placeId = team:GetProperty("_PlaceId")
            if placeId ~= self.FocusPlaceId then
                findPlaceId = placeId
                break
            end
        end
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
    XLuaUiManager.Open("UiDoomsdayFubenTask", self.StageId)
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
    self.AnimOffset = offset
    self.PanelStages:DOLocalMove(self.PanelStages.localPosition + offset, duration)
end

return XUiDoomsdayExplore
