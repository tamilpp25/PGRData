local XUiReplaceGrid = require("XUi/XUiGoldenMiner/Replace/XUiReplaceGrid")

--黄金矿工更换成员界面
local XUiGoldenMinerChange = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerChange")

function XUiGoldenMinerChange:OnAwake()
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self:RegisterButtonEvent()
    self:InitDynamicList()
end

function XUiGoldenMinerChange:OnStart(closeCb, updateUseCharacterFunc)
    self.CloseCb = closeCb
    self.UpdateUseCharacterFunc = updateUseCharacterFunc
    self.UseCharacterId = XDataCenter.GoldenMinerManager.GetUseCharacterId()
end

function XUiGoldenMinerChange:OnEnable()
    self.CurSelectGrid = nil
    self.DynamicTable:ReloadDataSync()
end

function XUiGoldenMinerChange:InitDynamicList()
    self.CharacterIdList = XDataCenter.GoldenMinerManager.GetCharacterIdList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiReplaceGrid)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetDataSource(self.CharacterIdList)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
end

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
        if not XDataCenter.GoldenMinerManager.IsCharacterUnLock(characterId) then
            local conditionId = XGoldenMinerConfigs.GetCharacterCondition(characterId)
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            XUiManager.TipError(desc)
            return
        end

        if not self.CurSelectGrid or self:IsCurSelectCharacter(characterId) then
            return
        end
        self.CurSelectGrid:SetSelectActive(false)
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

function XUiGoldenMinerChange:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick)
end

function XUiGoldenMinerChange:OnBtnChangeClick()
    local pos = 1
    local team = XDataCenter.GoldenMinerManager.GetTeam()
    team:UpdateEntityTeamPos(self.UseCharacterId, pos, true)
    self:OnBtnCancelClick()
end

function XUiGoldenMinerChange:OnBtnCancelClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end