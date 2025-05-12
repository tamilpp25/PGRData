local XUiPanelTheatre3CharacterDetail = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3CharacterDetail")
local XUiPanelTheatre3GeniusDetail = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3GeniusDetail")
local XUiPanelTheatre3Character = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3Character")

---@class XUiTheatre3Master : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Master = XLuaUiManager.Register(XLuaUi, "UiTheatre3Master")

local MasterType = {
    Genius = 1, -- 天赋
    Character = 2, -- 成员
}

function XUiTheatre3Master:OnAwake()
    if not self.BtnGenius then
        self.BtnGenius = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/BtnGenius", "XUiButton")
    end
    self:RegisterUiEvents()
    self.PanelCharacter.gameObject:SetActiveEx(false)
    ---@type XUiPanelTheatre3Character[]
    self.CharacterGroupList = {}
end

function XUiTheatre3Master:OnStart(isNewGenius, tagSelect, isQuantum)
    self._IsNewGenius = isNewGenius
    self._IsQuantum = isQuantum
    self:AddEventListener()
    self:InitPanelAsset()
    self:InitCharacterDetailPanel()
    self:InitGeniusDetailPanel()
    self:InitGeniusPanel()
    self:InitLeftTabBtns(tagSelect)
end

function XUiTheatre3Master:OnEnable()
    self.PanelTab:SelectIndex(self.SelectIndex or 1)
    self:RefreshGeniusRedPoint()
end

function XUiTheatre3Master:OnDisable()
    self:CancelGeniusSelect()
    self:CancelCharacterSelect()
    self:_ClearRedPoint(self.SelectIndex)
end

function XUiTheatre3Master:OnDestroy()
    self:RemoveEventListener()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetPanel)
end

--region PanelAsset
function XUiTheatre3Master:InitPanelAsset()
    self.ItemId = XEnumConst.THEATRE3.Theatre3TalentPoint
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ self.ItemId }, self.PanelSpecialTool, self, nil, handler(self, self.OnBtnClick))
end
--endregion

--region Tab
function XUiTheatre3Master:InitLeftTabBtns(tagSelect)
    self.TabBtns = {
        self.Genius,
        self.Character,
    }
    self.Character:ShowReddot(false)
    self.PanelTab:Init(self.TabBtns, function(index) self:OnSelectBtnTag(index) end)
    self.SelectIndex = tagSelect and tagSelect or 2
    if self._IsNewGenius then
        for i, btn in ipairs(self.TabBtns) do
            btn.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre3Master:OnSelectBtnTag(index)
    if self.SelectIndex ~= index then
        self:_ClearRedPoint(self.SelectIndex)
    end
    self.SelectIndex = index
    self.PanelCharacterList.gameObject:SetActiveEx(index == MasterType.Character)
    if index == MasterType.Genius then
        if self._IsQuantum then
            XLuaUiManager.PopThenOpen("UiTheatre3QuantumMaster", self._IsQuantum, 1)
            return
        end
        self:CancelCharacterSelect()
        self:RefreshGridGeniusList()
    elseif index == MasterType.Character then
        if self._IsNewGenius then
            XLuaUiManager.PopThenOpen("UiTheatre3Master", false, 2, self._IsNewGenius)
            return
        end
        self:CancelGeniusSelect()
        self:RefreshCharacterGridList()
        self:ClickCharacterGridByIndex(1, 1)
        -- 切换时从第一个进行显示
        if self.CharacterScrollRect then
            self.CharacterScrollRect.verticalNormalizedPosition = 1
        end
    end
    self:PlayAnimation("QieHuan1")
end
--endregion

--region Genius
function XUiTheatre3Master:InitGeniusDetailPanel()
    ---@type XUiPanelTheatre3GeniusDetail
    self._PanelGeniusDetail = XUiPanelTheatre3GeniusDetail.New(self.PanelGeniusDetail, self, handler(self, self.RefreshGridGeniusList))
end

function XUiTheatre3Master:InitGeniusPanel()
    local XUiPanelTheatre3Genius = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3Genius")
    ---@type XUiPanelTheatre3Genius
    self._PanelGenius = XUiPanelTheatre3Genius.New(self.PanelGeniusList, self, false)
    
    ---@type XUiPanelTheatre3Genius
    self._PanelGeniusNew = XUiPanelTheatre3Genius.New(self.PanelGeniusListNew, self, true)
end

function XUiTheatre3Master:CancelGeniusSelect()
    self._PanelGenius:CancelGeniusSelect()
    self._PanelGenius:Close()
    self._PanelGeniusNew:CancelGeniusSelect()
    self._PanelGeniusNew:Close()
    -- 关闭详情面板
    self._PanelGeniusDetail:Close()
    self.BtnGenius.gameObject:SetActiveEx(false)
end

function XUiTheatre3Master:SelectGenius(geniusId)
    -- 刷新详情面板
    self._PanelGeniusDetail:Open()
    self._PanelGeniusDetail:Refresh(geniusId)
    self:PlayAnimation("QieHuan2")
end

function XUiTheatre3Master:RefreshGridGeniusList(isIgnoreEqual)
    local conditionId = self._Control:GetClientConfigNumber("ToALineCloseCondition")
    if XTool.IsNumberValid(conditionId) then
        local isTrue, _ = XConditionManager.CheckCondition(conditionId)
        self.BtnGenius.gameObject:SetActiveEx(isTrue)
    else
        self.BtnGenius.gameObject:SetActiveEx(false)
    end
    if self._IsNewGenius then
        self._PanelGenius:Close()
        self._PanelGeniusNew:Open()
        self._PanelGeniusNew:Refresh(isIgnoreEqual)
    else
        self._PanelGeniusNew:Close()
        self._PanelGenius:Open()
        self._PanelGenius:Refresh(isIgnoreEqual)
    end
    
    self:RefreshGeniusRedPoint()
end

function XUiTheatre3Master:RefreshGeniusRedPoint()
    local isRedPoint = self._Control:CheckAllStrengthenTreeRedPoint()
    self.Genius:ShowReddot(isRedPoint)
    self.BtnGenius:ShowReddot(isRedPoint)
end

--endregion

--region Character
function XUiTheatre3Master:InitCharacterDetailPanel()
    ---@type XUiPanelTheatre3CharacterDetail
    self._PanelCharacterDetail = XUiPanelTheatre3CharacterDetail.New(self.PanelCharacterDetail, self)
end

function XUiTheatre3Master:RefreshCharacterGridList()
    local groupIdList = self._Control:GetCharacterGroupIdList()
    for index, groupId in pairs(groupIdList) do
        local characterGroup = self.CharacterGroupList[index]
        if not characterGroup then
            local go = XUiHelper.Instantiate(self.PanelCharacter, self.CharacterContent)
            characterGroup = XUiPanelTheatre3Character.New(go, self, handler(self, self.ClickCharacterGrid))
            self.CharacterGroupList[index] = characterGroup
        end
        characterGroup:Open()
        characterGroup:Refresh(groupId)
    end
    for i = #groupIdList + 1, #self.CharacterGroupList do
        self.CharacterGroupList[i]:Close()
    end
end

function XUiTheatre3Master:ClickCharacterGridByIndex(groupId, index)
    local characterGroup = self.CharacterGroupList[groupId]
    if not characterGroup then
        return
    end
    local grid = characterGroup:GetCharacterGridByIndex(index)
    if not grid then
        return
    end
    self:ClickCharacterGrid(grid)
end

-- 选择一个Grid
---@param grid XUiGridTheatre3Character
function XUiTheatre3Master:ClickCharacterGrid(grid)
    local curGrid = self.CurCharacterGrid
    if curGrid and curGrid.CharacterId == grid.CharacterId then
        return
    end
    -- 取消上一次的选择
    if curGrid then
        curGrid:SetCharacterSelect(false)
    end
    -- 选中当前的选择
    grid:SetCharacterSelect(true)
    -- 刷新详情面板
    self._PanelCharacterDetail:Open()
    self._PanelCharacterDetail:Refresh(grid.CharacterId)
    
    self.CurCharacterGrid = grid
    self:PlayAnimation("QieHuan2")
end

function XUiTheatre3Master:CancelCharacterSelect()
    if not self.CurCharacterGrid then
        return
    end
    -- 取消当前选择
    self.CurCharacterGrid:SetCharacterSelect(false)
    self.CurCharacterGrid = nil
    -- 关闭详情面板
    self._PanelCharacterDetail:Close()
end
--endregion

--region Ui - RedPoint
function XUiTheatre3Master:_ClearRedPoint(selectIndex)
    if selectIndex == 1 then
        self._Control:ClearGeniusRedPoint()
        self:RefreshGeniusRedPoint()
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3Master:RegisterUiEvents()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    self._Control:RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    self._Control:RegisterClickEvent(self, self.BtnGenius, self.OnChangeGeniusPanel)
end

function XUiTheatre3Master:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Master:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre3Master:OnBtnClick(index)
    XLuaUiManager.Open("UiTheatre3Tips", self.ItemId)
end

function XUiTheatre3Master:OnChangeGeniusPanel()
    --self._IsNewGenius = not self._IsNewGenius
    --self:RefreshGridGeniusList(true)
    if self._IsNewGenius then
        XLuaUiManager.PopThenOpen("UiTheatre3Master", false, 1)
    else
        XLuaUiManager.PopThenOpen("UiTheatre3QuantumMaster", true, 1)
    end
end
--endregion

--region Event
function XUiTheatre3Master:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_GENIUS_CHANGE_GRID, self.SelectGenius, self)
end

function XUiTheatre3Master:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_GENIUS_CHANGE_GRID, self.SelectGenius, self)
end
--endregion

return XUiTheatre3Master