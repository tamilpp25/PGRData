local XUiReplaceGrid = require("XUi/XUiGoldenMiner/Replace/XUiReplaceGrid")

---黄金矿工更换成员界面
---@class XUiGoldenMinerChange : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerChange = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerChange")

function XUiGoldenMinerChange:OnAwake()
    self.DataDb = self._Control:GetMainDb()
    self:RegisterButtonEvent()
    self:InitDynamicList()
end

function XUiGoldenMinerChange:OnStart(closeCb, updateUseCharacterFunc)
    self.CloseCb = closeCb
    self.UpdateUseCharacterFunc = updateUseCharacterFunc
    self.UseCharacterId = self._Control:GetUseCharacterId()
end

function XUiGoldenMinerChange:OnEnable()
    self.CurSelectGrid = nil
    self:UpdateDynamicList()
end

function XUiGoldenMinerChange:OnDisable()
    self._Control:ClearAllNewRoleTag()
end

--region Ui - CharacterGrid DynamicTable
function XUiGoldenMinerChange:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiReplaceGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerChange:UpdateDynamicList()
    self.CharacterIdList = self._Control:GetCharacterIdList()
    self.DynamicTable:SetDataSource(self.CharacterIdList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiReplaceGrid
function XUiGoldenMinerChange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.RootUi
        local characterId = self.CharacterIdList[index]
        local isCurSelectCharacter = self:IsCurSelectCharacter(characterId)
        grid:Refresh(characterId)
        grid:SetSelectActive(isCurSelectCharacter)
        if not self.CurSelectGrid and isCurSelectCharacter then
            self.CurSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local characterId = self.CharacterIdList[index]
        if not self._Control:IsCharacterUnLock(characterId) then
            local conditionId = self._Control:GetCfgCharacterCondition(characterId)
            local isOpen, desc = XConditionManager.CheckCondition(conditionId, characterId)
            XUiManager.TipError(desc)
            return
        end

        self._Control:ClearNewRoleTag(characterId)
        if self:IsCurSelectCharacter(characterId) then
            return
        end
        if self.CurSelectGrid then
            self.CurSelectGrid:SetSelectActive(false)
        end
        grid:SetSelectActive(true)
        self.CurSelectGrid = grid
        self.UseCharacterId = grid:GetCharacterId()
        if self.UpdateUseCharacterFunc then
            self.UpdateUseCharacterFunc(self.UseCharacterId)
        end
    end
end

function XUiGoldenMinerChange:IsCurSelectCharacter(characterId)
    return self.UseCharacterId == characterId
end
--endregion


--region Ui - BtnListener
function XUiGoldenMinerChange:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick)
end

function XUiGoldenMinerChange:OnBtnChangeClick()
    self._Control:CatchCurCharacterId(self.UseCharacterId)
    self:OnBtnCancelClick()
end

function XUiGoldenMinerChange:OnBtnCancelClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end
--endregion