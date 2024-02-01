-- 道具卡片
---@class XUiGridRogueSimProp : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimProp = XClass(XUiNode, "XUiGridRogueSimProp")

function XUiGridRogueSimProp:OnStart(callBack, sureCallBack)
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    self.SelectCallBack = callBack
    self.SureCallBack = sureCallBack
    self.PanelSelect.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
end

---@param propId number 道具配置Id
---@param id number 道具自增Id
function XUiGridRogueSimProp:Refresh(propId, id)
    self.PropId = propId
    self.Id = id
    self:RefreshView()
end

-- 设置index
function XUiGridRogueSimProp:SetIndex(index)
    self.Index = index
end

function XUiGridRogueSimProp:GetIndex()
    return self.Index
end

function XUiGridRogueSimProp:RefreshView()
    -- 道具图标
    self.RImgProp:SetRawImage(self._Control.MapSubControl:GetPropIcon(self.PropId))
    -- 道具名称
    self.TxtName.text = self._Control.MapSubControl:GetPropName(self.PropId)
    -- 道具效果描述
    self.TxtDetail.text = self:GetEffectDesc()
    -- 道具描述
    self.TxtStory.text = self._Control.MapSubControl:GetPropDesc(self.PropId)
    -- 道具稀有度
    local rare = self._Control.MapSubControl:GetPropRare(self.PropId)
    self.RImgBg:SetRawImage(self._Control.MapSubControl:GetPropRareIcon(rare))
end

function XUiGridRogueSimProp:GetEffectDesc()
    local effectDesc = self._Control.MapSubControl:GetPropEffectDesc(self.PropId)
    if not XTool.IsNumberValid(self.Id) then
        return effectDesc
    end
    local buffIds = self._Control.MapSubControl:GetPropBuffIds(self.PropId)
    -- 部分道具没有buffId
    if XTool.IsTableEmpty(buffIds) then
        return effectDesc
    end
    -- 默认显示第一个buff的累计加成
    local cumulativeAdd, isNotPercent = self._Control.BuffSubControl:GetBuffCumulativeAdd(buffIds[1], self.Id)
    -- 为空时不显示累计加成
    if not cumulativeAdd then
        return effectDesc
    end
    local addDesc = self._Control:GetClientConfig("PropBuffCumulativeMarkupTip", isNotPercent and 2 or 1)
    local cumulativeDesc = string.format(addDesc, cumulativeAdd)
    return string.format("%s%s", effectDesc, cumulativeDesc)
end

function XUiGridRogueSimProp:OnUnSelect()
    self.PanelSelect.gameObject:SetActiveEx(false)
end

function XUiGridRogueSimProp:OnSelect()
    self.PanelSelect.gameObject:SetActiveEx(true)
end

function XUiGridRogueSimProp:OnBtnPropClick()
    if self.SelectCallBack then
        self.SelectCallBack(self)
    end
end

function XUiGridRogueSimProp:OnBtnYesClick()
    if self.SureCallBack then
        self.SureCallBack()
    end
end

function XUiGridRogueSimProp:ShowLock(isLock)
    self.PanelLock.gameObject:SetActiveEx(isLock)
end

function XUiGridRogueSimProp:ShowNew(isNew)
    self.PanelNew.gameObject:SetActiveEx(isNew)
end

return XUiGridRogueSimProp
