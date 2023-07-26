---@class XUiGoldenMinerItemGrid
local XUiItemGrid = XClass(nil, "XUiItemGrid")

---黄金矿工通用道具格子
function XUiItemGrid:Ctor(ui, isGame)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsGame = isGame
    XTool.InitUiObject(self)

    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
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
function XUiItemGrid:Refresh(itemColumn, itemIndex)
    self.ItemColumn = itemColumn
    if self.PcBtnShow then
        self.PcBtnShow:SetKey(CS.XOperationType.ActivityGame, itemIndex + XGoldenMinerConfigs.GAME_PC_KEY.D)
        self.PcBtnShow.gameObject:SetActiveEx(XDataCenter.UiPcManager.IsPc())
    end
    if not itemColumn then
        self:SetRImgIconActive(false)
        return
    end

    local itemId = itemColumn:GetItemId()
    local iconPath = XGoldenMinerConfigs.GetItemIcon(itemId)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(iconPath)
    end
    self:SetRImgIconActive(self.DataDb:IsUseItem(itemColumn:GetGridIndex()))
end

function XUiItemGrid:SetUseItemActive(isActive)
    self.BtnClick.gameObject:SetActiveEx(isActive)
end

function XUiItemGrid:SetRImgIconActive(isActive)
    if self.RImgIcon then
        self.RImgIcon.gameObject:SetActiveEx(isActive)
    end
    if self.ImgNotItem then
        self.ImgNotItem.gameObject:SetActiveEx(not isActive)
    end
    local icon = XGoldenMinerConfigs.GetGameItemBgIcon(isActive)
    if self.IsGame and self.Bg and not string.IsNilOrEmpty(icon) then
        self.Bg:SetSprite(icon)
    end
end

function XUiItemGrid:GetItemColumn()
    return self.ItemColumn
end

function XUiItemGrid:OnBtnClick()
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

return XUiItemGrid