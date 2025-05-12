local XLuckyTenantAnimation = require("XModule/XLuckyTenant/Game/Animation/XLuckyTenantAnimation")
local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")

---@class XLuckyTenantAnimationGroup
local XLuckyTenantAnimationGroup = XClass(nil, "XLuckyTenantAnimationGroup")

function XLuckyTenantAnimationGroup:Ctor()
    -- 同一轨道的动画同时执行
    ---@type XLuckyTenantAnimation[][]
    self._Animations = {}
    self._IsFinish = false
end

function XLuckyTenantAnimationGroup:SetAnimation(animationParams)
    local animation = XLuckyTenantAnimation.New(animationParams)
    local track = animationParams.Type
    self._Animations[track] = self._Animations[track] or {}
    table.insert(self._Animations[track], 1, animation)
end

function XLuckyTenantAnimationGroup:Update(ui)
    local deltaTime = CS.UnityEngine.Time.deltaTime
    local runningAnimationAmount = 0
    for i = 1, XLuckyTenantEnum.Animation.End do
        local track = self._Animations[i]
        if track then
            local isRunning = false
            for i = #track, 1, -1 do
                local animation = track[i]
                if animation then
                    if animation:IsStart() then
                        animation:Update(deltaTime, ui)
                    else
                        animation:OnStart(ui)
                        animation:SetStart(true)
                    end
                    if animation:IsFinish() then
                        table.remove(track, i)
                    end
                    isRunning = true
                    runningAnimationAmount = runningAnimationAmount + 1
                end
            end
            if isRunning then
                break
            else
                self._Animations[i] = nil
            end
        end
    end
    if runningAnimationAmount == 0 then
        self._IsFinish = true
    end
end

function XLuckyTenantAnimationGroup:IsFinish()
    return self._IsFinish
end

return XLuckyTenantAnimationGroup