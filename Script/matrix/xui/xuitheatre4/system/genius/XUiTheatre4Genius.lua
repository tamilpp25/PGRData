local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre4GeniusGrid = require("XUi/XUiTheatre4/System/Genius/XUiTheatre4GeniusGrid")
--local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
local XUiTheatre4HandbookGeniusCard = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookGeniusCard")

---@class XUiTheatre4Genius:XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4Genius = XLuaUiManager.Register(XLuaUi, "UiTheatre4Genius")

function XUiTheatre4Genius:OnAwake()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)

    ---@type XUiTheatre4ColorResource
    --self._PanelResource = XUiTheatre4ColorResource.New(self.ListColour, self)
    --self._PanelResource:Close()

    self.DynamicTable = XDynamicTableNormal.New(self.ListProp)
    self.DynamicTable:SetProxy(XUiTheatre4GeniusGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridGenius.gameObject:SetActiveEx(false)

    self._IsHandbook = false
    self._CurrentSelectColor = nil
    self._IsChange = true
    self._LimitIndex = 0
    self._ListPos = nil
    self._CenterPos = nil
    self._TweenTimer = nil
    self._BackTweenTimer = nil
    self._CurrentSelectIndex = nil

    local buttonGroup = self.ListTab
    buttonGroup.gameObject:SetActiveEx(true)
    self._BtnList = {
        self.BtnRed,
        self.BtnYellow,
        self.BtnBlud,
    }
    buttonGroup:Init(self._BtnList, function(groupIndex)
        self:SetCurrentColorType(groupIndex)
        self:Update()
    end)

    ---@type XUiTheatre4HandbookGeniusCard
    self._GeniusCardUi = XUiTheatre4HandbookGeniusCard.New(self.GridGeniusCard, self)
    self._GeniusCardUi:Close()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseTip, self.OnClickTip)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnClickCharacter)
end

function XUiTheatre4Genius:OnStart(color, isHandbook)
    color = color or XEnumConst.Theatre4.ColorType.Red

    self._IsHandbook = isHandbook or false

    self:InitCenterPoint()
    self:SetCurrentColorType(color)
    self.ListTab:SelectIndex(color, false)

    if isHandbook then
        self.BtnCharacter.gameObject:SetActiveEx(false)
    else
        local entities = XMVCA.XTheatre4:GetCharacterList()
        if #entities == 0 then
            self.BtnCharacter.gameObject:SetActiveEx(false)
        end
    end

    self:UpdateColorResources()
end

function XUiTheatre4Genius:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_CLICK_TALENT_GRID, self.OnClickTalent, self)
end

function XUiTheatre4Genius:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_CLICK_TALENT_GRID, self.OnClickTalent, self)
    if XLuaUiManager.IsMaskShow(self.Name) then
        XLuaUiManager.SetMask(false, self.Name)
    end
    if self._TweenTimer then
        XScheduleManager.UnSchedule(self._TweenTimer)
        self._TweenTimer = nil
    end
    if self._BackTweenTimer then
        XScheduleManager.UnSchedule(self._BackTweenTimer)
        self._BackTweenTimer = nil
    end
end

function XUiTheatre4Genius:OnDestroy()
    if XLuaUiManager.IsMaskShow(self.Name) then
        XLuaUiManager.SetMask(false, self.Name)
    end
end

function XUiTheatre4Genius:Update()
    local dataSource = self:GetDataSource()

    self.DynamicTable:SetDataSource(dataSource)
    local index = 1
    if not self._IsHandbook then
        for i = 1, #dataSource do
            local data = dataSource[i]
            if data.IsActive then
                index = data.Index

                local key = self._Control:GetSaveKey() .. "GeniusGridUnlockEffect" .. XPlayer.Id .. data.ColorType .. data.Index
                if not XSaveTool.GetData(key) then
                    break
                end
            end
        end
    end
    self.DynamicTable:ReloadDataSync(index)

    self:RefreshBuildingPoint()
end

function XUiTheatre4Genius:UpdateDataSource()
    local dataSource = self:GetDataSource()
    self.DynamicTable:SetDataSource(dataSource)
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Update(dataSource[index], index)
    end
end

function XUiTheatre4Genius:GetDataSource()
    if self._IsHandbook then
        return self._Control.SystemControl:GetGeniusDatasByColorType(
                self._ColorType or XEnumConst.Theatre4.ColorType.Red)
    else
        self._Control.SetControl:UpdateGenius()
        return self._Control.SetControl:GetUiData().Genius.List
    end
end

function XUiTheatre4Genius:SetCurrentColorType(colorType)
    if self._IsHandbook then
        self._ColorType = colorType
    else
        self._Control.SetControl:SetGeniusColor(colorType)
    end
    self._IsChange = self._CurrentSelectColor ~= colorType
    self._CurrentSelectColor = colorType
end

function XUiTheatre4Genius:InitLimitGridMap()
    local gridSize = self.DynamicTable:GetGridSize()
    local spaceSize = self.DynamicTable:GetSpacing()

    self._LimitIndex = math.floor(CS.UnityEngine.Screen.width / 2 / (gridSize.x + spaceSize.x))
end

function XUiTheatre4Genius:InitCenterPoint()
    local camera = CS.UnityEngine.Camera.main
    local width = CS.UnityEngine.Screen.width
    local posZ = math.abs(camera.transform.position.z - self.Transform.position.z)

    self._ListPos = self.ListProp.transform.position
    self._CenterPos = camera:ScreenToWorldPoint(Vector3(width / 2, 0, posZ))
end

---@param grid XUiTheatre4GeniusGrid
function XUiTheatre4Genius:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index), index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:InitLimitGridMap()
        self:PlayGeniusAnimation()
    end
end

function XUiTheatre4Genius:OnClickTip()
    self.BtnCloseTip.gameObject:SetActiveEx(false)
    self.ListProp.transform.position = self._ListPos
    self._GeniusCardUi:Close()
    self._CurrentSelectIndex = nil
    self._Control.SystemControl:SetSelectedGenius(false)
    self._Control.SetControl:SetSelectedGenius(false)
    self:UpdateDataSource()
end

function XUiTheatre4Genius:OnClickTalent(data, grid)
    if not grid then
        return
    end

    local id = data.Id
    if not data.IsCanClick then
        return
    end
    self._Control.SetControl:SetSelectedGenius(data)
    self._Control.SystemControl:SetSelectedGenius(data)
    self:UpdateDataSource()

    ---@type XTheatre4ColorTalentEntity
    local entity
    if id then
        entity = self._Control.SetControl:GetTalentEntity4UiCard(id)
    end

    if entity and not entity:IsEmpty() then
        entity:SetIsInGame(true)
        if data.IsActive then
            entity:SetIsActiveOnGame(true)
        else
            entity:SetIsActiveOnGame(false)
        end
    end
    self.BtnCloseTip.gameObject:SetActiveEx(true)
    self._GeniusCardUi:Open()
    self._GeniusCardUi:Refresh(entity)
    --end
    local gridIndex = grid:GetIndex()

    if self._CurrentSelectIndex ~= gridIndex then
        if gridIndex <= self._LimitIndex then
            self.DynamicTable:ScrollToIndex(1, 0.1, function()
                XLuaUiManager.SetMask(true, self.Name)
            end, function()
                local centerPointX = self._CenterPos.x
                local diffX = centerPointX - grid.Transform.position.x
                local startPos = self._ListPos

                if self._CurrentSelectIndex ~= nil then
                    startPos = self.ListProp.transform.position
                end

                self._TweenTimer = XUiHelper.Tween(0.5, function(time)
                    self.ListProp.transform.position = Vector3(startPos.x + diffX * time, startPos.y, startPos.z)
                end, function()
                    XLuaUiManager.SetMask(false, self.Name)
                    self._TweenTimer = nil
                end, function(time)
                    return XUiHelper.Evaluate(XUiHelper.EaseType.OutBack, time)
                end)
            end)
        else
            if self._CurrentSelectIndex ~= nil then
                local endPosX = self._ListPos.x
                local startPos = self.ListProp.transform.position

                if endPosX ~= startPos.x then
                    local diffX = endPosX - startPos.x

                    XLuaUiManager.SetMask(true, self.Name)
                    self._BackTweenTimer = XUiHelper.Tween(0.3, function(time)
                        self.ListProp.transform.position = Vector3(startPos.x + diffX * time, startPos.y, startPos.z)
                    end, function()
                        XLuaUiManager.SetMask(false, self.Name)
                        self._BackTweenTimer = nil
                        self.DynamicTable:CenterToSelected(grid.GameObject, 0.6)
                    end, function(time)
                        return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, time)
                    end)
                else
                    self.DynamicTable:CenterToSelected(grid.GameObject, 0.6)
                end
            else
                self.DynamicTable:CenterToSelected(grid.GameObject, 0.6)
            end
        end
    end
    self._CurrentSelectIndex = gridIndex
end

function XUiTheatre4Genius:PlayGeniusAnimation()
    if not self._IsChange then
        return
    end

    RunAsyn(function()
        asynWaitSecond(0.02)
        XLuaUiManager.SetMask(true, self.Name)

        local grids = self.DynamicTable:GetGrids()
        local startIndex = self.DynamicTable:GetStartIndex()

        if not XTool.IsTableEmpty(grids) then
            for i = startIndex, table.nums(grids) + startIndex - 1 do
                local grid = grids[i]

                if grid then
                    grid:SetAlpha(0)
                end
            end
        end

        if not XTool.IsTableEmpty(grids) then
            for i = startIndex, table.nums(grids) + startIndex - 1 do
                local grid = grids[i]

                if grid then
                    grid:PlayAnimation("GridGeniusEnable", function()
                        if grid then
                            grid:SetAlpha(1)
                        end
                    end)
                end

                asynWaitSecond(0.04)
            end
        end
        XLuaUiManager.SetMask(false, self.Name)
    end)
end

function XUiTheatre4Genius:OnClickCharacter()
    self._Control:OpenCharacterPanel()
end

function XUiTheatre4Genius:UpdateColorResources()
    self:UpdateColorTalentLevel(self.BtnRed, XEnumConst.Theatre4.ColorType.Red)
    self:UpdateColorTalentLevel(self.BtnYellow, XEnumConst.Theatre4.ColorType.Yellow)
    self:UpdateColorTalentLevel(self.BtnBlud, XEnumConst.Theatre4.ColorType.Blue)
end

function XUiTheatre4Genius:UpdateColorTalentLevel(prefab, colorId)
    local btn = {}
    XTool.InitUiObjectByUi(btn, prefab)

    if self._IsHandbook then
        btn.PanelClassOn.gameObject:SetActiveEx(false)
        btn.PanelClassOff.gameObject:SetActiveEx(false)
    else
        local point = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColoPoint, colorId)
        local colorTalentLevel = self._Control:GetColorTalentLevel(colorId, point)

        btn.PanelClassOn.gameObject:SetActiveEx(true)
        btn.PanelClassOff.gameObject:SetActiveEx(true)
        if btn.TxtClassNumOn then
            btn.TxtClassNumOn.text = string.format("Lv.%s", colorTalentLevel)
        end
        if btn.TxtClassNumOff then
            btn.TxtClassNumOff.text = string.format("Lv.%s", colorTalentLevel)
        end
    end
end

function XUiTheatre4Genius:RefreshBuildingPoint()
    if self._IsHandbook then
        -- 局外预览
        self.PanelProgres = self.PanelProgres or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTitle/PanelProgress", "Transform")
        if self.PanelProgres then
            self.PanelProgres.gameObject:SetActiveEx(false)
        end
    else
        -- 局内天赋
        local data = self._Control.SetControl:GetUiData().Genius
        self.TxtScoreNum.text = data.BuildingPointAccumulate
        if data.BuildingPointNow then
            self.GridNow.gameObject:SetActiveEx(true)
            self.TxtScoreNumNow.text = data.BuildingPointNow
        else
            self.GridNow.gameObject:SetActiveEx(false)
        end
    end
end

return XUiTheatre4Genius
