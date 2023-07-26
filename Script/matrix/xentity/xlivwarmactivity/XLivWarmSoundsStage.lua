
local type = type
local pairs = pairs

--[[    
public class XLivWarmSoundsStage
{
    /// <summary>
    /// 关卡id
    /// </summary>
    public bool StageId;
    
    /// <summary>
    /// 胜利次数
    /// </summary>
    public int IsWin;

    /// <summary>
    /// 音频顺序
    /// </summary>
    public List<int> Answer = new List<int>();
}
]]
local Default = {
    _StageId = 0, --关卡Id
    _IsWin = false, --解密成功
    _Answer = {}, --解密顺序
    _TipCount = 0, --提示数量
}

local XLivWarmSoundsStage = XClass(nil, "XLivWarmSoundsStage")

function XLivWarmSoundsStage:Ctor(id)
    self:Init(id)
end

function XLivWarmSoundsStage:Init(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._StageId = id
    self:InitAnswer()
end

function XLivWarmSoundsStage:InitAnswer()
    if XTool.IsNumberValid(self._StageId) then
        local InitialSoundId = XLivWarmSoundsActivityConfig.GetStageInitialSoundId(self._StageId)
        for i, v in ipairs(InitialSoundId) do
            table.insert(self._Answer,v)
        end
    end
end

function XLivWarmSoundsStage:UpdateData(info)
    self._StageId = info.StageId or self._StageId
    self._IsWin = info.IsWin or self._IsWin
    self._Answer = not XTool.IsTableEmpty(info.Answer) and info.Answer or self._Answer
    self._TipCount = info.TipCount or self._TipCount
end

function XLivWarmSoundsStage:SetAnswer(answer)
    self._Answer = not XTool.IsTableEmpty(answer) and answer or self._Answer
end

function XLivWarmSoundsStage:SetTipCount(tipCount)
    self._TipCount = tipCount
end

function XLivWarmSoundsStage:SetIsWin(isWin)
    self._IsWin = isWin
end

function XLivWarmSoundsStage:GetStageId()
    return self._StageId
end

function XLivWarmSoundsStage:GetAnswer()
    return self._Answer
end

function XLivWarmSoundsStage:IsFinished()
    return self._IsWin
end

function XLivWarmSoundsStage:GetTipCount()
    return self._TipCount
end


return XLivWarmSoundsStage