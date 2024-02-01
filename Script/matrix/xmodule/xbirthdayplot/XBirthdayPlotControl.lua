---@class XBirthdayPlotControl : XControl
---@field private _Model XBirthdayPlotModel
local XBirthdayPlotControl = XClass(XControl, "XBirthdayPlotControl")
function XBirthdayPlotControl:OnInit()
    
    self._ShowSingleStoryCb = nil
    self._HideSingleStoryCb = nil
end

function XBirthdayPlotControl:AddAgencyEvent()
end

function XBirthdayPlotControl:RemoveAgencyEvent()

end

function XBirthdayPlotControl:OnRelease()
    self._ShowSingleStoryCb = nil
    self._HideSingleStoryCb = nil
end

function XBirthdayPlotControl:GetSingleStoryList()
    return self._Model:GetSingleStoryList()
end

function XBirthdayPlotControl:GetSingleStory(storyId)
    return self._Model:GetSingleStory(storyId)
end

function XBirthdayPlotControl:IsShowInView(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.IsShow == 1 or false
end

function XBirthdayPlotControl:IsInvited(storyId)
    return self._Model:IsViewSingleStory(storyId)
end

function XBirthdayPlotControl:GetFavorAbilityLevel(storyId)
    local level = self._Model:GetMaxFavorLevel(storyId)
    if XTool.IsNumberValid(level) then
        return level
    end
    level = 0
    local template = self:GetSingleStory(storyId)
    local characterIds = template.CharacterIds
    for _, characterId in ipairs(characterIds) do
        level = math.max(level, XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId))
    end
    
    self._Model:SetMaxFavorLevel(storyId, level)
    
    return level
end

function XBirthdayPlotControl:GetHalfBodyImage(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.HalfBodyImg or ""
end

function XBirthdayPlotControl:GetFullBodyImage(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.FullBodyImg or ""
end

function XBirthdayPlotControl:GetGender(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.Gender or ""
end

function XBirthdayPlotControl:GetStoryRoleName(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.Name or ""
end

function XBirthdayPlotControl:GetStoryText(storyId)
    local template = self:GetSingleStory(storyId)
    local text = template and template.Text or ""
    return XUiHelper.ReplaceWithPlayerName(text, XMovieConfigs.PLAYER_NAME_REPLACEMENT)
end

function XBirthdayPlotControl:GetStoryMovieId(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.MovieId or ""
end

function XBirthdayPlotControl:GetStoryIsVoiceover(storyId)
    local template = self:GetSingleStory(storyId)
    return template and template.IsVoiceover == 1 or false
end

function XBirthdayPlotControl:CheckSingleStoryUnlock(singleStoryId)
    local birthday = self._Model:GetBirthday()
    local map = birthday.SingleStoryId
    if XTool.IsTableEmpty(map) then
        return false
    end
    return map[singleStoryId] ~= nil
end

function XBirthdayPlotControl:DoUnlockStory(singleStoryId)
    self._Model:DoViewSingleStory(singleStoryId)
end

function XBirthdayPlotControl:GetFavorLevelIcon(level)
    local template = self._Model:GetFavorLevelConfig(level)
    return template and template.Icon or ""
end

function XBirthdayPlotControl:ShowSingleStory(storyId)
    if not self._ShowSingleStoryCb then
        return
    end
    
    self._ShowSingleStoryCb(storyId)
end

function XBirthdayPlotControl:SetShowSingleStoryCb(cb)
    self._ShowSingleStoryCb = cb
end

function XBirthdayPlotControl:HideSingleStory()
    if not self._HideSingleStoryCb then
        return
    end

    self._HideSingleStoryCb()
end

function XBirthdayPlotControl:SetHideSingleStoryCb(cb)
    self._HideSingleStoryCb = cb
end

function XBirthdayPlotControl:ViewSingleStoryMovie(storyId, cb, yieldCb, hideSkipBtn, isRelease)
    local movieId = self:GetStoryMovieId(storyId)
    if string.IsNilOrEmpty(movieId) then
        return
    end
    
    --已经邀请过
    if self:IsInvited(storyId) then
        XDataCenter.MovieManager.PlayMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease)
        return
    end
    local req = {
        StoryId = storyId
    }
    XNetwork.Call("ViewBirthdaySingleStoryRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:DoViewSingleStory(storyId)
        XDataCenter.MovieManager.PlayMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease)
    end)
end

return XBirthdayPlotControl