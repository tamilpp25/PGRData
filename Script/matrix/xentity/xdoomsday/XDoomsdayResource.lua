local Default = {
    _Id = 0,
    _CfgId = 0,
    _Count = 0,
    _Consume = 0 --每天消耗
}

--末日生存玩法-资源
local XDoomsdayResource = XClass(XDataEntityBase, "XDoomsdayResource")

function XDoomsdayResource:Ctor(id)
    self:Init(Default)
    self._Id = id
    self._CfgId = id
end

function XDoomsdayResource:Reset()
    self:SetProperty("_Count", 0)
end

function XDoomsdayResource:UpdateData(data)
    self:SetProperty("_Count", data.Count)
end

function XDoomsdayResource:AddCount(count)
    self:SetProperty("_Count", self._Count + count)
end

return XDoomsdayResource
