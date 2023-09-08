local XUiGridChapterStage = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridChapterStage")

---@class XUiPanelChapter : XUiNode 国际战旗关卡列表
---@field _Control XBlackRockChessControl
local XUiPanelChapter = XClass(XUiNode, "XUiPanelChapter")

function XUiPanelChapter:OnStart()
    ---@type XUiGridChapterStage[]
    self._Stages = {}
    self._ChessOffset = self._Control:GetChapterScrollOffset()
end

function XUiPanelChapter:SetData(chapterId, type)
    self._ChapterId = chapterId
    self._Type = type
    self._DimIndex = 1
    self._OffYMap = {}

    self:Refresh()

    if self.Content then
        local tabs = {}
        local cbs = {}
        for _, grid in pairs(self._Stages) do
            table.insert(tabs, grid.BtnChess)
            table.insert(cbs, handler(grid, grid.DoClick))
        end
        self.Content:Init(tabs, function(index)
            local needScroll = false
            if cbs[index] then
                needScroll = cbs[index]()
            end
            if needScroll then
                self:ScrollTo(index)
            end
        end)
    end

    self:ScrollTo(self._DimIndex)
end

function XUiPanelChapter:Refresh()
    local stageIds = self._Control:GetChapterStageIds(self._ChapterId, self._Type)
    local curStageId = self._Control:GetNextStageId(self._ChapterId, self._Type)
    for i = 1, #stageIds do
        local go = self["GridStage" .. i]
        if go then
            local grid = self._Stages[i]
            if not grid then
                ---@type XUiGridChapterStage
                grid = XUiGridChapterStage.New(go, self)
                self._Stages[i] = grid
            end
            if stageIds[i] == curStageId then
                self._DimIndex = i
            end
            self._OffYMap[i] = go.anchoredPosition.x
            local lastStageId = i == 1 and nil or stageIds[i - 1]
            grid:SetData(stageIds[i], lastStageId, curStageId, i)
        else
            XLog.Error("国际战旗章节" .. self._ChapterId .. "缺少关卡节点" .. i)
        end
    end
end

function XUiPanelChapter:ScrollTo(index)
    if not self.PanelStageList then
        return
    end
    local contentWidth = self.Content.transform.rect.width - self.PanelStageList.transform.rect.width
    local value = (self._OffYMap[index] - self._ChessOffset) / contentWidth
    value = CS.UnityEngine.Mathf.Clamp(value, 0, 1)
    self.PanelStageList.horizontalNormalizedPosition = value
end

return XUiPanelChapter