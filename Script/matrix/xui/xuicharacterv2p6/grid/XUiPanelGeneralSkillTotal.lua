local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelGeneralSkillTotal
---@field Parent XUiCharacterAttributeDetail
local XUiPanelGeneralSkillTotal = XClass(XUiNode, 'XUiPanelGeneralSkillTotal')
local XUiGridGeneralSkillDetail = require('XUi/XUiCharacterV2P6/Grid/XUiGridGeneraslSkillDetail')

function XUiPanelGeneralSkillTotal:OnStart()
    self._DynamicTable = XDynamicTableNormal.New(self.TableGeneralSkill)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiGridGeneralSkillDetail, self)
    self.GridElementDetail.gameObject:SetActiveEx(false)
end


function XUiPanelGeneralSkillTotal:OnEnable()
    self._CurgeneralSkills = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.Parent.CharacterId)

    self._GeneralSkillCfg = self:GetSortedCfgList()
    self._DynamicTable:SetDataSource(self._GeneralSkillCfg)
    self._DynamicTable:ReloadDataASync()
end

function XUiPanelGeneralSkillTotal:OnDisable()
    self._DynamicTable:RecycleAllTableGrid()
end

function XUiPanelGeneralSkillTotal:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._GeneralSkillCfg[index], table.contains(self._CurgeneralSkills, self._GeneralSkillCfg[index].Id))
    end
end

function XUiPanelGeneralSkillTotal:GetSortedCfgList()
    local cfgs = XMVCA.XCharacter:GetModelCharacterGeneralSkill()
    local sortTable = {}
    for i, v in pairs(cfgs) do
        table.insert(sortTable, v)
    end
    
    table.sort(sortTable, function(a, b) 
        
        local aIsCur = table.contains(self._CurgeneralSkills, a.Id)
        local bIsCur = table.contains(self._CurgeneralSkills, b.Id)
        
        -- 当前标签置顶，其他情况按Id升序
        if aIsCur and bIsCur then
            return a.Id < b.Id
        elseif aIsCur then
            return true
        elseif bIsCur then
            return false
        end
        
        return a.Id < b.Id
    end)
    
    return sortTable
end

return XUiPanelGeneralSkillTotal