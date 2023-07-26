---------------------------------------------------------------------
--地鼠状态：出现
local XUiMoleAppearStatus = {}

function XUiMoleAppearStatus.OnStart(mole)
    mole.FinishAppearAnim = nil
    if mole.ContainId > 0 then
        mole:Appear(function()
                mole.FinishAppearAnim = true
            end)
    else
        mole.FinishAppearAnim = true
    end
    mole.ForceExitTime = 0
    mole.ForceExit = true
end

function XUiMoleAppearStatus.OnUpdate(mole)
    if mole.FinishAppearAnim then
        mole.FinishAppearAnim = nil
        mole:ChangeStatus(XHitMouseConfigs.MoleStatus.Wait)
    elseif mole.ForceExit then
        mole.ForceExitTime = mole.ForceExitTime + CS.UnityEngine.Time.deltaTime
        if mole.ForceExitTime >= 1 then
            --XLog.Error("Mole" .. mole.Index .. " Force Appear.")
            mole.ForceExit = false
            mole.FinishAppearAnim = true
        end
    end
end

function XUiMoleAppearStatus.OnExit(mole)
    mole.ForceExit = false
    mole.ForceExitTime = 0
end

return XUiMoleAppearStatus