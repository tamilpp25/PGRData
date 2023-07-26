local Default = {
    _Id = 0,
    _TeamIds = {}, --探索中的队伍Id
    _Finished = false --是否全部探索完成
}

--末日生存玩法-探索地点
local XDoomsdayPlace = XClass(XDataEntityBase, "XDoomsdayPlace")

function XDoomsdayPlace:Ctor()
    self:Init(Default)
end

function XDoomsdayPlace:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_Finished", data.IsFinish)
end

--是否全部探索完成
function XDoomsdayPlace:IsFinished()
    return self._Finished
end

return XDoomsdayPlace
