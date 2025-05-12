-- 价格波动面板
---@class XUiPanelRogueSimFluctuate : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimFluctuate = XClass(XUiNode, "XUiPanelRogueSimFluctuate")

function XUiPanelRogueSimFluctuate:OnStart()
    self.TxtFluctuationsUp.gameObject:SetActiveEx(false)
    self.TxtFluctuationsNormal.gameObject:SetActiveEx(false)
    self.TxtFluctuationsDown.gameObject:SetActiveEx(false)
end

---@param id number 货物Id
function XUiPanelRogueSimFluctuate:Refresh(id)
    self.Id = id
    -- 货物价格波动值（万分比）
    local priceRate = self._Control.BuffSubControl:GetPriceTotalRatio(id)
    -- 价格波动百分比
    local percentage = priceRate / XEnumConst.RogueSim.Percentage
    -- 保留一位小数
    percentage = self._Control.ResourceSubControl:ConvertNumberToInteger(percentage, 1)
    self.TxtFluctuationsUp.gameObject:SetActiveEx(percentage > 0)
    self.TxtFluctuationsNormal.gameObject:SetActiveEx(percentage == 0)
    self.TxtFluctuationsDown.gameObject:SetActiveEx(percentage < 0)
    local text = self:AddPrefixAndSuffix(percentage, percentage > 0 and "+" or "")
    if percentage > 0 then
        self.TxtFluctuationsUp.text = text
    elseif percentage == 0 then
        self.TxtFluctuationsNormal.text = text
    else
        self.TxtFluctuationsDown.text = text
    end
end

-- 添加前后缀
function XUiPanelRogueSimFluctuate:AddPrefixAndSuffix(value, prefix, suffix)
    return string.format("%s%s%s", prefix or "", value, suffix or "%")
end

return XUiPanelRogueSimFluctuate
