local XGoldenMinerBaseObj = require("XEntity/XGoldenMiner/Object/XGoldenMinerBaseObj")

--黄金矿工红包箱
local XGoldenMinerRedEnvelope = XClass(XGoldenMinerBaseObj, "XGoldenMinerRedEnvelope")

function XGoldenMinerRedEnvelope:Ctor()
    self.RedEnvelopeRandPoolId = XGoldenMinerConfigs.GetRedEnvelopeRandId()
end

function XGoldenMinerRedEnvelope:GetScore()
    return XGoldenMinerConfigs.GetRedEnvelopeScore(self.RedEnvelopeRandPoolId) or 0
end

function XGoldenMinerRedEnvelope:GetItemId()
    return XGoldenMinerConfigs.GetRedEnvelopeItemId(self.RedEnvelopeRandPoolId)
end

return XGoldenMinerRedEnvelope