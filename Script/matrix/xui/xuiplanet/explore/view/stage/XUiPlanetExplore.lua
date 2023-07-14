local XViewModelPlanetExplore = require("XEntity/XPlanet/View/XViewModelPlanetExplore")
local XUiPlanetExploreGridBoss = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetExploreGridBoss")
local XUiPlanetExploreGridCharacter = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetExploreGridCharacter")
--local XUiPlanetExploreGridBuilding = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetExploreGridBuilding")
local XUiPlanetBuildGrid = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetBuildGrid")

---@class XUiPlanetExplore:XLuaUi
local XUiPlanetExplore = XLuaUiManager.Register(XLuaUi, "UiPlanetExplore")

function XUiPlanetExplore:Ctor()
    ---@type XViewModelPlanetExplore
    self._ViewModel = XViewModelPlanetExplore.New()
    ---@type XUiPlanetExploreGridBoss[]
    self._GridListBoss = {}
    ---@type XUiPlanetExploreGridCharacter[]
    self._GridListCharacter = {}
end

function XUiPlanetExplore:OnAwake()
    self:BindExitBtns(self.BtnClose)
    self:BindExitBtns(self.BtnTanchuangClose)
    self.IconBoss.gameObject:SetActiveEx(false)
    self.GridRole.gameObject:SetActiveEx(false)
    --self.PanelBoss
    --self.GridCard
    --self.PanelEmploymentList
    self:RegisterClickEvent(self.BtnTeam, function()
        self:OnCharacterClick()
    end)
    self:RegisterClickEvent(self.BtnExplore, self.OnClickEnterStage)
    self:RegisterClickEvent(self.BtnBuilding, self.OnClickBuilding)
    --self.BtnStory
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEmploymentList)
    self.DynamicTable:SetProxy(XUiPlanetBuildGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCard.gameObject:SetActiveEx(false)
end

function XUiPlanetExplore:OnStart(stageId)
    local stage = XDataCenter.PlanetExploreManager.GetStage(stageId)
    self._ViewModel:SetStage(stage)
    self:InitListChangeEffectRecord()
end

function XUiPlanetExplore:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_TEAM, self.UpdateCharacter, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_BUILDING_SELECT, self.UpdateBuilding, self)
    self:UpdateStage()
    self:UpdateBoss()
    self:UpdateCharacter()
    self:UpdateBuilding()
    self:RefreshRedPoint()

    self:CheckTip()
end

function XUiPlanetExplore:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_TEAM, self.UpdateCharacter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_BUILDING_SELECT, self.UpdateBuilding, self)
    XDataCenter.PlanetManager.SetBtnStoryCache(self.BtnStory.isOn)
end

function XUiPlanetExplore:OnDestroy()
    ---清空新建筑提示
    XDataCenter.PlanetManager.ClearStageBuildUnlockTip()
end

function XUiPlanetExplore:UpdateStage()
    local name = self._ViewModel:GetPlanetName()
    self.TxtName.text = name

    local icon = self._ViewModel:GetPlanetIcon()
    self.RImgStar:SetRawImage(icon)

    local desc = self._ViewModel:GetPlanetDesc()
    self.Text.text = desc

    local stageId = self._ViewModel:GetStageId()
    local isStoryCache = XDataCenter.PlanetManager.GetBtnStoryCache()
    if isStoryCache then
        self.BtnStory.isOn = isStoryCache
    end
    self.BtnStory.gameObject:SetActiveEx(XDataCenter.PlanetManager.GetViewModel():CheckStageIsPass(stageId))
end

function XUiPlanetExplore:UpdateBoss()
    local bossList = self._ViewModel:GetBoss()
    for i = 1, #bossList do
        if not self._GridListBoss[i] then
            local uiBoss = CS.UnityEngine.Object.Instantiate(self.IconBoss, self.IconBoss.parent.transform)
            ---@type XUiPlanetExploreGridBoss
            local grid = XUiPlanetExploreGridBoss.New(uiBoss)
            self._GridListBoss[i] = grid
        end
        local boss = bossList[i]
        local grid = self._GridListBoss[i]
        grid:Update(boss)
        grid.GameObject:SetActiveEx(true)
    end
    for i = #bossList + 1, #self._GridListBoss do
        local grid = self._GridListBoss[i]
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiPlanetExplore:UpdateCharacter()
    local team = self._ViewModel:GetTeam()
    local characterList = team:GetMembers()
    local capacity = team:GetCapacity()
    for i = 1, capacity do
        if not self._GridListCharacter[i] then
            local uiCharacter = CS.UnityEngine.Object.Instantiate(self.GridRole, self.GridRole.parent.transform)
            ---@type XUiPlanetExploreGridCharacter
            local grid = XUiPlanetExploreGridCharacter.New(uiCharacter)
            self._GridListCharacter[i] = grid
        end
        local character = characterList[i]
        local grid = self._GridListCharacter[i]
        if character then
            grid:Update(character)
        else
            grid:SetEmpty()
        end
        grid.GameObject:SetActiveEx(true)
        grid:RegisterClick(function(...)
            self:OnCharacterClick(...)
        end)
    end
end

---@param character XPlanetCharacter
function XUiPlanetExplore:OnCharacterClick(character)
    XLuaUiManager.Open("UiPlanetRole", character, false, handler(self, self.RefreshListChangeEffectRecord))
end

function XUiPlanetExplore:OnClickEnterStage()
    local membersAmount = self._ViewModel:GetTeam():GetAmount()
    if membersAmount == 0 then
        XUiManager.TipText("CharacterCheckTeamNil")
        return
    end

    if XDataCenter.PlanetManager.IsInGame() then
        XDataCenter.PlanetManager.ContinueStage("UiPlanetBattleMain")
    else
        XDataCenter.PlanetExploreManager.EnterStage(self._ViewModel:GetStage())
    end
end

function XUiPlanetExplore:UpdateBuilding()
    local buildingSelected = self._ViewModel:GetBuildingSelected4View()
    self.DynamicTable:SetDataSource(buildingSelected)
    self.DynamicTable:ReloadDataASync(1)
    self:UpdateBuildingAmountBring()
end

function XUiPlanetExplore:UpdateBuildingAmountBring()
    local amount = #self.DynamicTable.DataSource
    local capacity = self._ViewModel:GetBuildingCapacity()
    self.TxtBuildingAmount.text = string.format("%d/%d", amount, capacity)
end


--region 角色&建筑选择改变特效
function XUiPlanetExplore:RefreshListChangeEffectRecord()
    self:RefreshRedPoint()
    self._ChangeSelectCharacterIdList = {}
    self._ChangeSelectBuildIdList = {}

    local buildingSelected = self._ViewModel:GetBuildingSelected4View()
    local team = self._ViewModel:GetTeam()
    local characterList = team:GetMembers()

    for _, building in ipairs(buildingSelected) do
        if not self._SelectBuildIdList[building:GetId()] then
            self._ChangeSelectBuildIdList[building:GetId()] = true
        end
    end
    for _, character in ipairs(characterList) do
        if not self._SelectCharacterIdList[character:GetCharacterId()] then
            self._ChangeSelectCharacterIdList[character:GetCharacterId()] = true
        end
    end

    for index, grid in ipairs(self._GridListCharacter) do
        local isShow = characterList[index] and self._ChangeSelectCharacterIdList[characterList[index]:GetCharacterId()]
        grid:ShowShinyEffect(isShow)
    end
    for index, grid in ipairs(self.DynamicTable:GetGrids()) do
        grid:ShowShinyEffect(self._ChangeSelectBuildIdList[buildingSelected[index]:GetId()])
    end
    self:InitListChangeEffectRecord()
end

function XUiPlanetExplore:InitListChangeEffectRecord()
    self._SelectCharacterIdList = {}
    self._SelectBuildIdList = {}

    local team = self._ViewModel:GetTeam()
    local characterList = team:GetMembers()
    for _, buildingSelected in ipairs(self._ViewModel:GetBuildingSelected4View()) do
        self._SelectBuildIdList[buildingSelected:GetId()] = true
    end
    for _, character in ipairs(characterList) do
        self._SelectCharacterIdList[character:GetCharacterId()] = true
    end
end
--endregion

--region Tip&RedPoint
function XUiPlanetExplore:RefreshRedPoint()
    -- 角色
    self.BtnTeam:ShowReddot(XDataCenter.PlanetManager.CheckAllCharacterUnlockRed())
    -- 建筑
    self.BtnBuilding:ShowReddot(XDataCenter.PlanetManager.CheckAllStageBuildUnlockRed())
end

function XUiPlanetExplore:CheckTip()
    self:_CheckCharacterUnlock(function()
        self:_CheckBuildUnlock()
    end)
end

function XUiPlanetExplore:_CheckCharacterUnlock(cb)
    local isTip, _ = XDataCenter.PlanetManager.CheckCharacterUnlockTip()
    if isTip then
        XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
            XDataCenter.PlanetManager.ClearCharacterUnlockTip()
            if cb then
                cb()
            end
        end, XPlanetConfigs.TipType.NewCharacter)
    else
        if cb then
            cb()
        end
    end
end

function XUiPlanetExplore:_CheckBuildUnlock(cb)
    local isTip, _ = XDataCenter.PlanetManager.CheckStageBuildUnlockTip()
    if isTip then
        XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(cb, XPlanetConfigs.TipType.NewBuild)
    else
        if cb then
            cb()
        end
    end
end
--endregion

---@param grid XUiPlanetBuildGrid
function XUiPlanetExplore:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index), self._ViewModel:GetStage())
        grid:HideBring()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        XUiHelper.RegisterClickEvent(self, grid.BtnClick, self.OnClickBuilding)
    end
end

function XUiPlanetExplore:OnClickBuilding()
    XLuaUiManager.Open("UiPlanetBuild", self._ViewModel:GetStage(), handler(self, self.RefreshListChangeEffectRecord))
end

return XUiPlanetExplore