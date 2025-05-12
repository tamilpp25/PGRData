local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2EditorStageGrid = require("XUi/XUiTemple2/Editor/XUiTemple2EditorStageGrid")
local XUiTemple2EditorBlockOption = require("XUi/XUiTemple2/Editor/XUiTemple2EditorBlockOption")
local XUiTemple2EditorEditBlock = require("XUi/XUiTemple2/Editor/EditBlock/XUiTemple2EditorEditBlock")
local XUiTemple2EditorBlockPool = require("XUi/XUiTemple2/Editor/BlockPool/XUiTemple2EditorBlockPool")
local XUiTemple2CheckBoard = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoard")
local XUiTemple2EditorBlockRandomPool = require("XUi/XUiTemple2/Editor/BlockPool/XUiTemple2EditorBlockRandomPool")

local TAB = {
    SELECT_STAGE = 1,
    EDIT_BLOCK = 2,
    EDIT_MAP = 3,
    BLOCK_POOL = 4,
    RANDOM_BLOCK_POOL = 5,
    GAME = 6,
}

---@class XUiTemple2Editor : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Editor = XLuaUiManager.Register(XLuaUi, "UiTemple2Editor")

function XUiTemple2Editor:Ctor()
    self._OptionGrids = {}
end

function XUiTemple2Editor:GetControl()
    return self._Control:GetEditorControl()
end

function XUiTemple2Editor:OnAwake()
    self:RegisterClickEvent(
            self.BtnBack,
            function()
                self:GetControl():TrySave(function()
                    self:Close()
                end)
            end, nil, true
    )
    self.BtnMainUi.gameObject:SetActiveEx(false)

    self.GridStage.gameObject:SetActiveEx(false)
    self.DynamicTableStage = XDynamicTableNormal.New(self.StageList)
    self.DynamicTableStage:SetProxy(XUiTemple2EditorStageGrid, self)
    self.DynamicTableStage:SetDelegate({
        ---@param grid XUiTemple2EditorStageGrid
        OnDynamicTableEvent = function(ui, event, index, grid)
            if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
                grid:Update(self.DynamicTableStage:GetData(index))

            elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
                self:GetControl():TrySave(function()
                    self:GetControl():SetSelectedStage(self.DynamicTableStage:GetData(index))
                    self:UpdateStageList()
                end)
            end
        end
    })

    ---@type XUiTemple2CheckBoard
    self._CheckBoard = XUiTemple2CheckBoard.New(self.PanelCheckerboard, self, self._Control:GetEditorControl())

    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnClickSave)

    ---@type XUiTemple2EditorEditBlock
    self._PanelEditBlock = XUiTemple2EditorEditBlock.New(self.PanelEditBlock, self)

    ---@type XUiTemple2EditorBlockPool
    self._PanelBlockPool = XUiTemple2EditorBlockPool.New(self.PanelBlockPool, self)

    ---@type XUiTemple2EditorBlockRandomPool
    self._PanelBlockRandomPool = XUiTemple2EditorBlockRandomPool.New(self.PanelBlockRandomPool, self)

    XUiHelper.RegisterClickEvent(self, self.ButtonSize, self.OnClickChangeSize)

    XUiHelper.RegisterClickEvent(self, self.BtnResetEditMap, self.OnClickReset)

    self.ButtonGroup:Init({
        self.BtnToggle1,
        self.BtnToggle2,
        self.BtnToggle3,
        self.BtnToggle4,
        self.BtnToggle5,
        self.BtnToggle6,
    }, function(index)
        self:OnTabClick(index)
    end)
end

function XUiTemple2Editor:OnStart()
end

function XUiTemple2Editor:OnEnable()
    xpcall(function()
        self:Update()
    end, function(msg)
        XLog.Error(msg)
    end)

    local timer = XScheduleManager.ScheduleForever(function()
        self:GetControl():UpdateGame(self._CheckBoard)
    end, 0, 0)
    self:_AddTimerId(timer)
end

function XUiTemple2Editor:OnDisable()

end

function XUiTemple2Editor:Update()
    self.ButtonGroup:SelectIndex(TAB.SELECT_STAGE)
end

function XUiTemple2Editor:OnTabClick(index)
    self.PanelSelectStage.gameObject:SetActiveEx(false)
    self.PanelEditMap.gameObject:SetActiveEx(false)
    self._PanelEditBlock:Close()
    self._PanelBlockPool:Close()
    self._PanelBlockRandomPool:Close()

    if index == TAB.SELECT_STAGE then
        self.PanelSelectStage.gameObject:SetActiveEx(true)
        self:UpdateStageList()
        self._CheckBoard:Open()
        return
    end

    if index == TAB.EDIT_BLOCK then
        self.PanelSelectStage.gameObject:SetActiveEx(false)
        self.PanelEditMap.gameObject:SetActiveEx(false)
        self._PanelEditBlock:Open()
        self._CheckBoard:Close()
        return
    end

    if index == TAB.EDIT_MAP then
        self.PanelEditMap.gameObject:SetActiveEx(true)
        self:UpdateEditMap()
        self._CheckBoard:Open()
        local x, y = self:GetControl():GetMapSize()
        self.InputFieldSizeX.text = x
        self.InputFieldSizeY.text = y
        return
    end

    if index == TAB.BLOCK_POOL then
        self.PanelEditMap.gameObject:SetActiveEx(false)
        self._PanelBlockPool:Open()
        return
    end

    if index == TAB.RANDOM_BLOCK_POOL then
        self.PanelEditMap.gameObject:SetActiveEx(false)
        self._PanelBlockRandomPool:Open()
        return
    end

    if index == TAB.GAME then
        self._Control:GetEditorControl():TrySave(function()
            self._Control:GetEditorControl():OpenGameUi()
        end)
        return
    end
end

function XUiTemple2Editor:UpdateStageList()
    local stageList = self:GetControl():GetUiDataStage()
    self.DynamicTableStage:SetDataSource(stageList)
    self.DynamicTableStage:ReloadDataSync(1)
    self:UpdateMap()
    self._CheckBoard:UpdateBg()
end

function XUiTemple2Editor:UpdateMap()
    self._CheckBoard:Update()
end

function XUiTemple2Editor:UpdateEditMap()
    local options = self:GetControl():GetUiDataBlockOptions()
    XTool.UpdateDynamicItem(self._OptionGrids, options, self.BtnOptionEditor, XUiTemple2EditorBlockOption, self)
end

function XUiTemple2Editor:OnClickSave()
    self:GetControl():Save()
    self:GetControl():PrintPath()
end

function XUiTemple2Editor:OnClickChangeSize()
    local x = tonumber(self.InputFieldSizeX.text)
    local y = tonumber(self.InputFieldSizeY.text)
    if x and y and x > 0 and y > 0 then
        self._Control:GetEditorControl():SetMapSize(x, y)
        self:UpdateMap()
    end
end

function XUiTemple2Editor:OnClickReset()
    self:GetControl():ResetMap()
    self:UpdateMap()
end

return XUiTemple2Editor