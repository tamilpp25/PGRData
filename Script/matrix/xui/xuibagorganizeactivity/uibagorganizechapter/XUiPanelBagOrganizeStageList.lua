---@class XUiPanelBagOrganizeStageList: XUiNode
---@field _Control XBagOrganizeActivityControl
---@field Parent XUiBagOrganizeChapter
local XUiPanelBagOrganizeStageList = XClass(XUiNode, 'XUiPanelBagOrganizeChapterList')
local XUiGridBagOrganizeStage = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeChapter/XUiGridBagOrganizeStage')

function XUiPanelBagOrganizeStageList:OnStart(chapterId)
    self._ChapterId = chapterId
    self.GridStage.gameObject:SetActiveEx(false)
    self:InitStages()
end

function XUiPanelBagOrganizeStageList:InitStages()
    -- 初始化关卡UI
    local stageIds = self._Control:GetChapterStageIdsById(self._ChapterId)

    if not XTool.IsTableEmpty(stageIds) then
        self._StageGrids = {}
        for index, stageId in ipairs(stageIds) do
            local stageRoot = self['Stage'..index]
            if stageRoot then
                local stageGo = CS.UnityEngine.GameObject.Instantiate(self.GridStage, stageRoot)
                stageGo.transform.anchoredPosition = Vector2.zero
                local grid = XUiGridBagOrganizeStage.New(stageGo, self, stageId, index)
                grid:Open()
                table.insert(self._StageGrids, grid)
            else
                break
            end
        end
    end
end

function XUiPanelBagOrganizeStageList:RefreshStages()
    if not XTool.IsTableEmpty(self._StageGrids) then
        for i, v in ipairs(self._StageGrids) do
            v:Refresh()
        end
    end

end


return XUiPanelBagOrganizeStageList