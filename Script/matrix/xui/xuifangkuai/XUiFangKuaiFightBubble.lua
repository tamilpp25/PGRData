---@class XUiFangKuaiFightBubble : XUiNode 负责管理道具弹框逻辑
---@field Parent XUiFangKuaiFight
---@field _Control XFangKuaiControl
local XUiFangKuaiFightBubble = XClass(XUiNode, "XUiFangKuaiFightBubble")

local BubblePos1 = CS.UnityEngine.Vector3(-70, 147, 0)
local BubblePos2 = CS.UnityEngine.Vector3(-80, 147, 0)

function XUiFangKuaiFightBubble:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnUse, self.OnClickUse)
    XUiHelper.RegisterClickEvent(self, self.BtnDetele, self.OnClickDetele)
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnClickLeft)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnClickRight)
    self:RegisterChooseColorBtn()
end

function XUiFangKuaiFightBubble:SetStageId(id)
    self._StageId = id
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFightBubble:ShowItemTip(index, item, content)
    local isNeedChooseColor = self._Control:IsItemNeedChooseColor(item.Kind)
    local isItemAddRound = self._Control:IsItemNeedUseBtn(item.Kind)

    self.BubbleProp:SetParent(content, false)
    self.BubbleProp.localPosition = index == 2 and BubblePos2 or BubblePos1

    self.BubblePropNormal.gameObject:SetActiveEx(not isNeedChooseColor and not isItemAddRound)
    self.BubblePropCut.gameObject:SetActiveEx(isNeedChooseColor and not isItemAddRound)
    self.BubblePropTime.gameObject:SetActiveEx(isItemAddRound)
    self.BubblePropPull.gameObject:SetActiveEx(false)
    self.BtnDetele.gameObject:SetActiveEx(true)
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFightBubble:UpdateShowUseBtnView(item)
    --todo:后面改成配置的
    local isUseLongBg = item.Kind == XEnumConst.FangKuai.ItemType.RandomLine or item.Kind == XEnumConst.FangKuai.ItemType.RandomBlock or item.Kind == XEnumConst.FangKuai.ItemType.Frozen
    self._CurItemType = item.Kind
    self.TxtTimeTitle.text = item.Name
    self.TxtTimeDetail.text = item.Desc
    self.SmallBg.gameObject:SetActiveEx(not isUseLongBg)
    self.BigBg.gameObject:SetActiveEx(isUseLongBg)
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFightBubble:UpdateChooseColorView(item)
    self._CurItemType = item.Kind
    self.TxtSpecialTitle.text = item.Name
    self.TxtSpecialDetail.text = item.Desc
    self:UpdateChooseColorBtn()
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFightBubble:UpdateNormalView(item)
    self._CurItemType = item.Kind
    self.TxtNormalTitle.text = item.Name
    self.TxtNormalDetail.text = item.Desc
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFightBubble:UpdateAlignmentView(item)
    self._CurItemType = item.Kind

    if self._CurItemType == XEnumConst.FangKuai.ItemType.Alignment then
        self.BubblePropNormal.gameObject:SetActiveEx(false)
        self.BubblePropPull.gameObject:SetActiveEx(true)
    end

    self.TxtPullTitle.text = item.Name
    self.TxtPullDetail.text = item.Desc
end

function XUiFangKuaiFightBubble:HideBubble()
    self._CurItemType = nil
    self.BubblePropNormal.gameObject:SetActiveEx(false)
    self.BubblePropCut.gameObject:SetActiveEx(false)
    self.BubblePropTime.gameObject:SetActiveEx(false)
    self.BubblePropPull.gameObject:SetActiveEx(false)
    self.BtnDetele.gameObject:SetActiveEx(false)
end

function XUiFangKuaiFightBubble:RegisterChooseColorBtn()
    self._ColorGridMap = {}
    local isFirst = true
    local configs = self._Control:GetAllColorTextureConfigs()
    for k, v in pairs(configs) do
        local uiObject = {}
        local grid = isFirst and self.GridColor or XUiHelper.Instantiate(self.GridColor, self.GridColor.parent)
        XUiHelper.InitUiClass(uiObject, grid)
        self._ColorGridMap[k] = grid
        self.Parent:RegisterClickEvent(grid, function()
            self.Parent:OnClickColor(k)
        end)
        uiObject.ImgOne:SetRawImage(v.StandaloneImage)
        uiObject.ImgOnePass:SetRawImage(v.StandaloneImage)
        uiObject.RImgExpression:SetRawImage(v.Standby[1])
        uiObject.RImgExpressionPass:SetRawImage(v.Standby[1])
        isFirst = false
    end
end

function XUiFangKuaiFightBubble:UpdateChooseColorBtn()
    local colors = self._Control:GetStageColorIds(self._StageId)
    for k, v in pairs(self._ColorGridMap) do
        v.gameObject:SetActiveEx(table.indexof(colors, k))
    end
end

function XUiFangKuaiFightBubble:OnClickUse()
    if self._CurItemType == XEnumConst.FangKuai.ItemType.AddRound then
        self.Parent:OnClickAddRound()
    elseif self._CurItemType == XEnumConst.FangKuai.ItemType.Frozen then
        self.Parent:OnClickFrozenRound()
    elseif self._CurItemType == XEnumConst.FangKuai.ItemType.RandomBlock then
        self.Parent:OnClickRandomBlock()
    elseif self._CurItemType == XEnumConst.FangKuai.ItemType.RandomLine then
        self.Parent:OnClickRandomLine()
    elseif self._CurItemType == XEnumConst.FangKuai.ItemType.Convertion then
        self.Parent:OnClickConvertionBlock()
    end
end

function XUiFangKuaiFightBubble:OnClickDetele()
    self.Parent:OnClickDeleteItem()
end

function XUiFangKuaiFightBubble:OnClickLeft()
    self.Parent:DoAlignmentBlock(0)
end

function XUiFangKuaiFightBubble:OnClickRight()
    self.Parent:DoAlignmentBlock(1)
end

return XUiFangKuaiFightBubble