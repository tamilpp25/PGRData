---@class XPacManControl : XControl
---@field private _Model XPacManModel
local XPacManControl = XClass(XControl, "XPacManControl")
function XPacManControl:OnInit()
    --初始化内部变量
end

function XPacManControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPacManControl:RemoveAgencyEvent()

end

function XPacManControl:OnRelease()
end

function XPacManControl:GetStagePrefab(stageId)
    local config = self._Model:GetStage(stageId)
    if config then
        return config.Prefab
    end
    return false
end

function XPacManControl:GetStage(stageId)
    local config = self._Model:GetStage(stageId)
    if config then
        return config
    end
    return false
end

function XPacManControl:GetStory(storyId)
    local story = self._Model:GetStory(storyId)
    return story
end

return XPacManControl