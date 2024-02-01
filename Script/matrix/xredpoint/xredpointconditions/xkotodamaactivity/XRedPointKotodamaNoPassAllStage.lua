local XRedPointKotodamaNoPassAllStage = {}

function XRedPointKotodamaNoPassAllStage.Check()
    local allStageCfgs=XMVCA.XKotodamaActivity:GetAllKotodamaStageCfg()
    for i, v in pairs(allStageCfgs) do
        if not XMVCA.XKotodamaActivity:CheckStageIsPassById(v.Id) then
            return true
        end
    end
    return false
end

return XRedPointKotodamaNoPassAllStage