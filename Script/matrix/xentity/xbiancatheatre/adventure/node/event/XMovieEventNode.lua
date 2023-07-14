local XAEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAEventNode")
local XMovieEventNode = XClass(XAEventNode, "XMovieEventNode")

function XMovieEventNode:RequestTriggerNode(callback)
    XMovieEventNode.Super.RequestTriggerNode(self, function(newEventNode)
        if newEventNode == nil then -- 剧情是最后一个节点，直接关掉界面
            XLuaUiManager.Remove("UiBiancaTheatreOutpost")
        end
        XDataCenter.MovieManager.PlayMovie(self.EventConfig.StoryId, callback)
    end)
end

function XMovieEventNode:GetIsTriggerWithDirect()
    return true
end

return XMovieEventNode