---@class XPlanetMovieManager
local XPlanetMovieManager = XClass(nil, "XPlanet")

local STATUS =
{
    Init = 0, -- Manager初始化完毕
    Close = 1, -- 未播放剧情
    Playing = 2  -- 正在播放剧情   
}

function XPlanetMovieManager:Ctor(rootProxy)
    ---@type XPlanetRunningExplore
    self.RootProxy = rootProxy
    self.MovieId = nil
    self.Status = STATUS.Init
end

function XPlanetMovieManager:CheckIsPlayingMovie()
    return self.Status == STATUS.Playing
end

function XPlanetMovieManager:GetPlayingMovieId()
    return self.MovieId
end

function XPlanetMovieManager:CheckIsPlayingMovie()
    return self.Status == STATUS.Playing
end

function XPlanetMovieManager:Skip()
    if self.Status ~= STATUS.Playing then 
        return
    end

    self:Stop()
end

---@param entities XPlanetRunningExploreEntity[] key = charId
function XPlanetMovieManager:Play(movieId, entities, finishCb)
    if self.Status == STATUS.Playing then
        return
    end

    local changeDialogCb = function (movieInfo, index)
        local curMovieInfo = movieInfo[index]
        if XTool.IsTableEmpty(curMovieInfo) then
            return
        end
        
        local entity = entities[curMovieInfo.PlanetCharacterId]
        if XTool.IsTableEmpty(entity) then
            return
        end
        
        -- 动作
        local actionName = curMovieInfo.Action
        if not string.IsNilOrEmpty(actionName) then
            entity.Animation.ActionOnce = actionName
        end

        -- 气泡
        local bbcId = curMovieInfo.BubbleControllerId
        if XTool.IsNumberValid(bbcId) then
            local bbManager = self.RootProxy.PlanetBubbleManager
            if bbManager then
                bbManager:PlayBubble(bbcId, entity.Id)
            end
        end
    end
    
    local doFinCb = function ()
        self:OnMovieFinish()
        if finishCb then
            finishCb()
        end
    end
    XLuaUiManager.Open("UiPlanetMovie", movieId, changeDialogCb, doFinCb)
    self.MovieId = movieId
    self.Status = STATUS.Playing
end

function XPlanetMovieManager:OnMovieFinish()
    self.Status = STATUS.Close
    self.MovieId = nil
end

function XPlanetMovieManager:Stop()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_REQUEST_STOP_MOVIE)
end

return XPlanetMovieManager