---@class XMovieActionTextAppear
---@field UiRoot XUiMovie
local XMovieActionTextAppear = XClass(XMovieActionBase, "XMovieActionTextAppear")

function XMovieActionTextAppear:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    
    self.TextId = params[1]
    self.TextContent = params[2]
    self.PosX = paramToNumber(params[3])
    self.PosY = paramToNumber(params[4])
    self.Rotation = paramToNumber(params[5])
    self.IsPlayTypeWriter = paramToNumber(params[6]) == 1 -- 是否播放打字机
    self.CanJumpTypeWriter = paramToNumber(params[7]) == 1
    self.TypeWriterTime = paramToNumber(params[8])
    self.Layer = params[9] and paramToNumber(params[9]) or 1  -- 1:背景之上，演员之下 2：演员之上 3：最上层
    
    -- 参数10决定对齐方式
    if params[10] == "1" then
        self.Alignment = CS.UnityEngine.TextAnchor.MiddleLeft
    elseif params[10] == "2" then
        self.Alignment = CS.UnityEngine.TextAnchor.MiddleRight
    else
        self.Alignment = CS.UnityEngine.TextAnchor.MiddleCenter
    end
    
    self.IsAnim = paramToNumber(params[11]) == 1
end

function XMovieActionTextAppear:OnInit()
    self.IsTyping = false
    local content = XMVCA.XMovie:ExtractGenderContent(self.TextContent)
    local text = self.UiRoot:AppearText(self.Layer, self.TextId, content, self.PosX, self.PosY, self.Rotation, self.IsAnim)
    if self.IsPlayTypeWriter then
        self.IsTyping = true
        self.TypeWriter = text.transform:GetComponent("TextTypewriter")
        self.TypeWriter.Duration = self.TypeWriterTime
        self.TypeWriter.CompletedHandle = function() self:OnTypeWriterComplete() end
        self.TypeWriter:Play()
    end
    self.UiRoot:SetBtnNextCallback(function() self:OnClickBtnNext() end)
    text.alignment = self.Alignment
end

function XMovieActionTextAppear:OnDestroy()
    self.UiRoot:RemoveBtnNextCallback()
end

function XMovieActionTextAppear:OnClickBtnNext()
    if self.IsTyping then
        self.TypeWriter:Stop()
        self:OnTypeWriterComplete()
    else
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionTextAppear:OnTypeWriterComplete()
    self.IsTyping = false
end

return XMovieActionTextAppear