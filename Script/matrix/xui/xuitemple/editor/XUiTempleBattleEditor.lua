local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTempleBattle = require("XUi/XUiTemple/XUiTempleBattle")
local XUiTempleEditorStageGrid = require("XUi/XUiTemple/Editor/XUiTempleEditorStageGrid")
local XUiTempleBattleBlockOption = require("XUi/XUiTemple/XUiTempleBattleBlockOption")
local XUiTempleEditorPanelRule = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelRule")
local XUiTempleEditorPanelTime = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelTime")
local XUiTempleEditorPanelBlock = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelBlock")
local XUiTempleEditorPanelRound = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelRound")
local XUiTempleEditorPanelRuleTips = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelRuleTips")

---@field _Control XTempleControl
---@class XUiTempleEditor:XUiTempleBattle
local XUiTempleBattleEditor = XLuaUiManager.Register(XUiTempleBattle, "UiTempleBattleEditor")

function XUiTempleBattleEditor:Ctor()
    ---@type XUiTempleBattleBlockOption[]
    self._Option2InitMap = {}

    --self._ActionIndex = 1

    ---@type XUiTempleEditorPanelRule
    self._PanelRule = nil

    ---@type XUiTempleEditorPanelTime
    self._PanelTime = nil

    ---@type XUiTempleEditorPanelBlock
    self._PanelBlock = nil
end

function XUiTempleBattleEditor:InitGameControl()
    self._Control:SetEditor(true)

    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameEditorControl()
end

function XUiTempleBattleEditor:OnAwake()
    XUiTempleBattle.OnAwake(self)

    -- 将editor的uiObject赋值view    
    self:InitUiEditorObjects()
    self:InitStateButtonGroup()

    self.PanelEditRule.gameObject:SetActiveEx(false)
    self._PanelRule = XUiTempleEditorPanelRule.New(self.PanelEditRule, self)
    self.PanelEditTime.gameObject:SetActiveEx(false)
    self._PanelTime = XUiTempleEditorPanelTime.New(self.PanelEditTime, self)
    self.PanelEditBlock.gameObject:SetActiveEx(false)
    self._PanelBlock = XUiTempleEditorPanelBlock.New(self.PanelEditBlock, self)
    self.PanelEditRound.gameObject:SetActiveEx(false)
    self._PanelRound = XUiTempleEditorPanelRound.New(self.PanelEditRound, self)
    self.PanelEditRuleTips.gameObject:SetActiveEx(false)
    self._PanelRuleTips = XUiTempleEditorPanelRuleTips.New(self.PanelEditRuleTips, self)

    self.StageDynamicTable = XDynamicTableNormal.New(self.StageList.transform)
    self.StageDynamicTable:SetProxy(XUiTempleEditorStageGrid, self)
    self.StageDynamicTable:SetDelegate({
        OnDynamicTableEvent = function(_, event, index, grid)
            self:OnStageGridUpdate(event, index, grid)
        end
    })
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiTempleBattleEditor:InitUiEditorObjects()
    local uiEditor = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Editor", "UiObject")
    if uiEditor then
        for i = 0, uiEditor.NameList.Count - 1 do
            self[uiEditor.NameList[i]] = uiEditor.ObjList[i]
        end
    end
end

function XUiTempleBattleEditor:OnStart()
    XUiTempleBattle.OnStart(self)
    local dataProvider = self._GameControl:GetStageList()
    local firstStage = dataProvider[1]
    if firstStage then
        self._GameControl:SetSelectedStage(firstStage.StageId)
    end
end

function XUiTempleBattleEditor:OnEnable()
    XUiTempleBattle.OnEnable(self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_EDIT, self.UpdateByState, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_EDIT_BLOCK_FROM_OPTION, self.UpdateByState, self)
    XScheduleManager.ScheduleNextFrame(function()
        self:UpdateByState()
    end)
end

function XUiTempleBattleEditor:OnDisable()
    XUiTempleBattle.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_EDIT, self.UpdateByState, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_EDIT_BLOCK_FROM_OPTION, self.UpdateByState, self)
end

function XUiTempleBattleEditor:InitStateButtonGroup()
    ---@type XUiButtonGroup
    local buttonGroup = self.ButtonGroup
    buttonGroup:InitBtns({ self.BtnToggle1, self.BtnToggle2, self.BtnToggle3, self.BtnToggle4, self.BtnToggle5, self.BtnToggle6, self.BtnToggle7 }, function(index)
        self._GameControl:OnSelectState(index)
        self:UpdateByState()
    end)
    buttonGroup:SelectIndex(self._GameControl:GetStateButtonGroupIndex(), false)
end

function XUiTempleBattleEditor:UpdateByState()
    local data = self._GameControl:GetUiStateData()
    self.PanelSelectStage.gameObject:SetActiveEx(data.IsSelectStage)
    self.PanelEditMap.gameObject:SetActiveEx(data.IsEditMap)
    if data.IsEditTime then
        self._PanelTime:Open()
    else
        self._PanelTime:Close()
    end
    if data.IsEditRule then
        self._PanelRule:Open()
    else
        self._PanelRule:Close()
    end
    self.PanelEditRound.gameObject:SetActiveEx(data.IsEditRound)
    if data.IsEditRound then
        self._PanelRound:Open()
    else
        self._PanelRound:Close()
    end
    self.PanelRight.gameObject:SetActiveEx(data.IsEditRound)

    if data.IsEditBlock then
        self._PanelBlock:Open()
    else
        self._PanelBlock:Close()
    end

    if data.IsSelectStage then
        self:UpdateStageList()
    end
    if data.IsEditMap then
        self:UpdateEditMapGrid()
    end
    if data.IsEditRule then
        self:UpdateEditRule()
    end
    if data.IsEditTime then
        self._PanelTime:Update()
    end
    if data.IsEditRuleTips then
        self._PanelRuleTips:Open()
    else
        self._PanelRuleTips:Close()
    end
end

function XUiTempleBattleEditor:UpdateStageList()
    local dataProvider = self._GameControl:GetStageList()
    self.StageDynamicTable:SetDataSource(dataProvider)
    self.StageDynamicTable:ReloadDataSync()
end

function XUiTempleBattleEditor:OnStageGridUpdate(event, index, grid)
    local data = self.StageDynamicTable:GetData(index)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(data)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._GameControl:SetSelectedStage(data.StageId)
        self:UpdateStageList()
    end
end

function XUiTempleBattleEditor:UpdateEditMapGrid()
    local options = self._GameControl:GetOption2InitMap()
    self:UpdateDynamicItem(self._Option2InitMap, options, self.BtnOptionEditor, XUiTempleBattleBlockOption)

    for i = 1, #options do
        local option = self._Option2InitMap[i].Button
        self:RegisterClickEvent(option, function()
            self._GameControl:OnClickBlockOptionEditor(options[i].BlockId)
        end, true)
    end
end

function XUiTempleBattleEditor:UpdateEditRule()
    self._PanelRule:Update()
end

return XUiTempleBattleEditor
