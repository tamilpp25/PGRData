---@class XGoldenMinerComponentProjector:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
---@field ShowEffect UnityEngine.Transform
---@field ProjectorLoop UnityEngine.Transform
---@field ProjectorDisable UnityEngine.Transform
local XGoldenMinerComponentProjector = XClass(XEntity, "XGoldenMinerComponentProjector")

--region Override
function XGoldenMinerComponentProjector:OnInit()
    -- Static Value
    ---@type UnityEngine.Transform
    self.Transform = nil
    -- Dynamic Value
    self._IsDisappear = false
end

function XGoldenMinerComponentProjector:OnRelease()
    self.Transform = nil
    self.ShowEffect = nil
end
--endregion

--region Setter
function XGoldenMinerComponentProjector:SetTransform(value)
    self.Transform = value
    XTool.InitUiObject(self)
    self.ProjectorLoop = XUiHelper.TryGetComponent(self.Transform, "Animation/ProjectorLoop")
    self.ProjectorDisable = XUiHelper.TryGetComponent(self.Transform, "Animation/ProjectorDisable")
    if self.ProjectorLoop then
        self.ProjectorLoop:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
end

function XGoldenMinerComponentProjector:SetIsDisappear(value)
    self._IsDisappear = value
end

function XGoldenMinerComponentProjector:SetTransAngle(value)
    local localEulerAngles = self.Transform.localEulerAngles
    local y = localEulerAngles.y
    if value > 90 then
        value = 180 - value
        y = 180 - y
    end
    self.Transform.localEulerAngles = Vector3(localEulerAngles.x, y, value)
end
--endregion

--region Check
function XGoldenMinerComponentProjector:IsDisappear()
    return self._IsDisappear
end
--endregion

--region Control
function XGoldenMinerComponentProjector:CloseShowEffect()
    if self.ProjectorDisable then
        self.ProjectorDisable:PlayTimelineAnimation(function()
            self:_CloseShowEffect()
        end)
    else
        self:_CloseShowEffect()
    end
end

function XGoldenMinerComponentProjector:_CloseShowEffect()
    if self.ShowEffect then
        self.ShowEffect.gameObject:SetActiveEx(false)
    end
end
--endregion

return XGoldenMinerComponentProjector