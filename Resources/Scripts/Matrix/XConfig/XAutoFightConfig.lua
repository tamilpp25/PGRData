XAutoFightConfig = XAutoFightConfig or {}


local AutoFightCfgs = {}
local TABLE_AUTO_FIGHT = "Share/Fuben/AutoFight.tab"

function XAutoFightConfig.Init()
    AutoFightCfgs = XTableManager.ReadByIntKey(TABLE_AUTO_FIGHT, XTable.XTableAutoFight, "Id")
end

function XAutoFightConfig.GetCfg(autoFightId)
    return AutoFightCfgs[autoFightId]
end