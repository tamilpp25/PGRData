local type = type

--二周年预热-赛跑小游戏-关卡通关数据
local RunGameStageData = XClass(nil, "RunGameStageData")

local Default = {
    _StageId = 0,   --关卡id
    _StarMark = 0,  --关卡星级
}

function RunGameStageData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function RunGameStageData:UpdateData(data)
    self._StageId = data.StageId
    self._StarMark = data.StarMark
end

function RunGameStageData:GetStageId()
    return self._StageId
end

function RunGameStageData:GetStarMark()
    return self._StarMark
end

return RunGameStageData