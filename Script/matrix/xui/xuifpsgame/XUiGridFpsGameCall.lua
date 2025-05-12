---@class XUiGridFpsGameCall : XUiNode 通讯节点
---@field Parent XUiFpsGameChapter
---@field _Control XFpsGameControl
local XUiGridFpsGameCall = XClass(XUiNode, "XUiGridFpsGameCall")

function XUiGridFpsGameCall:OnStart(stageId, commuId)
    self._StageId = stageId
    self._Call = XCommunicationConfig.GetFunctionInitiativeCommunicationConfigById(commuId)
    self.GridCall.CallBack = handler(self, self.OnClick)
end

function XUiGridFpsGameCall:RefreshData()
    if self._Control:IsStagePass(self._StageId) then
        self:Open()
    else
        self:Close()
    end
end

function XUiGridFpsGameCall:OnClick()
    XLuaUiManager.Open("UiFunctionalOpen", self._Call, false, false)
    XSaveTool.SaveData(self._Control:GetCallRedPointKey(self._StageId), true)
    self:RefreshRedPoint()
end

function XUiGridFpsGameCall:BindNode(node3D)
    self._Node3D = node3D
end

function XUiGridFpsGameCall:RefreshPosition()
    if not self._Node3D then
        return
    end
    if self:IsNodeShow() then
        self.Parent:SetViewPosToTransformLocalPosition(self.Transform, self._Node3D)
    end
end

function XUiGridFpsGameCall:RefreshRedPoint()
    local isEnter = XSaveTool.GetData(self._Control:GetCallRedPointKey(self._StageId))
    self.GridCall:ShowReddot(not isEnter)
end

return XUiGridFpsGameCall