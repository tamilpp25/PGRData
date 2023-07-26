--地鼠状态：待机
local XUiMoleWaitStatus = {}

function XUiMoleWaitStatus.OnStart(mole)
    mole:Wait()
    --XLog.Debug("Mole Index : " .. mole.Index .. " Wait Start" )
end

function XUiMoleWaitStatus.OnUpdate(mole)
    if mole.ShowTimeEnd then
        mole.ShowTimeEnd = false
        mole.NotHit = true
        --XLog.Error(mole.Index .. "号坑位".. mole.Name .."漏击！")
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Disappear)
    elseif mole.FeverHit then
        if mole.WaitFever then return end
        mole.WaitFever = true
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Hit)
    elseif mole.ClearRound then
        mole.ClearRound = false
        if mole.isNeedHit then
            --XLog.Error(mole.Index .. "号坑位".. mole.Name .."漏击！")
        end
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Disappear)
    elseif mole.BeHit then
        mole.BeHit = false
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Hit)
    end
end

function XUiMoleWaitStatus.OnExit(mole)
    mole.WaitFever = false
    --XLog.Debug("Mole Index : " .. mole.Index .. " Wait End" )
end

return XUiMoleWaitStatus