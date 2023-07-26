---@class XUiGridMainLineSkipStage
local XUiGridMainLineSkipStage = XClass(nil, "XUiGridMainLineSkipStage")

local MAX_STAGE_COUNT = CS.XGame.ClientConfig:GetInt("MainLineStageMaxCount")

function XUiGridMainLineSkipStage:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSkipStageList = {}
end

function XUiGridMainLineSkipStage:SetSkipStage(chapter)
    self.Chapter = chapter
    local skipIds = self.Chapter.SkipId
    local skipConditions = self.Chapter.SkipCondition
    local skipIcons = self.Chapter.SkipIcon
    if XTool.IsTableEmpty(skipIds) then
        return
    end
    local targetCanvas = self.RootUi.Transform:GetComponent("Canvas")
    for i = 1, #skipIds do
        local isShow = self:CheckSkipStage(skipConditions[i])
        if isShow then
            local grid = self.GridSkipStageList[i]
            if not grid then
                local uiName = "PanelStageActiveSkip"

                local parent = XUiHelper.TryGetComponent(self.Transform, string.format("Skip%d", i))
                local prefabName = XUiHelper.GetClientConfig(uiName, XUiHelper.ClientConfigType.String)
                local prefab = parent:LoadPrefab(prefabName)
                
                local canvas = parent:GetComponent("Canvas")
                if not XTool.UObjIsNil(canvas) then
                    canvas.sortingOrder = canvas.sortingOrder + targetCanvas.sortingOrder
                end
                
                grid = {}
                XTool.InitUiObjectByUi(grid, prefab)
                grid.GameObject:SetActiveEx(true)
                grid.Parent = parent
                self.GridSkipStageList[i] = grid
            end
            grid.BtnSkip:SetRawImage(skipIcons[i])
            grid.BtnSkip.CallBack = function()
                XFunctionManager.SkipInterface(skipIds[i])
            end
            grid.Parent.gameObject:SetActive(true)
        end
    end

    for i = #self.GridSkipStageList + 1, MAX_STAGE_COUNT do
        local parent = XUiHelper.TryGetComponent(self.Transform, string.format("Skip%d", i))
        if parent then
            parent.gameObject:SetActive(false)
        end
    end
end

function XUiGridMainLineSkipStage:CheckSkipStage(conditionId)
    local isShow = true
    if XTool.IsNumberValid(conditionId) then
        isShow = XConditionManager.CheckCondition(conditionId)
    end
    return isShow
end

return XUiGridMainLineSkipStage