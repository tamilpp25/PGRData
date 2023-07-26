local XMovieActionRoleMask = XClass(XMovieActionBase,"XMovieActionRoleMask")

function XMovieActionRoleMask:Ctor(actionData)
    self.IsEnable = XDataCenter.MovieManager.ParamToNumber(actionData.Params[1]) == 1
end

function XMovieActionRoleMask:OnRunning()
    if self.IsEnable then
        self.UiRoot:PlayAnimation("UiMaskEnable",nil,function() 
            self.UiRoot.UiMask02.gameObject:SetActiveEx(true)
        end)
    else
        self.UiRoot:PlayAnimation("UiMaskDisable",function()
            self.UiRoot.UiMask02.gameObject:SetActiveEx(false )
        end)
    end
end

return XMovieActionRoleMask