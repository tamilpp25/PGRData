local XUiPlanetDetailGrid = require("XUi/XUiPlanet/Build/XUiPlanetDetailGrid")
local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")

---@class XUiPlanetBuildDetailPanel
local XUiPlanetBuildDetailPanel = XClass(nil, "XUiPlanetBuildDetailPanel")

function XUiPlanetBuildDetailPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitObj()
    self:AddBtnClickListener()
end


--region ui
function XUiPlanetBuildDetailPanel:Refresh(buildId, isCard, isTalent)
    self.IsCard = isCard
    self.IsTalent = isTalent
    self.IsFloor = XPlanetWorldConfigs.CheckBuildingIsType(buildId, XPlanetWorldConfigs.BuildType.FloorBuild)
    self.BuildId = buildId
    self:OpenPanel()
    
    self:RefreshBuildDetail(buildId)
    self:RefreshFloorBuildModeDetail()
    self:RefreshFloorSelectDetail(buildId)
end

---地板建造模式选择
function XUiPlanetBuildDetailPanel:RefreshFloorBuildModeDetail()
    local isShowFloorBuild = self.IsFloor and self.IsCard
    self.PanelBuildTitle.gameObject:SetActiveEx(isShowFloorBuild)
    self.PanelBuild.gameObject:SetActiveEx(isShowFloorBuild)
    if not isShowFloorBuild or XTool.UObjIsNil(self.GridBuild) then
        return
    end
    local modeList = {
        XPlanetConfigs.FloorBuildingBuildMode.Point,
        XPlanetConfigs.FloorBuildingBuildMode.Cycle,
    }
    -- 地板建筑选择建造方式
    for _, mode in pairs(modeList) do
        local gridBuildMode = XUiPlanetDetailGrid.New(XUiHelper.Instantiate(self.GridBuild, self.PanelBuildContent))
        local isSelect = XDataCenter.PlanetManager.GetCurFloorSelectBuildMode(self.IsTalent) == mode
        self.GridBuildModeList[mode] = gridBuildMode
        gridBuildMode:Update(mode, false, isSelect, function()
            XDataCenter.PlanetManager.SetCurFloorSelectBuildMode(self.IsTalent, mode)
            self:RefreshBuildModeSelectState()
        end)
    end
    self.GridBuild.gameObject:SetActiveEx(false)
end

function XUiPlanetBuildDetailPanel:RefreshBuildModeSelectState()
    for mode, grid in pairs(self.GridBuildModeList) do
        grid:SetSelect(XDataCenter.PlanetManager.GetCurFloorSelectBuildMode(self.IsTalent) == mode)
    end
end

---天赋球建筑基底选择
function XUiPlanetBuildDetailPanel:RefreshFloorSelectDetail(buildId)
    if not self.IsTalent then
        return
    end
    local canUseFloorIdList = XDataCenter.PlanetManager.GetTalentBuildingCanUseFloorId(buildId)
    local isHaveFloorIdList = #canUseFloorIdList > 1
    local isHideFloorSelect = XLuaUiManager.IsUiShow("UiPlanetHomeland") or (not self.IsCard and self.RootUi:CheckIsDefaultBuilding())
    local isShowFloorSelect = not self.IsFloor and not isHideFloorSelect and isHaveFloorIdList

    self.PanelChoiceTitle.gameObject:SetActiveEx(isShowFloorSelect)
    self.PanelChoiceBase.gameObject:SetActiveEx(isShowFloorSelect)
    if not isShowFloorSelect then
        return
    end
    if self.IsCard then
        XDataCenter.PlanetManager.SetTalentCurBuildDefaultFloorId(buildId)
    end

    -- 建筑选择基底
    for _, floorId in ipairs(canUseFloorIdList) do
        local gridFloor = XUiPlanetDetailGrid.New(XUiHelper.Instantiate(self.GridChoice, self.PanelChoiceContent))
        local isSelect = self.RootUi:CheckIsSelectFloor(floorId)
        local onClick = function()
            if self.IsCard then
                XDataCenter.PlanetManager.SetCurBuildSelectFloorId(floorId, buildId)
            else
                self.RootUi:OnClickUpdateBuilding(floorId)
            end
            self:RefreshFloorSelectState()
        end
        self.GridFloorList[floorId] = gridFloor
        gridFloor:Update(floorId, true, isSelect, onClick)
    end
    self.GridChoice.gameObject:SetActiveEx(false)
end

function XUiPlanetBuildDetailPanel:RefreshFloorSelectState()
    for floorId, gridFloor in pairs(self.GridFloorList) do
        gridFloor:SetSelect(self.RootUi:CheckIsSelectFloor(floorId))
    end
end

---天赋球建筑点击刷新
function XUiPlanetBuildDetailPanel:RefreshBuildDetail(buildId)
    self:UpdateBuffList(buildId)

    for index, buff in ipairs(XDataCenter.PlanetExploreManager.GetBuffList(self.BuffList)) do
        if XTool.IsTableEmpty(self.GridBuffList[index]) then
            self.GridBuffList[index] = XUiPlanetGridBuff.New(XUiHelper.Instantiate(self.ImgBuffBg01, self.ImgBuffBg01.transform.parent))
        end
        self.GridBuffList[index].GameObject:SetActiveEx(true)
        self.GridBuffList[index]:Update(buff)
    end

    for index, buff in ipairs(XDataCenter.PlanetExploreManager.GetBuffList(self.DeBuffList)) do
        if XTool.IsTableEmpty(self.GridDeBuffList[index]) then
            self.GridDeBuffList[index] = XUiPlanetGridBuff.New(XUiHelper.Instantiate(self.ImgDebuffBg, self.ImgDebuffBg.transform.parent))
        end
        self.GridDeBuffList[index].GameObject:SetActiveEx(true)
        self.GridDeBuffList[index]:Update(buff)
    end
    self.PanelBuffTitle.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.BuffList))
    self.ImgBuffBg01.transform.parent.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.BuffList))
    self.PanelDebuffTitle.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.DeBuffList))
    self.ImgDebuffBg.transform.parent.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.DeBuffList))
end

function XUiPlanetBuildDetailPanel:UpDateBuffActive(slaveGuid)
    for index, eventId in pairs(self.BuffList) do
        if eventId == XPlanetWorldConfigs.GetBuildingComboEvent(self.BuildId) then
            self.GridBuffList[index]:SetBuffActive(slaveGuid and slaveGuid > -1)
        end
    end

    for index, eventId in ipairs(self.DeBuffList) do
        if eventId == XPlanetWorldConfigs.GetBuildingComboEvent(self.BuildId) then
            self.GridDeBuffList[index]:SetBuffActive(slaveGuid and slaveGuid > -1)
        end
    end
end

function XUiPlanetBuildDetailPanel:OpenPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPlanetBuildDetailPanel:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPlanetBuildDetailPanel:InitObj()
    ---@type XUiPlanetGridBuff[]
    self.GridBuffList = {
        [1] = XUiPlanetGridBuff.New(self.ImgBuffBg01),
    }
    ---@type XUiPlanetGridBuff[]
    self.GridDeBuffList = {
        [1] = XUiPlanetGridBuff.New(self.ImgDebuffBg),
    }
    self.GridFloorList = {}
    self.GridBuildModeList = {}

    for _, grid in ipairs(self.GridBuffList) do
        grid.GameObject:SetActiveEx(false)
    end

    for _, grid in ipairs(self.GridDeBuffList) do
        grid.GameObject:SetActiveEx(false)
    end
end

---收集BuffId并分类
function XUiPlanetBuildDetailPanel:UpdateBuffList(buildId)
    local eventIdList = self.IsTalent and XPlanetTalentConfigs.GetTalentBuildingEventList(buildId) or XPlanetWorldConfigs.GetBuildingEvents(buildId)
    self.BuffList = {}
    self.DeBuffList = {}

    for _, eventId in ipairs(eventIdList) do
        if XPlanetStageConfigs.GetEventIsShow(eventId) then
            if XPlanetStageConfigs.GetEventIsIncrease(eventId) then
                table.insert(self.BuffList, eventId)
            else
                table.insert(self.DeBuffList, eventId)
            end
        end
    end

    if not self.IsTalent then
        local comboEventId = XPlanetWorldConfigs.GetBuildingComboEvent(buildId)
        if not XTool.IsNumberValid(comboEventId) then
            return
        end
        if XPlanetStageConfigs.GetEventIsIncrease(comboEventId) then
            table.insert(self.BuffList, comboEventId)
        else
            table.insert(self.DeBuffList, comboEventId)
        end
    end
end
--endregion


--region 按钮绑定
function XUiPlanetBuildDetailPanel:AddBtnClickListener()
    
end

function XUiPlanetBuildDetailPanel:OnBtnClick()
    self.RootUi:OnBtnCloseClick()
end
--endregion

return XUiPlanetBuildDetailPanel