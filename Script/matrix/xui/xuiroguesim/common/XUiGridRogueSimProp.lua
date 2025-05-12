-- 道具卡片
---@class XUiGridRogueSimProp : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimProp = XClass(XUiNode, "XUiGridRogueSimProp")

function XUiGridRogueSimProp:OnStart(callBack, sureCallBack)
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick, true, true)
    self.SelectCallBack = callBack
    self.SureCallBack = sureCallBack
    self.PanelSelect.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.GridTag.gameObject:SetActiveEx(false)
    self.GridScore.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridShowLabelList = {}
    ---@type UiObject[]
    self.GridScoreList = {}
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
    -- 刷新显示标签
    self:RefreshShowLabels()
    -- 刷新评分列表
    self:RefreshScoreList()
end

-- 刷新标签
function XUiGridRogueSimProp:RefreshShowLabels()
    local showLabels = self._Control.MapSubControl:GetPropShowLabels(self.PropId)
    if XTool.IsTableEmpty(showLabels) then
        self.ListTag.gameObject:SetActiveEx(false)
        return
    end
    self.ListTag.gameObject:SetActiveEx(true)
    for index, id in ipairs(showLabels) do
        local grid = self.GridShowLabelList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTag, self.ListTag)
            self.GridShowLabelList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtTag").text = self._Control.MapSubControl:GetPropShowLabelDesc(id)
        local color = self._Control.MapSubControl:GetPropShowLabelColor(id)
        grid:GetObject("ImgBg").color = XUiHelper.Hexcolor2Color(color)
    end
    for i = #showLabels + 1, #self.GridShowLabelList do
        self.GridShowLabelList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新评分列表
function XUiGridRogueSimProp:RefreshScoreList()
    local index = 1
    for _, id in pairs(XEnumConst.RogueSim.CommodityIds) do
        local score = self._Control.MapSubControl:GetPropShowScore(self.PropId, id)
        if score > 0 then
            local grid = self.GridScoreList[index]
            if not grid then
                grid = XUiHelper.Instantiate(self.GridScore, self.ListScore)
                self.GridScoreList[index] = grid
            end
            grid.gameObject:SetActiveEx(true)
            local icon = self._Control.ResourceSubControl:GetCommodityIcon(id)
            grid:GetObject("RImgResource"):SetRawImage(icon)
            grid:GetObject("TxtNum").text = score
            index = index + 1
        end
    end
    for i = index, #self.GridScoreList do
        self.GridScoreList[i].gameObject:SetActiveEx(false)
    end
    self.ListScore.gameObject:SetActiveEx(index > 1)
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
    local cumulativeDesc = self._Control.BuffSubControl:GetPropBuffCumulativeAddDesc(buffIds[1], self.Id)
    if string.IsNilOrEmpty(cumulativeDesc) then
        return effectDesc
    end
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
