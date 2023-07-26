--地鼠设置完成状态
local XUiMoleSetMoleStatus = {}

function XUiMoleSetMoleStatus.OnStart(mole)
    local moleId = mole.ContainId
    if moleId and moleId > 0 then
        mole.RoundFinish = false
    else
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Default)
        mole.RoundFinish = true
    end
    --XLog.Debug("Mole Index : " .. mole.Index .. " SetMole Start" )
end

function XUiMoleSetMoleStatus.OnUpdate(mole)
    if mole.RoundStartFlag then
        mole.RoundStartFlag = nil
        mole.ShowStartFlag = true
        mole.ShowTimeCount = 0
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Appear)
    end
end

function XUiMoleSetMoleStatus.OnExit(mole)
    --XLog.Debug("Mole Index : " .. mole.Index .. " SetMole End" )
end

return XUiMoleSetMoleStatus