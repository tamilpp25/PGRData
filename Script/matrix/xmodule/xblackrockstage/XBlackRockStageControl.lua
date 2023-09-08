---@class XBlackRockStageControl : XControl
---@field private _Model XBlackRockStageModel
local XBlackRockStageControl = XClass(XControl, "XBlackRockStageControl")

function XBlackRockStageControl:OnInit()
    --初始化内部变量
end

function XBlackRockStageControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBlackRockStageControl:RemoveAgencyEvent()
end

function XBlackRockStageControl:OnRelease()
end

function XBlackRockStageControl:GetUiData()
    return self._Model:GetUiData()
end

function XBlackRockStageControl:UpdateUiData()
    self._Model:UpdateUiData()
end

function XBlackRockStageControl:SetSkipMovie(value)
    self._Model:SetSkipMovie(value)
end

return XBlackRockStageControl