local MAX_TEAM_NUM = 2 --最大队伍数量

local XUiGridDoomsdayPlace = XClass(nil, "XUiGridDoomsdayPlace")

function XUiGridDoomsdayPlace:Ctor(go, stageId, parent, clickCb)
    self.GameObject = go.gameObject
    self.Transform = go.transform
    self.Parent = parent

    self.StageId = stageId
    self.ClickCb = clickCb

    self.TeamPanels = {}
    XTool.InitUiObject(self)

    self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    self:SetSelect(false)

    self.Img05 = self.Img05 or XUiHelper.TryGetComponent(self.Transform, "Img05")
    self.Img04 = self.Img04 or XUiHelper.TryGetComponent(self.Transform, "Img04")
    local panelTeamAll = XUiHelper.TryGetComponent(self.Transform, "PanelTeamAll")
    self.PanelTeam = panelTeamAll or self.PanelTeam
end

function XUiGridDoomsdayPlace:Refresh(placeId, isCamp)
    self.PlaceId = placeId

    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    local place = stageData:GetPlace(placeId)
    --每次刷新保持在最顶层
    self.Transform:SetSiblingIndex(self.Transform.parent.childCount)

    --已探索完成
    self.Parent:BindViewModelPropertyToObj(
        place,
        function(isFinish)
            if XDoomsdayConfigs.CheckPlaceIsCamp(self.StageId, placeId) then
                return
            end
            if not XTool.UObjIsNil(self.Img05) then
                --self.PanelTitle01.gameObject:SetActiveEx(isFinish)
                self.Img05.gameObject:SetActiveEx(isFinish)
            end

            if not XTool.UObjIsNil(self.Img04) then
                --self.PanelTitle03.gameObject:SetActiveEx(not isFinish)
                self.Img04.gameObject:SetActiveEx(not isFinish)
            end

            self:UpdateEvent()
        end,
        "_Finished"
    )

    --在地点中的队伍
    self.Parent:BindViewModelPropertyToObj(
        place,
        function(teamIds)
            self.PanelTeam.gameObject:SetActiveEx(false)
            for index = 1, MAX_TEAM_NUM do
                self["ImgTeam0" .. index].gameObject:SetActiveEx(false)
            end
            self.PanelTeam.gameObject:SetActiveEx(false)

            for _, index in pairs(teamIds) do
                self["ImgTeam0" .. index].gameObject:SetActiveEx(true)
                self.PanelTeam.gameObject:SetActiveEx(true)
            end
        end,
        "_TeamIds"
    )
end

function XUiGridDoomsdayPlace:UpdateEvent()
    if XDoomsdayConfigs.CheckPlaceIsCamp(self.StageId, self.PlaceId) then
        return
    end
    --新事件
    if self.Event then
        self.Parent:BindViewModelPropertyToObj(
            self.Event,
            function(isFinish)
                if not XTool.UObjIsNil(self.Img04) then
                    --self.PanelTitle03.gameObject:SetActiveEx(not isFinish)
                    self.Img04.gameObject:SetActiveEx(not isFinish)
                end

                if not XTool.UObjIsNil(self.Img05) then
                    --self.PanelTitle01.gameObject:SetActiveEx(isFinish)
                    self.Img05.gameObject:SetActiveEx(isFinish)
                end
            end,
            "_Finished"
        )
    else
        if not XTool.UObjIsNil(self.Img04) then
            --self.PanelTitle03.gameObject:SetActiveEx(false)
            self.Img04.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridDoomsdayPlace:SetSelect(value)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end
end

--为当前地点附加随机事件
function XUiGridDoomsdayPlace:SetEvent(event)
    self.Event = event
    self:UpdateEvent()
end

function XUiGridDoomsdayPlace:OnClickBtnClick()
    local event = self.Event
    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    if event then
        --判断当前位置是否能触发事件
        --if not event:GetProperty("_Finished") then
        if event:IsActive(stageData:GetProperty("_Day")) then
            XDataCenter.DoomsdayManager.EnterEventUi(self.StageId, event)
            return
        end
        
    end

    self.ClickCb(self.PlaceId)
end

--播放动画
function XUiGridDoomsdayPlace:PlayEnable(engCb, beginCb, warpMode)
    if not self.AnimEnable then
        return
    end
    warpMode = warpMode or CS.UnityEngine.Playables.DirectorWrapMode.None
    self.AnimEnable.transform:PlayTimelineAnimation(engCb, beginCb, warpMode)
end

return XUiGridDoomsdayPlace
