local XUiReformListEnvironmentGrid = require("XUi/XUiReform2nd/Reform/Environment/XUiReformListEnvironmentGrid")

---@field _Control XReformControl
---@class XUiReformListEnvironment:XUiNode
local XUiReformListEnvironment = XClass(XUiNode, "XUiReformListEnvironment")

function XUiReformListEnvironment:OnStart()
    ---@type XUiReformListEnvironmentGrid[]
    self._GridList = {}
    self._OnClickGrid = function(environmentId)
        self:OnClickGrid(environmentId)
    end
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClickSure)
end

function XUiReformListEnvironment:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT, self.Update, self)
end

function XUiReformListEnvironment:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT, self.Update, self)
end

function XUiReformListEnvironment:Update()
    local viewModel = self._Control:GetViewModelList()
    viewModel:UpdateEnvironment()
    local uiData = viewModel:GetUiDataEnvironment()
    self:UpdateUiList(XUiReformListEnvironmentGrid, self.GridEnvironment, self._GridList, uiData.List, self._OnClickGrid)
    for i = 1, #self._GridList do
        local grid = self._GridList[i]
        grid:RegisterClick(self._OnClickGrid)
    end
end

function XUiReformListEnvironment:OnClickGrid(environmentId)
    local viewModel = self._Control:GetViewModelList()
    viewModel:SetSelectedEnvironment(environmentId)
end

function XUiReformListEnvironment:OnClickSure()
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_CLOSE_DETAIL)
end

function XUiReformListEnvironment:UpdateUiList(class, uiObject, gridArray, dataArray, OnClick)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            if grid.RegisterClick then
                grid:RegisterClick(OnClick)
            end
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

return XUiReformListEnvironment
