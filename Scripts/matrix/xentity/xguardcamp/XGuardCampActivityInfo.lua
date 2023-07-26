local type = type

local XGuardCampActivityInfo = XClass(nil, "XGuardCampActivityInfo")

local Default = {
    __Id = 0,               --活动id
    __SelectCampId = 0,     --选择阵营
    __CampInfos = {},       --阵营信息
    __IsGetReward = false,  --是否已领奖
}

function XGuardCampActivityInfo:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.__Id = id
end

function XGuardCampActivityInfo:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end
    self.__SelectCampId = data.SelectCampId

    if not XTool.IsTableEmpty(data.CampInfos) then
        for _, v in ipairs(data.CampInfos) do
            self.__CampInfos[v.Id] = v.SupportCount     --阵营id和支援数量
        end
    end

    self:SetIsGetReward(data.IsGetReward)
end

function XGuardCampActivityInfo:GetSelectCampId()
    return self.__SelectCampId
end

function XGuardCampActivityInfo:GetSupportCountByCampId(campId)
    return campId and self.__CampInfos[campId] or 0
end

function XGuardCampActivityInfo:IsGetReward()
    return self.__IsGetReward
end

function XGuardCampActivityInfo:SetIsGetReward(isGetReward)
    self.__IsGetReward = isGetReward
end

return XGuardCampActivityInfo