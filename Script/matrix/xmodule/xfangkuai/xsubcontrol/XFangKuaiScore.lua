---@class XFangKuaiScore : XControl
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
local XFangKuaiScore = XClass(XControl, "XFangKuaiScore")

function XFangKuaiScore:OnInit()
    self:InitData()
end

function XFangKuaiScore:AddAgencyEvent()

end

function XFangKuaiScore:RemoveAgencyEvent()

end

function XFangKuaiScore:OnRelease()

end

function XFangKuaiScore:InitData()
    self._Score = 0
    self:ResetCombo()
end

function XFangKuaiScore:GetScore()
    return self._Score
end

function XFangKuaiScore:ResetScore(chapterId)
    self._Score = self._MainControl:GetCurRoundScore(chapterId)
end

---@param blockData XFangKuaiBlock
function XFangKuaiScore:AddScore(blockData, waneLen)
    local score
    local point = blockData:GetScore()
    if blockData:IsBoss() then
        score = point
    else
        score = XTool.IsNumberValid(waneLen) and self:GetWaneItemScore(blockData, waneLen) or point
    end
    self._Score = self._Score + math.floor(score * self:GetCombo() / 10000) -- 提前÷1000再相乘的话会有精度的问题 230会变成229！
end

-- 使用长度缩减道具：如果长度4是500分 长度3是360分 则消除一个单位后 得分：500-360=140分
---@param blockData XFangKuaiBlock
function XFangKuaiScore:GetWaneItemScore(blockData, waneLen)
    local type = blockData:GetBlockType()
    local len = blockData:GetLen()
    local old = self._MainControl:GetBlockPoint(type, len)
    if len <= waneLen then
        return old
    end
    local new = self._MainControl:GetBlockPoint(type, len - waneLen)
    return old - new
end

function XFangKuaiScore:AddCombo(num)
    num = num or 1
    self._Combo = self._Combo + num
end

function XFangKuaiScore:GetComboNum()
    return self._Combo
end

function XFangKuaiScore:ResetCombo()
    self._Combo = 1
end

function XFangKuaiScore:GetCombo()
    return self._MainControl:GetComboConfigRadio(self._Combo)
end

return XFangKuaiScore