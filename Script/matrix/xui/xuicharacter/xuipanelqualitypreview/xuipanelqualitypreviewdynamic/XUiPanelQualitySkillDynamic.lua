--===========================================================================
--v1.28 分阶拆分-XUiPanelQualityPreview-技能成长动态列表：XUiPanelQualitySkillDynamic
--===========================================================================
local XUiPanelQualitySkillDynamic = XClass(nil, "XUiPanelQualitySkillDynamic")
local UiPanelQualitySkillGrid = require("XUi/XUiCharacter/XUiPanelQualityPreview/XUiPanelQualityPreviewGrid/XUiPanelQualitySkillGrid")

function XUiPanelQualitySkillDynamic:Ctor(ui, rootUi, skillData, character)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.SkillData = skillData
    self.Character = character

    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(ui)
    self.DynamicTable:SetProxy(UiPanelQualitySkillGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelQualitySkillDynamic:RefreshData(skillData, character)
    self.SkillData = skillData
    self.Character = character
end

function XUiPanelQualitySkillDynamic:UpdateDynamicTable(index)
    if not index then index = 1 end
    self.DynamicTable:SetDataSource(self.SkillData)
    self.DynamicTable:ReloadDataASync(index)
end

function XUiPanelQualitySkillDynamic:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local star = self.Character.Star
        local quality = self.Character.Quality
        local thisSkillQuality = XCharacterConfigs.GetCharSkillQualityApartQuality(self.SkillData[index])
        local thisSkillPhase = XCharacterConfigs.GetCharSkillQualityApartPhase(self.SkillData[index])
        -- 当前节点是否激活
        local isLight = quality > thisSkillQuality or quality == thisSkillQuality and star >= thisSkillPhase
        local isNext = false
        if index > 1 then
            local beforeSkillQuality = XCharacterConfigs.GetCharSkillQualityApartQuality(self.SkillData[index - 1])
            local beforeSkillPhase = XCharacterConfigs.GetCharSkillQualityApartPhase(self.SkillData[index - 1])
            -- 上一个节点是否激活
            local before = quality > beforeSkillQuality or quality == beforeSkillQuality and star >= beforeSkillPhase
            -- 当前未激活，上一个激活则当前节点为待点亮
            isNext = before and not isLight
        end
        grid:Refresh(self.SkillData[index], isLight, isNext)
    end
end

return XUiPanelQualitySkillDynamic