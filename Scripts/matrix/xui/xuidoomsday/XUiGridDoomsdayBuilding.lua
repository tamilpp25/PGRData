local XUiGridDoomsdayBuilding = XClass(nil, "XUiGridDoomsdayBuilding")

function XUiGridDoomsdayBuilding:Ctor(stageId, clickCb)
    self.StageId = stageId
    self.ClickCb = clickCb
end

function XUiGridDoomsdayBuilding:Init()
    self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    self.BtnEvent.CallBack = handler(self, self.OnClickBtnEvent)

    self:SetSelect(false)
end

function XUiGridDoomsdayBuilding:Refresh(buildingIndex)
    self.BuildingIndex = buildingIndex

    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    local building = stageData:GetBuilding(buildingIndex)

    self.Parent:BindViewModelPropertyToObj(
        building,
        function(cfgId)
            if XTool.IsNumberValid(cfgId) then
                self.RImgBuiid:SetRawImage(XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "Icon"))
                self.TxtBuiidName.text = XDoomsdayConfigs.BuildingConfig:GetProperty(cfgId, "Name")
            else
                self.RImgBuiid:SetRawImage(XDoomsdayConfigs.EmptyBuildingIcon)
                self.TxtBuiidName.text = ""
            end
        end,
        "_CfgId"
    )

    self.Parent:BindViewModelPropertyToObj(
        building,
        function(state)
            if
            ((state == XDoomsdayConfigs.BUILDING_STATE.WORKING and XDoomsdayConfigs.IsBuildingInOperable(building:GetProperty("_CfgId"))) 
                    or state == XDoomsdayConfigs.BUILDING_STATE.EMPTY )
             then
                --不可操作类型建筑处于等待状态时隐藏建筑状态图标
                self.ImgState.gameObject:SetActiveEx(false)
            else
                self.ImgState:SetSprite(XDoomsdayConfigs.BuildingTypeIcon[state])
                self.ImgState.gameObject:SetActiveEx(true)

                if state == XDoomsdayConfigs.BUILDING_STATE.WORKING then
                    self.ImgStateLoop:Play()
                else
                    self.ImgStateLoop:Stop()
                    --暂停时，恢复动画产生的旋转
                    self.ImgState.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
                end
            end
        end,
        "_State"
    )
    self:UpdateEvent()
end

--随机事件
function XUiGridDoomsdayBuilding:UpdateEvent()
    if self:CheckEventActive() then
        self.Parent:BindViewModelPropertyToObj(
            self.Event,
            function(finished)
                --策划改动关卡格子上不显示事件  by lph
                --self.BtnEvent.gameObject:SetActiveEx(finished)
            end,
            "_Finished"
        )
    else
        self.BtnEvent.gameObject:SetActiveEx(false)
    end
end

function XUiGridDoomsdayBuilding:SetSelect(value)
    self.ImageSelected.gameObject:SetActiveEx(value)
end

--为当前建筑附加随机事件
function XUiGridDoomsdayBuilding:SetEvent(event)
    self.Event = event
    self:UpdateEvent()
end

function XUiGridDoomsdayBuilding:CheckEventActive()
    return self.Event and not self.Event:GetProperty("_Finished")
end

function XUiGridDoomsdayBuilding:OnClickBtnClick()
    self.ClickCb(self.BuildingIndex)
end

function XUiGridDoomsdayBuilding:OnClickBtnEvent()
    XDataCenter.DoomsdayManager.EnterEventUi(self.StageId, self.Event)
end

return XUiGridDoomsdayBuilding
