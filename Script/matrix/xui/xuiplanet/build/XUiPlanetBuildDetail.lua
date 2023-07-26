local XUiPlanetBuildDetail = XLuaUiManager.Register(XLuaUi, "UiPlanetBuildDetail")
local XUiPlanetBuildDetailPanel = require("XUi/XUiPlanet/Build/XUiPlanetBuildDetailPanel")

function XUiPlanetBuildDetail:OnAwake()
    self:InitUi()
    self:AddBtnClickListener()
end

function XUiPlanetBuildDetail:OnStart(buildId, isTalent, isCard, buildGuid, slaveGuid, isDefault, closeCb)
    self.BuildId = buildId
    self.IsTalent = isTalent
    self.IsCard = isCard
    self.IsDefault = isDefault
    self.BuildGuid = buildGuid
    self.SlaveGuid = slaveGuid
    self.CloseCb = closeCb
end

function XUiPlanetBuildDetail:OnEnable()
    self:Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_DETAIL, self.UpdateShow, self)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

function XUiPlanetBuildDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_DETAIL, self.UpdateShow, self)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end


--region Ui
function XUiPlanetBuildDetail:Refresh()
    if not XTool.IsNumberValid(self.BuildId) then
        return
    end

    self:RefreshTitle()
    self:RefreshContent()
    self:RefreshCanBuildTip()
    self:UpdateShow()
end

function XUiPlanetBuildDetail:RefreshTitle()
    --标题信息
    local name = self.IsTalent and XPlanetTalentConfigs.GetTalentBuildingName(self.BuildId) or XPlanetWorldConfigs.GetBuildingName(self.BuildId)
    local desc = self.IsTalent and XPlanetTalentConfigs.GetTalentBuildingDesc(self.BuildId) or XPlanetWorldConfigs.GetBuildingBgDesc(self.BuildId)
    local iconUrl = XPlanetWorldConfigs.GetBuildingIconUrl(self.BuildId)

    self.TxtBuildLevel.gameObject:SetActiveEx(false)
    self.TxtBuildName.text = name
    self.TxtBuildDesc.text = desc
    if not string.IsNilOrEmpty(iconUrl) then
        self.RImgBuildIcon:SetRawImage(iconUrl)
    end
end

function XUiPlanetBuildDetail:RefreshContent()
    local event = self.IsTalent and XPlanetTalentConfigs.GetTalentBuildingEventList(self.BuildId) or XPlanetWorldConfigs.GetBuildingEvents(self.BuildId)
    local noEvent = XTool.IsTableEmpty(event)
    -- 关卡建筑连携事件
    if not self.IsTalent and noEvent then
        noEvent = not XTool.IsNumberValid(XPlanetWorldConfigs.GetBuildingComboEvent(self.BuildId))
    end
    self.PanelNoResult.gameObject:SetActiveEx(noEvent)
    self.PanelLand:Refresh(self.BuildId, self.IsCard, self.IsTalent)
end

function XUiPlanetBuildDetail:RefreshRecovery()
    local isCanRecycle = self.IsTalent and XPlanetTalentConfigs.GetTalentBuildingIsCard(self.BuildId) or 
            not self.IsTalent and XPlanetWorldConfigs.GetBuildingCanRecovery(self.BuildId)
    local isTalentDefault = self.IsTalent and self.IsDefault
    local isBandRecovery = XLuaUiManager.IsUiShow("UiPlanetHomeland")
    self.BtnRecycle.gameObject:SetActiveEx(isCanRecycle and not self.IsCard and not isTalentDefault and not isBandRecovery)
    if XTool.UObjIsNil(self.RImgRecycleIcon) then
        return
    end
    if self.IsTalent then
        self.RImgRecycleIcon.gameObject:SetActiveEx(false)
        self.TxtNum.gameObject:SetActiveEx(false)
    else
        local recycleCount = math.floor(XPlanetWorldConfigs.GetBuildingCast(self.BuildId) * XPlanetWorldConfigs.GetBuildingRecovery(self.BuildId))
        local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.PlanetRunningStageCoin)
        XUiHelper.GetUiSetIcon(self.RImgRecycleIcon, icon)
        self.TxtNum.text = recycleCount or 0
    end
end

function XUiPlanetBuildDetail:RefreshCanBuildTip()
    self.TxtTipsCenter.gameObject:SetActiveEx(false)
end

function XUiPlanetBuildDetail:UpdateShow()
    local data = XDataCenter.PlanetManager.GetBuildDataDetail(self.BuildGuid)
    if not XTool.IsTableEmpty(data) and not self.IsTalent then
        self.SlaveGuid = data.SlaveGuid
        if XTool.IsNumberValid(data.Level) then
            self.TxtBuildLevel.text = XUiHelper.GetText("PlanetLevelText", data.Level)
        end
        self.TxtBuildLevel.gameObject:SetActiveEx(XTool.IsNumberValid(data.Level))
    end
    self:RefreshRecovery()
    self.PanelLand:UpDateBuffActive(self.SlaveGuid)
end

function XUiPlanetBuildDetail:InitUi()
    self.PanelTitleList.gameObject:SetActiveEx(true)
    self.PanelItemList.gameObject:SetActiveEx(false)

    self.PanelLand = XUiPlanetBuildDetailPanel.New(self, self.PanelLand)
end

function XUiPlanetBuildDetail:CheckIsDefaultBuilding()
    return self.IsDefault
end

function XUiPlanetBuildDetail:CheckIsSelectFloor(floorId)
    if self.IsCard then
        return XDataCenter.PlanetManager.GetCurBuildSelectFloorId() == floorId
    end
    
    if not self.BuildGuid or not self.IsTalent then return false end
    local scene = XDataCenter.PlanetManager.GetPlanetMainScene()
    local building = scene._Planet:GetBuildingByBuildGuid(self.BuildGuid)
    return not XTool.IsTableEmpty(building) and building:GetFloorId() == floorId
end
--endregion


--region 按钮绑定
function XUiPlanetBuildDetail:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRecycle, self.OnClickRecoveryBuilding)
end

function XUiPlanetBuildDetail:OnBtnCloseClick()
    self:Close()
    if self.CloseCb then self.CloseCb() end
end

function XUiPlanetBuildDetail:OnClickUpdateBuilding(floorId)
    if not self.BuildGuid or not self.IsTalent then return end
    XDataCenter.PlanetManager.GetPlanetMainScene():UpdateBuilding(self.BuildGuid, floorId)
end

function XUiPlanetBuildDetail:OnClickRecoveryBuilding()
    if not self.BuildGuid then return end
    if self.IsTalent then
        XDataCenter.PlanetManager.GetPlanetMainScene():DeleteBuildingByGuid(self.BuildGuid)
    else
        XDataCenter.PlanetManager.GetPlanetStageScene():DeleteBuildingByGuid(self.BuildGuid)
    end
    self:OnBtnCloseClick()
end
--endregion