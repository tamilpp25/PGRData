local XMovieActionAutoSkip = XClass(XMovieActionBase, "XMovieActionAutoSkip")

function XMovieActionAutoSkip:Ctor(actionData)
    local params = actionData.Params
    self.ManSkipActionId = XMVCA.XMovie:ParamToNumber(params[1]) -- 男指挥官跳转ActionId
    self.WomanSkipActionId = XMVCA.XMovie:ParamToNumber(params[2]) -- 女指挥官跳转ActionId
    self.SkipActionId = XMVCA.XMovie:ParamToNumber(params[3]) -- 无论性别直接跳转ActionId
end

function XMovieActionAutoSkip:OnInit()
    if self.SkipActionId ~= 0 then
        self.SelectedActionId = self.SkipActionId
        return
    end
    
    -- 根据性别设置跳转Id
    local gender = XPlayer.GetShowGender()
    if gender == XEnumConst.PLAYER.GENDER_TYPE.MAN then
        self.SelectedActionId = self.ManSkipActionId
    else
        self.SelectedActionId = self.WomanSkipActionId
    end
end

function XMovieActionAutoSkip:GetSelectedActionId()
    return self.SelectedActionId or 0
end


return XMovieActionAutoSkip