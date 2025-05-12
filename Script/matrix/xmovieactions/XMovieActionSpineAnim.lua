local XMovieActionSpineAnim = XClass(XMovieActionBase, "XMovieActionSpineAnim")

function XMovieActionSpineAnim:Ctor(actionData)
    self.SpinePath = actionData.Params[1]
end

function XMovieActionSpineAnim:OnInit()
    self.UiRoot.PanelSpine.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.SpinePath))
    if not string.IsNilOrEmpty(self.SpinePath) then
        self.UiRoot.PanelSpine:LoadPrefab(self.SpinePath)
    end
end

return XMovieActionSpineAnim
