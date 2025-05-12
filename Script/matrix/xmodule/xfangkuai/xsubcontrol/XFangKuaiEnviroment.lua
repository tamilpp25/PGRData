---@class XFangKuaiEnviroment : XControl 关卡环境（顶部掉落+多行上升）
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

function XFangKuaiEnviroment:InitEnviroment(stageId)
    local enviromentId = self._MainControl:GetStageConfig(stageId).EnvironmentId
    if XTool.IsNumberValid(enviromentId) then
        self._Config = self._MainControl:GetEnvironmentConfig(enviromentId)
    else
        self._Config = nil
    end
end

function XFangKuaiEnviroment:ResetParam()

end

--region 多行上升

function XFangKuaiEnviroment:GetNewLineCount()
    if self._Config and self._Config.Type == Environment.Up then
        local round = self._MainControl:GetCurRound()
        local index = round % #self._Config.Params + 1
        return self._Config.Params[index]
    end
    return 1
end

--endregion

--region 顶部掉落

function XFangKuaiEnviroment:InitDropBlockEnviroment(stageId)
    -- 如果是继续游戏 则不能初始化cd
    local chapterId = self._MainControl:GetChapterIdByStage(stageId)
    if self._Model:HasBlockDropEnviroment(stageId) and self._MainControl:GetCurRound(chapterId) == 0 then
        local stageData = self._Model.ActivityData:GetStageData(chapterId)
        local config = self:GetNextDropBlockConfig(stageId)
        stageData:SetDropBlockCd(config.ActionCd)
    end
end

function XFangKuaiEnviroment:GetNextDropBlockConfig(stageId)
    local chapterId = self._MainControl:GetChapterIdByStage(stageId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    local times = stageData:GetDropBlockTimes() + 1
    return self._Model:GetBlockDropConfig(stageId, times)
end

function XFangKuaiEnviroment:CreateDropBlockData(stageId)
    local stageData = self._MainControl:GetCurStageData()
    local config = self:GetNextDropBlockConfig(stageId)
    local stageConfig = self._MainControl:GetStageConfig(stageId)
    local blockLen = XMath.RandomByDoubleList(config.BlockLength, config.Weight)
    local blockX = XTool.Random(1, stageConfig.SizeX - blockLen + 1)
    local blockData = self._MainControl:CreateBlock(stageData, blockLen, blockX, stageConfig.SizeY)
    stageData:SetTopPreviewBlock(blockData)
end

--endregion

return XFangKuaiEnviroment