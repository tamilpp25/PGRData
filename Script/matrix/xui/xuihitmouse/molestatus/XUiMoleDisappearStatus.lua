---@class XUiMoleDisappearStatus
local XUiMoleDisappearStatus = {}

function XUiMoleDisappearStatus.OnStart(mole)
    mole.FinishDisappearAnim = nil
    mole.ShowStartFlag = false
    mole.ShowTimeEnd = false
    mole.FeverHit = false
    mole:Disappear(function()
            mole.FinishDisappearAnim = true
        end)
    mole.ForceExitTime = 0
    mole.ForceExit = true
    --XLog.Debug("Mole Index : " .. mole.Index .. " Disappear Start" )
end

function XUiMoleDisappearStatus.OnUpdate(mole)
    if mole.FinishDisappearAnim then
        mole.FinishDisappearAnim = nil
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Default)
    elseif mole.ForceExit then
        mole.ForceExitTime = mole.ForceExitTime + CS.UnityEngine.Time.deltaTime
        if mole.ForceExitTime >= 1.5 then
            --XLog.Error("Mole" .. mole.Index .. " Force Disappear.")
            mole.ForceExit = false
            mole.FinishDisappearAnim = true
        end
    end
end

function XUiMoleDisappearStatus.OnExit(mole)
    mole.ContainId = -1
    mole.RoundFinish = true
    mole.ForceExit = false
    mole.ForceExitTime = 0
    if mole.OnDisappearFinishCb then
        local cb = mole.OnDisappearFinishCb
        mole.OnDisappearFinishCb = nil
        cb()
    end
    --XLog.Debug("Mole Index : " .. mole.Index .. " Disappear End" )
end

return XUiMoleDisappearStatus