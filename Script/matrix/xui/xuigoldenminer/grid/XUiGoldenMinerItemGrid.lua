---@class XUiGoldenMinerItemGrid:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerItemGrid = XClass(XUiNode, "XUiGoldenMinerItemGrid")

---黄金矿工通用道具格子
function XUiGoldenMinerItemGrid:OnStart(isGame)
    self.IsGame = isGame

    self.DataDb = self._Control:GetMainDb()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.GameObject:SetActiveEx(true)
    if isGame and self.PanelPropNot then
        self.PanelPropNot.gameObject:SetActiveEx(false)
    end
    ---@type XUiPc.XUiPcCustomKey
    self.PcBtnShow = XUiHelper.TryGetComponent(self.Transform, "GridSubSkillPC", "XUiPcCustomKey")
    if self.PcBtnShow then
        self.PcBtnShow.gameObject:SetActiveEx(false)
    end
end

---@param itemColumn XGoldenMinerItemData
function XUiGoldenMinerItemGrid:Refresh(itemColumn, itemIndex)
    self.ItemColumn = itemColumn
    if self.PcBtnShow then
        self.PcBtnShow:SetKey(CS.XOperationType.ActivityGame, itemIndex + XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Right)
        self.PcBtnShow.gameObject:SetActiveEx(XDataCenter.UiPcManager.IsPc())
    end
    if not itemColumn then
        self:SetRImgIconActive(false)
        return
    end

    local itemId = itemColumn:GetItemId()
    local iconPath = self._Control:GetCfgItemIcon(itemId)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(iconPath)
    end
    self:SetRImgIconActive(self.DataDb:IsUseItem(itemColumn:GetGridIndex()))
end

function XUiGoldenMinerItemGrid:SetUseItemActive(isActive)
    self.BtnClick.gameObject:SetActiveEx(isActive)
end

function XUiGoldenMinerItemGrid:SetRImgIconActive(isActive)
    if self.RImgIcon then
        self.RImgIcon.gameObject:SetActiveEx(isActive)
    end
    if self.ImgNotItem then
        self.ImgNotItem.gameObject:SetActiveEx(not isActive)
    end
    local icon = self._Control:GetClientGameItemBgIcon(isActive)
    if self.IsGame and self.Bg and not string.IsNilOrEmpty(icon) then
        self.Bg:SetSprite(icon)
    end
end

function XUiGoldenMinerItemGrid:GetItemColumn()
    return self.ItemColumn
end

function XUiGoldenMinerItemGrid:OnBtnClick()
    local itemColumn = self.ItemColumn
    local itemIndex = not XTool.IsTableEmpty(itemColumn) and itemColumn:GetGridIndex()
    if not itemIndex then
        return
    end
    
    if self.IsGame then --玩法中使用道具
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_USE_ITEM, self)
    else                --商店中准备出售道具
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, nil, self, self.Transform.position.x)
    end
end

return XUiGoldenMinerItemGrid