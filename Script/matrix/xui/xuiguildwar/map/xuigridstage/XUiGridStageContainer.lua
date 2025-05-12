--- 关卡容器
---@class XUiGridStageContainer: XUiNode
---@field private _NodeDict table @key: nodeId, value: uigrid
local XUiGridStageContainer = XClass(XUiNode, 'XUiGridStageContainer')

function XUiGridStageContainer:OnStart()
    self._NodeDict = {}    
end

function XUiGridStageContainer:AddUiGridNode(nodeId, uiGrid)
    self._NodeDict[nodeId] = uiGrid
end

function XUiGridStageContainer:CheckContainsNodeId(nodeId)
    return not XTool.IsTableEmpty(self._NodeDict[nodeId])
end

---@param nodeData XGWNode
function XUiGridStageContainer:UpdateUiGridByNodeData(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver, ...)
    local nodeId = nodeEntity:GetId()
    ---@type XUiGridStage
    local uiGrid = self._NodeDict[nodeId]

    if uiGrid then
        uiGrid:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver, ...)
    end
end

--- 容器包含复数个UI实例，该接口控制仅显示其中的一个
function XUiGridStageContainer:SetShowOnly(nodeId)
    if not XTool.IsTableEmpty(self._NodeDict) then
        for id, grid in pairs(self._NodeDict) do
            -- 暂未继承XUiNode
            if id == nodeId then
                grid.GameObject:SetActiveEx(true)

                if grid.OnShow then
                    grid:OnShow()
                end
                
                self._CurShowGrid = grid
            else
                grid.GameObject:SetActiveEx(false)

                if grid.OnHide then
                    grid:OnHide()
                end
            end
        end
    end
end

--- 暂时没有多个同时显示的需求，若有则外部访问一系列逻辑也需要同步调整
function XUiGridStageContainer:GetCurShowGrid()
    return self._CurShowGrid
end

return XUiGridStageContainer