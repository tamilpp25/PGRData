---@class XUiGridScoreTowerStrengthen : XUiNode
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerStrengthen = XClass(XUiNode, "XUiGridScoreTowerStrengthen")

function XUiGridScoreTowerStrengthen:OnStart(onClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTalent, self.OnBtnTalentClick, nil, true)
    self.OnSelectCallback = onClick
end

-- 获取强化Id
function XUiGridScoreTowerStrengthen:GetStrengthenId()
    return self.StrengthenId
end

---@param strengthenId number 强化Id
function XUiGridScoreTowerStrengthen:Refresh(strengthenId)
    self.StrengthenId = strengthenId
    self:RefreshInfo()
end

function XUiGridScoreTowerStrengthen:RefreshInfo()
    -- 当前等级
    local curLevel = self._Control:GetStrengthenBuffCurLv(self.StrengthenId)
    self.PanelLv.gameObject:SetActiveEx(curLevel > 0)
    self.TxtNum.text = curLevel
    self.ImgMask.gameObject:SetActiveEx(curLevel <= 0)
    -- 图标
    local fightEventId = self._Control:GetStrengthenBuffFightEventId(self.StrengthenId, curLevel)
    local icon = self._Control:GetFightEventIcon(fightEventId)
    if not string.IsNilOrEmpty(icon) then
        self.RImgTalent:SetRawImage(icon)
    end
end

-- 刷新红点
function XUiGridScoreTowerStrengthen:RefreshRedPoint(isPass)
    self.BtnTalent:ShowReddot(isPass and self._Control:CheckStrengthenBuffCanStrengthen(self.StrengthenId))
end

-- 设置选中状态
function XUiGridScoreTowerStrengthen:SetSelect(isSelect)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActive(isSelect)
    end
end

function XUiGridScoreTowerStrengthen:OnBtnTalentClick()
    if self.OnSelectCallback then
        self.OnSelectCallback(self.StrengthenId, self)
    end
end

return XUiGridScoreTowerStrengthen
