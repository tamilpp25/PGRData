---@class XFangKuaiEnviroment : XControl 关卡环境
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
---@field _Config XTableFangKuaiStageEnvironment
local XFangKuaiEnviroment = XClass(XControl, "XFangKuaiEnviroment")

local Environment = XEnumConst.FangKuai.Environment

function XFangKuaiEnviroment:OnInit()

end

function XFangKuaiEnviroment:AddAgencyEvent()

end

function XFangKuaiEnviroment:RemoveAgencyEvent()

end

function XFangKuaiEnviroment:OnRelease()

end

function XFangKuaiEnviroment:InitEnviroment(enviromentId)
    if XTool.IsNumberValid(enviromentId) then
        self._Config = self._MainControl:GetEnvironmentConfig(enviromentId)
    else
        self._Config = nil
    end
end

function XFangKuaiEnviroment:ResetParam()

end

function XFangKuaiEnviroment:GetNewLineCount()
    if self._Config and self._Config.Type == Environment.Up then
        local round = self._MainControl:GetClientRound()
        local index = round % #self._Config.Params + 1
        return self._Config.Params[index]
    end
    return 1
end

return XFangKuaiEnviroment