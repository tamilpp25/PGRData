--大秘境词缀
local XUiRiftAffix = XLuaUiManager.Register(XLuaUi, "UiRiftAffix")
local XUiGridRiftAffixMonster = require("XUi/XUiRift/Grid/XUiGridRiftAffixMonster")
local XUiGridRiftAffixDesc = require("XUi/XUiRift/Grid/XUiGridRiftAffixDesc")

local DynamicTableType = 
{
    Monster = 1,
    Desc = 2,
}

function XUiRiftAffix:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiRiftAffix:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

function XUiRiftAffix:InitDynamicTable()
    -- 2个动态列表
    -- Monster
    self.DynamicTableMonster = XDynamicTableNormal.New(self.PanelMonsterList)
    self.DynamicTableMonster:SetProxy(XUiGridRiftAffixMonster, self)
    self.DynamicTableMonster:SetDelegate(self)
    self.DynamicTableMonster:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, DynamicTableType.Monster)
    end)
    -- Desc
    self.DynamicTableDesc = XDynamicTableNormal.New(self.PanelSkillDescList)
    self.DynamicTableDesc:SetProxy(XUiGridRiftAffixDesc)
    self.DynamicTableDesc:SetDelegate(self)
    self.DynamicTableDesc:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, DynamicTableType.Desc)
    end)
end

function XUiRiftAffix:OnStart(xStageGroup, targetXMonster, isLucky)
    self.MonsterList = isLucky and XDataCenter.RiftManager:GetLuckMonster() or xStageGroup:GetAllEntityMonsters()
    self.CurrMonsterListIndex = 1
    if targetXMonster then
        for index, xMonster in pairs(self.MonsterList) do
            if targetXMonster == xMonster then
                self.CurrMonsterListIndex = index
            end
        end
    end
end

function XUiRiftAffix:OnEnable()
    self:RefreshDynamicTableMonster()
end

function XUiRiftAffix:RefreshDynamicTableMonster()
    self.DynamicTableMonster:SetDataSource(self.MonsterList)
    self.DynamicTableMonster:ReloadDataSync(self.CurrMonsterListIndex)
end

function XUiRiftAffix:RefreshDynamicTableDesc()
    local curMonster = self.CurrMonsterGrid.XMonster
    local npcId = curMonster:GetMonsterNpcId()
    self.TxtMonsterName.text = XMVCA.XCharacter:GetNpcTemplate(npcId).Name
    self.DescList = curMonster:GetAllAffixs()
    self.DynamicTableDesc:SetDataSource(self.DescList)
    self.DynamicTableDesc:ReloadDataSync(1)
end

function XUiRiftAffix:OnDynamicTableEvent(event, index, grid, dynamicTableType)
    if dynamicTableType == DynamicTableType.Monster then
        -- Monster 
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            grid:Refresh(self.MonsterList[index])
            local isSelected = index == self.CurrMonsterListIndex
            grid:SetSelect(isSelected)
            if isSelected then
                self.CurrMonsterGrid = grid
                self:RefreshDynamicTableDesc()
            end
        end
    elseif dynamicTableType == DynamicTableType.Desc then
        -- Desc
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            grid:Refresh(self.DescList[index])
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        end
    end
end

function XUiRiftAffix:OnGridMonsterClick(grid)
    if grid == self.CurrMonsterGrid then
        grid:SetSelect(true)
        return
    end

    if self.CurrMonsterGrid then
        self.CurrMonsterGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurrMonsterGrid = grid
    self.CurrMonsterListIndex = grid.Index
    self:RefreshDynamicTableDesc()
end

function XUiRiftAffix:OnDisable()
end

function XUiRiftAffix:OnDestroy()
end

return XUiRiftAffix