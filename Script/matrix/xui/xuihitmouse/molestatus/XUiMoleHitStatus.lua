--地鼠状态：被击中
local XUiMoleHitStatus = {}

function XUiMoleHitStatus.OnStart(mole)
    mole.FinishHitAnim = nil
    mole:Hit(function()
            mole.FinishHitAnim = true
        end)
    --XLog.Debug("Mole Index : " .. mole.Index .. " Hit Start" )
end

function XUiMoleHitStatus.OnUpdate(mole)
    if mole.IsDied then
        if mole.FinishHitAnim or mole.ShowTimeEnd then
            mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Disappear)
        end
    elseif mole:CheckHitCount() and not mole.IsDied then
        mole:Dead()
        --XLog.Error(mole.Index .. "号坑位" .. mole.Name .. "击破")
    elseif mole.ShowTimeEnd then
        mole.ShowTimeEnd = false
        mole.NotHit = true
        --XLog.Error(mole.Index .. "号坑位".. mole.Name .."漏击！")
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Disappear)
    elseif mole.BeHit then
        mole.BeHit = false
        mole:Hit(function()
                mole.FinishHitAnim = true
            end)
    elseif mole.FinishHitAnim then
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Wait)
    end
end

function XUiMoleHitStatus.OnExit(mole)
    mole.BeHit = false
    --XLog.Debug("Mole Index : " .. mole.Index .. " Hit End" )
end

return XUiMoleHitStatus