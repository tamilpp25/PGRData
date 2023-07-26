local type = type
local pairs = pairs

local Default = {
    _Day = 0, --天数
    _MinerCount = 0, --矿工数量
    _MineralCount = 0, --矿石数量
    _TotalMineralCount = 0, --总产出矿石数量
}

local XStrongholdMineRecord = XClass(nil, "XStrongholdMineRecord")

function XStrongholdMineRecord:Ctor(day)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Day = day
end

function XStrongholdMineRecord:UpdateData(minerCount, mineralCount, totalMineralCount)
    self._MinerCount = minerCount or self._MinerCount
    self._MineralCount = mineralCount or self._MineralCount
    self._TotalMineralCount = totalMineralCount or self._TotalMineralCount
end

function XStrongholdMineRecord:GetDay()
    return self._Day
end

function XStrongholdMineRecord:GetMinerCount()
    return self._MinerCount
end

function XStrongholdMineRecord:GetMineralCount()
    return self._MineralCount
end

function XStrongholdMineRecord:GetTotalMineralCount()
    return self._TotalMineralCount
end

return XStrongholdMineRecord