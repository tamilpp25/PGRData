---@class XUiTheatre3FightResult : XLuaUi
---@field _Control XTheatre3Control
---@field PanelRole XUiButtonGroup
local XUiTheatre3FightResult = XLuaUiManager.Register(XLuaUi, "UiTheatre3FightResult")

function XUiTheatre3FightResult:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3FightResult:OnStart()
    self:InitCharacter()
    self:InitFightResult()
end

function XUiTheatre3FightResult:OnEnable()
    self:RefreshCharacter()
    self.PanelRole:SelectIndex(self:_GetNotEmptySlotId())
end

--region Ui - Character
function XUiTheatre3FightResult:InitCharacter()
    local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")
    ---@type XUiTheatre3EquipmentCharacter[]
    self._CharacterList = {
        XUiTheatre3EquipmentCharacter.New(self.CharacterGrid1.transform, self, 1),
        XUiTheatre3EquipmentCharacter.New(self.CharacterGrid2.transform, self, 2),
        XUiTheatre3EquipmentCharacter.New(self.CharacterGrid3.transform, self, 3),
    }
    self._CharacterEquipTxtList = {
        self.TxtNumber1,
        self.TxtNumber2,
        self.TxtNumber3,
    }
    self._RoleBtnList = {
        self.CharacterGrid1,
        self.CharacterGrid2,
        self.CharacterGrid3,
    }
    self.PanelRole:Init(self._RoleBtnList, handler(self, self.RefreshFightResult))
end

function XUiTheatre3FightResult:RefreshCharacter()
    for slotId, grid in pairs(self._CharacterList) do
        local characterId = self._Control:GetSlotCharacter(slotId)
        local isNoEmpty = characterId ~= 0
        if isNoEmpty then
            grid:Update()
            grid:IsShowCapacity(false)
            grid.Transform.parent.gameObject:SetActiveEx(true)
        else
            grid.Transform.parent.gameObject:SetActiveEx(false)
        end
        local cur = self._Control:GetSlotCapcity(slotId)
        local all = self._Control:GetSlotMaxCapcity(slotId)
        self._CharacterEquipTxtList[slotId].text = XUiHelper.GetText("Theatre3TxtFightResultEquipNumber", cur, all)
    end
end

function XUiTheatre3FightResult:_GetNotEmptySlotId()
    for slotId, _ in pairs(self._CharacterList) do
        local characterId = self._Control:GetSlotCharacter(slotId)
        local isNoEmpty = characterId ~= 0
        if isNoEmpty then
            return slotId
        end
    end
end
--endregion

--region Ui - FightResult
function XUiTheatre3FightResult:InitFightResult()
    local XUiTheatre3GridFightResult = require("XUi/XUiTheatre3/Adventure/FightResult/XUiTheatre3GridFightResult")
    ---@type XUiTheatre3GridFightResult
    self._GridAllFightData = XUiTheatre3GridFightResult.New(self.GridResult, self)
    
    ---@type XUiTheatre3PanelEquipFightResult[]
    self._GridEquipFightDataList = {}
    self.GridEquipFightData.gameObject:SetActiveEx(false)
end

---@return XUiTheatre3PanelEquipFightResult
function XUiTheatre3FightResult:_CreateEquipFightResult(obj)
    local XUiTheatre3PanelEquipFightResult = require("XUi/XUiTheatre3/Adventure/FightResult/XUiTheatre3PanelEquipFightResult")
    return XUiTheatre3PanelEquipFightResult.New(obj, self)
end

function XUiTheatre3FightResult:RefreshFightResult(slotId)
    if not slotId or self._CurShowSlotId == slotId then
        return
    end
    self._CurShowSlotId = slotId
    self._GridAllFightData:RefreshBySlotId(self._CurShowSlotId)
    
    local equipSuitList = self._Control:GetAdventureFightRecordSuitList(self._CurShowSlotId)
    if XTool.IsTableEmpty(equipSuitList) then
        self.PanelFightData.gameObject:SetActiveEx(false)
        self.PanelEmpty.gameObject:SetActiveEx(true)
        return
    end

    self.PanelFightData.gameObject:SetActiveEx(true)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    
    for i, suitId in ipairs(equipSuitList) do
        local grid = self._GridEquipFightDataList[i]
        if not grid then
            grid = self:_CreateEquipFightResult(XUiHelper.Instantiate(self.GridEquipFightData, self.GridEquipFightData.parent))
            self._GridEquipFightDataList[i] = grid
        end
        grid:Open()
        grid:Refresh(self._CurShowSlotId, suitId)
    end
    for i = #equipSuitList + 1, #self._GridEquipFightDataList do
        self._GridEquipFightDataList[i]:Close()
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3FightResult:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
end

function XUiTheatre3FightResult:OnBtnBackClick()
    self:Close()
end
--endregion

return XUiTheatre3FightResult