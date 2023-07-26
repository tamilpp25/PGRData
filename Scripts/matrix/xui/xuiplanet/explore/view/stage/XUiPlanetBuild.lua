local XUiPlanetBuildGrid = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetBuildGrid")
local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")

---@class XUiPlanetBuild:XLuaUi
local XUiPlanetBuild = XLuaUiManager.Register(XLuaUi, "UiPlanetBuild")

function XUiPlanetBuild:Ctor()
    ---@type XPlanetDataBuilding
    self._BuildingSelected = false
    ---@type XPlanetStage
    self._Stage = false
end

function XUiPlanetBuild:OnAwake()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEmploymentList)
    self.DynamicTable:SetProxy(XUiPlanetBuildGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCard.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickBring)
    self:RegisterClickEvent(self.BtnCancel, self.OnClickNotBring)
    self:RegisterClickEvent(self.BtnDeploy, self.OnClickDefaultBuilding)
    self:RegisterClickEvent(self.BtnDetermine, self.OnClickClose)
    self:RegisterClickEvent(self.BtnWndClose, self.OnClickClose)
    self:RegisterClickEvent(self.BtnClose, self.OnClickClose)
    self.TxtLevel.gameObject:SetActiveEx(false)
    ---@type XUiPlanetGridBuff
    self._GridBuff = XUiPlanetGridBuff.New(self.ImgBuff)
    self._GridBuffList = {
        self._GridBuff
    }
    ---@type XUiPlanetGridBuff
    self._GridDebuff = XUiPlanetGridBuff.New(self.ImgBuff2)
    self._GridDebuffList = {
        self._GridDebuff
    }
end

function XUiPlanetBuild:OnStart(stage, closeCb)
    self._Stage = stage
    self._CloseCb = closeCb
    local index = 1
    self:UpdateBuildList(index)
    self:SetSelected(self.DynamicTable:GetData(index))
end

function XUiPlanetBuild:UpdateBuildList(index)
    local building = self._Stage:GetBuildingCanBring()
    self.DynamicTable:SetDataSource(building)
    self.DynamicTable:ReloadDataASync(index)
end

function XUiPlanetBuild:SetSelected(building, isShowSelectEffect)
    self._BuildingSelected = building
    XDataCenter.PlanetManager.ClearOneStageBuildUnlockRed(self._BuildingSelected:GetId())
    self:Update()
    self:UpdateSelected(isShowSelectEffect)
    self:PlayAnimation("QieHuan")
end

function XUiPlanetBuild:Update()
    local building = self._BuildingSelected
    if not building then
        return
    end
    self.RImgHead:SetRawImage(building:GetIcon())
    self.TxtName.text = building:GetName()
    self.TxtCode.text = building:GetDesc()
    self:UpdateAmountBring()
    self:UpdateBtnBring()
    self:UpdateBuff()
end

function XUiPlanetBuild:UpdateAmountBring()
    local amount = self._Stage:GetBuildingBringAmount()
    local capacity = self._Stage:GetBuildingCapacity()
    self.TxtNumber.text = string.format("%d/%d", amount, capacity)
end

---@param grid XUiPlanetBuildGrid
function XUiPlanetBuild:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index), self._Stage)
        grid:UpdateSelected(self._BuildingSelected)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:RegisterClick(function(building)
            self:SetSelected(building, true)
        end)
        local buildId = self.DynamicTable:GetData(index):GetId()
        if XDataCenter.PlanetManager.CheckOneStageBuildUnlockTip(buildId) then
            grid:PlayUnlockAnim()
            XDataCenter.PlanetManager.ClearOneStageBuildUnlockTip(buildId)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local building = self.DynamicTable:GetData(index)
        self:SetSelected(building)
    end
end

function XUiPlanetBuild:UpdateSelected(isShowSelectEffect)
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateSelected(self._BuildingSelected, isShowSelectEffect)
    end
end

function XUiPlanetBuild:UpdateBring()
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateBring()
    end
end

function XUiPlanetBuild:OnClickBring()
    -- ban掉的不加入
    if self._Stage:IsBanned(self._BuildingSelected) then
        XUiManager.TipErrorWithKey("PlanetRunningBuildBanned")
        return
    end
    -- 超过上限不加入
    if self._Stage:GetBuildingBringAmount() >= self._Stage:GetBuildingCapacity() then
        XUiManager.TipErrorWithKey("PlanetRunningBuildBringInLimit")
        return
    end
    self._Stage:SetBuildingSelected(self._BuildingSelected, true)
    self:OnBuildingBringUpdate()
end

function XUiPlanetBuild:OnClickNotBring()
    if self._Stage:IsSureBring(self._BuildingSelected) then
        XUiManager.TipErrorWithKey("PlanetRunningBuildSureBring")
        return
    end
    self._Stage:SetBuildingSelected(self._BuildingSelected, false)
    self:OnBuildingBringUpdate()
end

function XUiPlanetBuild:UpdateBtnBring()
    if XDataCenter.PlanetManager.GetViewModel():IsBuildingSelected(self._BuildingSelected) then
        self.BtnConfirm.gameObject:SetActiveEx(false)
        self.BtnCancel.gameObject:SetActiveEx(true)
    else
        self.BtnConfirm.gameObject:SetActiveEx(true)
        self.BtnCancel.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetBuild:OnClickDefaultBuilding()
    local buildingDefault = self._Stage:GetBuildingRecommendDefault()
    local resultBuildingList = {}
    -- 过滤未解锁建筑
    for _, buildId in ipairs(buildingDefault) do
        if XDataCenter.PlanetManager.CheckBuildingIsUnLock(buildId) then
            table.insert(resultBuildingList, buildId)
        end
    end
    XDataCenter.PlanetManager.GetViewModel():SetSelectBuilding(resultBuildingList)
    XDataCenter.PlanetExploreManager.RequestSelectBuilding(resultBuildingList)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BUILDING_SELECT)
    self:OnBuildingBringUpdate()
end

function XUiPlanetBuild:OnBuildingBringUpdate()
    self:UpdateBtnBring()
    self:UpdateBring()
    self:UpdateAmountBring()
end

function XUiPlanetBuild:UpdateBuff()
    local buffList = self._BuildingSelected:GetBuff()
    self:RefreshBuff(buffList)
    
    local debuffList = self._BuildingSelected:GetDebuff()
    self:RefreshDeBuff(debuffList)
end

function XUiPlanetBuild:RefreshBuff(buffList)
    self.PanelNoResult2.gameObject:SetActiveEx(XTool.IsTableEmpty(buffList))
    for _, grid in pairs(self._GridBuffList) do
        grid.GameObject:SetActiveEx(false)
    end
    for index, buff in ipairs(buffList) do
        if not self._GridBuffList[index] then
            self._GridBuffList[index] = XUiPlanetGridBuff.New(XUiHelper.Instantiate(self.ImgBuff, self.ImgBuff.transform.parent))
        end
        self._GridBuffList[index]:Update(buff)
        self._GridBuffList[index].GameObject:SetActiveEx(true)
    end
end

function XUiPlanetBuild:RefreshDeBuff(debuffList)
    self.PanelNoResult2.gameObject:SetActiveEx(XTool.IsTableEmpty(debuffList))
    for _, grid in pairs(self._GridDebuffList) do
        grid.GameObject:SetActiveEx(false)
    end
    for index, buff in ipairs(debuffList) do
        if not self._GridDebuffList[index] then
            self._GridDebuffList[index] = XUiPlanetGridBuff.New(XUiHelper.Instantiate(self.ImgBuff2, self.ImgBuff2.transform.parent))
        end
        self._GridDebuffList[index]:Update(buff)
        self._GridDebuffList[index].GameObject:SetActiveEx(true)
    end
end

function XUiPlanetBuild:OnClickClose()
    self:Close()
    if self._CloseCb then
        self._CloseCb()
    end
end

return XUiPlanetBuild