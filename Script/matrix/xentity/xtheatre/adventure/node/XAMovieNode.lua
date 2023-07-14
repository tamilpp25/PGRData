local XANode = require("XEntity/XTheatre/Adventure/Node/XANode")
-- 直接播放的剧情节点
local XAMovieNode = XClass(XANode, "XAMovieNode")

function XAMovieNode:Ctor()
    self.StoryId = nil
    self.IsPlayed = false
end

function XAMovieNode:InitWithServerData(data)
    XAMovieNode.Super.InitWithServerData(self, data)
    self.StoryId = data.StoryId
end

function XAMovieNode:GetStoryId()
    return self.StoryId
end

function XAMovieNode:GetIsPlayed()
    return self.IsPlayed
end

function XAMovieNode:RequestEnd(callback)
    self.IsPlayed = true
    self:Trigger(function()
        XNetwork.CallWithAutoHandleErrorCode("TheatreEndNodeRequest", {}, function(res)
            if callback then callback() end
        end)    
    end) 
end

return XAMovieNode