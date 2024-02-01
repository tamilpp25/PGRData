local XRedPointKotodamaNewUnLockStage = {}

function XRedPointKotodamaNewUnLockStage.Check(stageId)

    if XTool.IsNumberValid(stageId) then
        if XMVCA.XKotodamaActivity:CheckStageIsNew(stageId) and XMVCA.XKotodamaActivity:CheckStageIsUnLockById(stageId) then
            return true
        end
    else
        local allStageCfgs=XMVCA.XKotodamaActivity:GetAllKotodamaStageCfg()
        for i, v in pairs(allStageCfgs) do
            if XMVCA.XKotodamaActivity:CheckStageIsNew(v.Id) and XMVCA.XKotodamaActivity:CheckStageIsUnLockById(v.Id) then
                return true
            end
        end
    end
    return false
end

return XRedPointKotodamaNewUnLockStage