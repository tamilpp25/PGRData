local pairs = pairs
local tableInsert = table.insert

local XMovieActionSetGray = XClass(XMovieActionBase, "XMovieActionSetGray")

function XMovieActionSetGray:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Value = XMath.Clamp(paramToNumber(params[1]), 0, 1)
    self.IndexList = {}
    local maxParamNum = XMovieConfigs.MAX_ACTOR_NUM + 1
    for i = 1, maxParamNum do
        local index = paramToNumber(params[i + 1])
        if index ~= 0 then
            tableInsert(self.IndexList, index)
        end
    end
end

function XMovieActionSetGray:OnRunning()
    local value = self.Value
    local maxActorNum = XMovieConfigs.MAX_ACTOR_NUM
    local indexList = self.IndexList
    local setValue = false

    for _, index in pairs(indexList) do
        if index > 0 and index < maxActorNum then
            local actor = self.UiRoot:GetActor(index)
            actor:SetGrayScale(value)
            setValue = true
        else
            self.UiRoot.MaterialBg:SetGrayScale(value)
            setValue = true
        end
    end

    if not setValue then
        self.UiRoot.MaterialBg:SetGrayScale(value)
        for index = 1, maxActorNum do
            local actor = self.UiRoot:GetActor(index)
            actor:SetGrayScale(value)
        end
    end
end

return XMovieActionSetGray