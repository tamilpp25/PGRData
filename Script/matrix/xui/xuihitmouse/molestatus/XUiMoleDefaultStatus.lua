--地鼠状态：默认
local XUiMoleDefaultStatus = {}

function XUiMoleDefaultStatus.OnStart(mole)
    XUiMoleDefaultStatus.Reset(mole)
    --XLog.Debug("Mole Index : " .. mole.Index .. " Default Start" )
end

function XUiMoleDefaultStatus.Reset(mole)
    mole.HitCount = 0
    mole.BeHit = false
    mole.CanBeHit = false
    mole.isNeedHit = false
    mole.ClearRound = nil
    mole.IsDied = false
    mole.Dying = false
    mole.FeverHit = false
end

function XUiMoleDefaultStatus.OnUpdate(mole)
    if mole.ContainId and mole.ContainId > 0 then
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.SetMole)
    elseif not mole.RoundFinish and mole.RoundStartFlag then
        mole.RoundFinish = true
    elseif mole.ClearRound then
        mole.ClearRound = nil
    end
end

function XUiMoleDefaultStatus.OnExit(mole)
    --XLog.Debug("Mole Index : " .. mole.Index .. " Default End" )
end

return XUiMoleDefaultStatus