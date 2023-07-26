local XMovieActionShowInsertPanel = XClass(XMovieActionBase,"XMovieActionShowInsertPanel")
local vector = CS.UnityEngine.Vector3

function XMovieActionShowInsertPanel:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.BgPath = params[1]
    self.Direction =  paramToNumber(params[2])
end

function XMovieActionShowInsertPanel:OnRunning()

    self.UiRoot:SetInsertPanelBg(self.BgPath,self.Direction)
    self.UiRoot:PlayInsertPanelEnableAnimation(self.Direction)
end

function XMovieActionShowInsertPanel:OnUndo()
    self.UiRoot:PlayInsertPanelDisableAnimation(self.Direction)
end

return XMovieActionShowInsertPanel