local XMovieActionTimelinePlay = XClass(XMovieActionBase, "XMovieActionTimelinePlay")
local CAMERA_TRACK = "Camera"

function XMovieActionTimelinePlay:Ctor(actionData)
    local params = actionData.Params
    self.TimelineName = params[1]
    self.TrackDic = {}
    for i = 2, #params do
        local kv = string.Split(params[i], "|")
        self.TrackDic[kv[1]] = kv[2]
    end
end

function XMovieActionTimelinePlay:OnRunning()
    ---@type UnityEngine.Playables.PlayableDirector
    local timelineHelper = self.UiRoot:GetTimeline(self.TimelineName)
    if not timelineHelper then
        return
    end

    local roleList = {}
    timelineHelper:SetBindingTarget(CAMERA_TRACK, self.UiRoot.CineMachineBrain)
    for trackName, roleId in pairs(self.TrackDic) do
        ---@type Movie.XMovie3DRole
        local role = self.UiRoot:GetModelActor(roleId)
        if not role then
            return
        end

        table.insert(roleList, role) 

        timelineHelper:SetBindingTarget(trackName, role.gameObject)
    end

    timelineHelper:Play(function()
        for _, role in pairs(roleList) do
            --动画播放完毕后修正transform最终位置
            role:FixFinalPosition()
        end
    end)
end

return XMovieActionTimelinePlay