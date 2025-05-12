---@class XUiStageMemoryProgressPoint : XUiNode
---@field _Control
local XUiStageMemoryProgressPoint = XClass(XUiNode, "XUiStageMemoryProgressPoint")

function XUiStageMemoryProgressPoint:OnStart()
end

---@param data XStageMemoryControlStage
function XUiStageMemoryProgressPoint:Update(data)
    self._Data = data
    self:UpdateSelected()
end

function XUiStageMemoryProgressPoint:UpdateSelected(index)
    local data = self._Data
    if data.IsUnlock then
        self.Lock.gameObject:SetActiveEx(false)
        if data.Index == index then
            self.Normal.gameObject:SetActiveEx(false)
            self.NormalClear.gameObject:SetActiveEx(false)
            self.Select.gameObject:SetActiveEx(true)
            if data.IsPassed then
                self.SelectClear.gameObject:SetActiveEx(true)
            else
                self.SelectClear.gameObject:SetActiveEx(false)
            end
        else
            self.Select.gameObject:SetActiveEx(false)
            self.SelectClear.gameObject:SetActiveEx(false)
            self.Normal.gameObject:SetActiveEx(true)
            if data.IsPassed then
                self.NormalClear.gameObject:SetActiveEx(true)
            else
                self.NormalClear.gameObject:SetActiveEx(false)
            end
        end
    else
        self.Lock.gameObject:SetActiveEx(true)
        self.Normal.gameObject:SetActiveEx(false)
        self.NormalClear.gameObject:SetActiveEx(false)
        self.Select.gameObject:SetActiveEx(false)
        self.SelectClear.gameObject:SetActiveEx(false)
    end
end

return XUiStageMemoryProgressPoint