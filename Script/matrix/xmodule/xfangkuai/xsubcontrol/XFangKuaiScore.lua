---@class XFangKuaiScore : XControl
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
local XFangKuaiScore = XClass(XControl, "XFangKuaiScore")

function XFangKuaiScore:OnInit()

end

function XFangKuaiScore:AddAgencyEvent()

end

function XFangKuaiScore:RemoveAgencyEvent()

end

function XFangKuaiScore:OnRelease()

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
    self._MainControl:GetCurStageData():AddPoint(score, self:GetCombo(), self._MainControl:GetCurStageData():GetCombo())
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

function XFangKuaiScore:GetCombo()
    local combo = self._MainControl:GetCurStageData():GetCombo()
    return self._MainControl:GetComboConfigRadio(combo)
end

return XFangKuaiScore