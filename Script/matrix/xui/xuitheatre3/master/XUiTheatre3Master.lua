local XUiPanelTheatre3CharacterDetail = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3CharacterDetail")
local XUiPanelTheatre3GeniusDetail = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3GeniusDetail")
local XUiPanelTheatre3Character = require("XUi/XUiTheatre3/Master/XUiPanelTheatre3Character")
local XUiGridTheatreGenius = require("XUi/XUiTheatre3/Master/XUiGridTheatreGenius")

---@class XUiTheatre3Master : XLuaUi
---@field _Control XTheatre3Control
---@field BoundSizeFitter XBoundSizeFitter
---@field PanelGeniusDrag XDragArea
local XUiTheatre3Master = XLuaUiManager.Register(XLuaUi, "UiTheatre3Master")

local MasterType = {
    Genius = 1, -- 天赋
    Character = 2, -- 成员
}
local DefaultId = 1
local FocusTime = 0.5

function XUiTheatre3Master:OnAwake()
    self:RegisterUiEvents()
    self.PanelCharacter.gameObject:SetActiveEx(false)
    self.GridGenuisSmall.gameObject:SetActiveEx(false)
    self.GridGenuisMiddle.gameObject:SetActiveEx(false)
    self.GridGenuisBig.gameObject:SetActiveEx(false)
    self.GridGenuisDir = {
        [XEnumConst.THEATRE3.StrengthenPointType.Small] = self.GridGenuisSmall,
        [XEnumConst.THEATRE3.StrengthenPointType.Middle] = self.GridGenuisMiddle,
        [XEnumConst.THEATRE3.StrengthenPointType.Big] = self.GridGenuisBig,
    }
    ---@type XUiGridTheatreGenius[]
    self.GridGeniusList = {}
    ---@type UnityEngine.Transform
    self.LineGeniusDir = {}
    ---@type XUiPanelTheatre3Character[]
    self.CharacterGroupList = {}
    local genuisMaxCount = self._Control:GetClientConfig("StrengthenTreeMaxCount")
    self.GenuisMaxCount = genuisMaxCount and tonumber(genuisMaxCount)
    self.IsFristEnter = true
end

function XUiTheatre3Master:OnStart()
    self:InitPanelAsset()
    self:InitCharacterDetailPanel()
    self:InitGeniusDetailPanel()
    self:InitLeftTabBtns()
end

function XUiTheatre3Master:OnEnable()
    -- 获取保存的天赋Index
    self.CurGeniusIndex = self._Control:GetStrengthenTreeSelectIndex()
    self.PanelTab:SelectIndex(self.SelectIndex or 1)
    self:RefreshGeniusRedPoint()
end

function XUiTheatre3Master:OnDisable()
    self:CancelGeniusSelect()
    -- 保存天赋上次关闭位置Index 
    self._Control:SaveStrengthenTreeSelectIndex(self.CurGeniusIndex)
    self:CancelCharacterSelect()
end

function XUiTheatre3Master:OnDestroy()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetPanel)
end

--region PanelAsset
function XUiTheatre3Master:InitPanelAsset()
    self.ItemId = XEnumConst.THEATRE3.Theatre3TalentPoint
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ self.ItemId }, self.PanelSpecialTool, nil, handler(self, self.OnBtnClick))
end
--endregion

--region Tab
function XUiTheatre3Master:InitLeftTabBtns()
    self.TabBtns = {
        self.Genius,
        self.Character,
    }
    self.Character:ShowReddot(false)
    self.PanelTab:Init(self.TabBtns, function(index) self:OnSelectBtnTag(index) end)
    self.SelectIndex = 2
end

function XUiTheatre3Master:OnSelectBtnTag(index)
    self.SelectIndex = index
    self.PanelGeniusList.gameObject:SetActiveEx(index == MasterType.Genius)
    self.PanelCharacterList.gameObject:SetActiveEx(index == MasterType.Character)
    if index == MasterType.Genius then
        self:CancelCharacterSelect()
        self:RefreshGeniusTable()
        self:ClickGenuisGridByIndex()
    elseif index == MasterType.Character then
        self:CancelGeniusSelect()
        self:RefreshCharacterGridList()
        self:ClickCharacterGridByIndex(1, 1)
        -- 切换时从第一个进行显示
        if self.CharacterScrollRect then
            self.CharacterScrollRect.verticalNormalizedPosition = 1
        end
    end
end
--endregion

--region 天赋
function XUiTheatre3Master:RefreshGeniusTable()
    local geniusIdList = self._Control:GetStrengthenTreeIdList()
    for index, id in pairs(geniusIdList) do
        local grid = self.GridGeniusList[index]
        if not grid then
            local parent = XUiHelper.TryGetComponent(self.Content, "Genius" .. index)
            if not parent then
                XLog.Error("天赋树Id: " .. id .. "找不到对应ui节点")
                break
            end
            parent.gameObject:SetActiveEx(true)
            local go = XUiHelper.Instantiate(self.GridGenuisDir[self._Control:GetStrengthenTreePointTypeById(id)], parent)
            grid = XUiGridTheatreGenius.New(go, self, index, handler(self, self.ClickGenuisGrid))
            self.GridGeniusList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        -- 线
        if not self.LineGeniusDir[index] then
            local go = XUiHelper.TryGetComponent(self.Content, "RImgBg/Line" .. index)
            if go then
                self.LineGeniusDir[index] = go
            end
        end
        if self.LineGeniusDir[index] then
            self.LineGeniusDir[index].gameObject:SetActiveEx(self._Control:CheckStrengthTreeUnlock(id))
        end
    end

    for i = 1, self.GenuisMaxCount do
        if not self.GridGeniusList[i] then
            local parent = XUiHelper.TryGetComponent(self.Content, "Genius" .. i)
            if parent then
                parent.gameObject:SetActiveEx(false)
            end
        end
    end
    
    -- 移动至ListView正确的位置
    if self.BoundSizeFitter then
        self.BoundSizeFitter:SetLayoutHorizontal()
    end
end

function XUiTheatre3Master:InitGeniusDetailPanel()
    ---@type XUiPanelTheatre3GeniusDetail
    self._PanelGeniusDetail = XUiPanelTheatre3GeniusDetail.New(self.PanelGeniusDetail, self, handler(self, self.RefreshGridGeniusList))
end

---@param grid XUiGridTheatreGenius
function XUiTheatre3Master:GoToGenuis(grid)
    if self.PanelGeniusDrag then
        local scale = (self.PanelGeniusDrag.MinScale + self.PanelGeniusDrag.MaxScale) / 2
        self.PanelGeniusDrag:FocusTarget(grid.Transform, scale, FocusTime, Vector3.zero)
    end
end

-- 模拟点击一个天赋
function XUiTheatre3Master:ClickGenuisGridByIndex()
    if not XTool.IsNumberValid(self.CurGeniusIndex) then
        self.CurGeniusIndex = DefaultId
    end
    local grid = self.GridGeniusList[self.CurGeniusIndex]
    if not grid then
        self.CurGeniusIndex = 0
        return
    end
    self:ClickGenuisGrid(grid)
    -- 第一次打开将选中的自动移到中间位置
    if self.IsFristEnter then
        self.IsFristEnter = false
        self:GoToGenuis(grid)
    end
end

-- 选中 Grid
---@param grid XUiGridTheatreGenius
function XUiTheatre3Master:ClickGenuisGrid(grid)
    local curGrid = self.CurGeniusGrid
    if curGrid and curGrid.GeniusId == grid.GeniusId then
        return
    end
    -- 取消上一次选择
    if curGrid then
        curGrid:SetGeniusSelect(false)
    end
    -- 选中当前选择
    grid:SetGeniusSelect(true)
    -- 刷新详情面板
    self._PanelGeniusDetail:Open()
    self._PanelGeniusDetail:Refresh(grid.GeniusId)

    self.CurGeniusIndex = grid.Index
    self.CurGeniusGrid = grid
end

function XUiTheatre3Master:CancelGeniusSelect()
    if not self.CurGeniusGrid then
        return
    end
    -- 取消当前选择
    self.CurGeniusGrid:SetGeniusSelect(false)
    self.CurGeniusGrid = nil
    -- 关闭详情面板
    self._PanelGeniusDetail:Close()
end

function XUiTheatre3Master:RefreshGridGeniusList()
    self:RefreshGeniusTable()
    self:ClickGenuisGridByIndex()
    self:RefreshGeniusRedPoint()
end

function XUiTheatre3Master:RefreshGeniusRedPoint()
    local isRedPoint = self._Control:CheckAllStrengthenTreeRedPoint()
    self.Genius:ShowReddot(isRedPoint)
end

--endregion

--region 成员
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

--region Ui - BtnListener
function XUiTheatre3Master:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
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
--endregion

return XUiTheatre3Master