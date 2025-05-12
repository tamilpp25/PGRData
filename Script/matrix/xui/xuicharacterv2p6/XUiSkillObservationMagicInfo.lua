local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSkillObservationMagicInfo = XLuaUiManager.Register(XLuaUi, "UiSkillObservationMagicInfo")

function XUiSkillObservationMagicInfo:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiSkillObservationMagicInfo:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiSkillObservationMagicInfo:InitDynamicTable()
    local XGridSkillObservationMagicInfo = require("XUi/XUiCharacterV2P6/Grid/XGridSkillObservationMagicInfo")

    -- 装甲状态
    self.DynamicTableTank = XDynamicTableNormal.New(self.PanelList1)
    self.DynamicTableTank:SetProxy(XGridSkillObservationMagicInfo, self, self)
    self.DynamicTableTank:SetDelegate(self)
    self.DynamicTableTank:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventTank(event, index, grid)
    end)
    local grid = self.DynamicTableTank:GetGrid()
    if grid and grid.gameObject then
        grid.gameObject:SetActiveEx(false)
    end

    -- 增幅状态
    self.DynamicTableAmplifier = XDynamicTableNormal.New(self.PanelList2)
    self.DynamicTableAmplifier:SetProxy(XGridSkillObservationMagicInfo, self, self)
    self.DynamicTableAmplifier:SetDelegate(self)
    self.DynamicTableAmplifier:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventAmplifier(event, index, grid)
    end)
    local grid = self.DynamicTableAmplifier:GetGrid()
    if grid and grid.gameObject then
        grid.gameObject:SetActiveEx(false)
    end
end

function XUiSkillObservationMagicInfo:OnStart(skillId)
    self.SkillId = skillId
end

function XUiSkillObservationMagicInfo:OnEnable()
    if not XTool.IsNumberValid(self.SkillId) then
        return
    end

    local obsCfg = XMVCA.XCharacter:GetModelCharacterObsTriggerMagic()[self.SkillId]
    self.ObsCfg = obsCfg
    if XTool.IsTableEmpty(self.ObsCfg) then
        return
    end

    self.DataTank = {} -- 装甲状态数据，key是element，value是不同level的数据
    self.DataAmplifier = {} -- 增幅状态数据，key是element，value是不同level的数据

    for k, v in pairs(obsCfg.ObservationElement) do
        -- 创建对应的元素的数据
        if not self.DataTank[v] then
            self.DataTank[v] = {}
        end
        if not self.DataAmplifier[v] then
            self.DataAmplifier[v] = {}
        end

        local data = { IndexInCfg = k,  Level = self.ObsCfg.Level[k] }
        if obsCfg.ObservationCareer[k] == XEnumConst.CHARACTER.Career.Tank then
            table.insert(self.DataTank[v], data)
        elseif obsCfg.ObservationCareer[k] == XEnumConst.CHARACTER.Career.Amplifier then
            table.insert(self.DataAmplifier[v], data)
        end
    end

    self.keyInTank = {}
    for k, v in pairs(self.DataTank) do
        if (v[1]) then
            table.insert(self.keyInTank, k)
        end
    end

    self.KeyInAmplifier = {}
    for k, v in pairs(self.DataAmplifier) do
        if (v[1]) then
            table.insert(self.KeyInAmplifier, k)
        end
    end

    self.CurSkillLevel = XMVCA.XCharacter:GetSkillLevel(self.SkillId)

    self.DynamicTableTank:SetDataSource(self.keyInTank)
    self.DynamicTableTank:ReloadDataASync()

    self.DynamicTableAmplifier:SetDataSource(self.KeyInAmplifier)
    self.DynamicTableAmplifier:ReloadDataASync()
   
    -- 判空显示格子
    self.BtnTab1.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.keyInTank))
    self.BtnTab2.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.KeyInAmplifier))

    local defaultSelectIndexInCSharp = 0
    if XTool.IsTableEmpty(self.keyInTank) then
        defaultSelectIndexInCSharp = 1
    elseif XTool.IsTableEmpty(self.KeyInAmplifier) then
        defaultSelectIndexInCSharp = 0
    end
    self.LayerSetting:DoSelectIndex(defaultSelectIndexInCSharp)
end

function XUiSkillObservationMagicInfo:OnDynamicTableEventTank(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local indexInTankData = self.keyInTank[index]
        local dataList = self.DataTank[indexInTankData]
        local targetLevelData = XTool.FindClosestNumber(dataList, self.CurSkillLevel, "Level")
        local targetIndex = targetLevelData.IndexInCfg
        grid:Refresh(self.ObsCfg, targetIndex)
    end
end

function XUiSkillObservationMagicInfo:OnDynamicTableEventAmplifier(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local indexInAmplifierData = self.KeyInAmplifier[index]
        local dataList = self.DataAmplifier[indexInAmplifierData]
        local targetLevelData = XTool.FindClosestNumber(dataList, self.CurSkillLevel, "Level")
        local targetIndex = targetLevelData.IndexInCfg
        grid:Refresh(self.ObsCfg, targetIndex)
    end
end

return XUiSkillObservationMagicInfo
