--肉鸽玩法二期 道具格子
local XUiBiancaTheatreItemGrid = XClass(nil, "XUiBiancaTheatreItemGrid")

function XUiBiancaTheatreItemGrid:Ctor(ui, isNotRegisterClickEvent, rootUi, isSetBtnTxtColor)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.IsSetBtnTxtColor = isSetBtnTxtColor    --是否设置按钮文本品质颜色
    XUiHelper.InitUiClass(self, ui)
    self:Init()
    self:RegisterClickEvent(isNotRegisterClickEvent)
    self.GameObject:SetActiveEx(true)
end

function XUiBiancaTheatreItemGrid:Init()
    self.Btn = self.Btn or self.GameObject:GetComponent("XUiButton")
    self.Reddot = self.Reddot or self.Transform:Find("Red")
end

function XUiBiancaTheatreItemGrid:RegisterClickEvent(isNotRegisterClickEvent)
    if isNotRegisterClickEvent then
        return
    end
    if self.Btn then
        self.Btn.CallBack = function() self:OnBtnClick() end
    else
        XUiHelper.RegisterClickEvent(self, self.Transform, handler(self, self.OnBtnClick))
    end
end

function XUiBiancaTheatreItemGrid:Refresh(itemId, curSelectItemId, itemCount, itemType)
    if not XTool.IsNumberValid(itemId) then
        return
    end

    self.ItemId = itemId
    self.ItemType = itemType
    local itemIcon = XBiancaTheatreConfigs.GetEventStepItemIcon(itemId, itemType)
    local quality = XBiancaTheatreConfigs.GetEventStepItemQuality(itemId, itemType)
    local qualityPath = XBiancaTheatreConfigs.GetEventStepItemQualityIcon(itemId, itemType)
    local itemName = XBiancaTheatreConfigs.GetEventStepItemName(itemId, itemType)
    local itemDesc = XBiancaTheatreConfigs.GetEventStepItemDesc(itemId, itemType)

    --道具图标
    if self.Btn and itemIcon then
        self.Btn:SetRawImage(itemIcon)
    end
    if self.RImgIcon and itemIcon then
        self.RImgIcon:SetRawImage(itemIcon)
    end

    --道具品质
    if self.Btn and qualityPath then
        self.Btn:SetSprite(qualityPath)
    end
    if self.ImgQuality then
        if qualityPath then
            self.ImgQuality:SetSprite(qualityPath)
        end
        self.ImgQuality.gameObject:SetActiveEx(qualityPath and true or false)
    end

    --道具名
    local nameColor = quality and XBiancaTheatreConfigs.GetQualityTextColor(quality)
    self:SetBtnItemName(itemName, nameColor)
    if self.TxtDes then
        self.TxtDes.text = itemName
        if nameColor then
            self.TxtDes.color = nameColor
        end
    end
    if self.TxtName then
        self.TxtName.text = itemName
        if nameColor then
            self.TxtName.color = nameColor
        end
    end
    
    --道具描述
    self:SetBtnItemDesc(itemDesc)
    if self.TxtProgress then
        self.TxtProgress.text = itemDesc
    end

    --道具数量
    if self.TxtCount then
        local count = itemCount or 1
        self.TxtCount.text = "x" .. count
    end
    
    local unlock = XDataCenter.BiancaTheatreManager.IsUnlockItem(itemId)
    self:SetIsLock(unlock)
    --是否选中
    self:SetIsSelect(itemId == curSelectItemId)

    --红点
    self:RefreshReddot(itemId)
end

function XUiBiancaTheatreItemGrid:RefreshReddot(itemId)
    if not self.Reddot then
        return
    end
    self.Reddot.gameObject:SetActiveEx(XDataCenter.BiancaTheatreManager.CheckFieldGuideGridRedPoint(itemId))
end

function XUiBiancaTheatreItemGrid:SetBtnItemName(text, color)
    if self.Btn then
        if self.IsSetBtnTxtColor and color then
            self.Btn:SetNameAndColorByGroup(0, text, color)
        else
            self.Btn:SetNameByGroup(0, text)
        end
    end
end

function XUiBiancaTheatreItemGrid:SetBtnItemDesc(text, color)
    if self.Btn then
        if self.IsSetBtnTxtColor and color then
            self.Btn:SetNameAndColorByGroup(1, text, color)
        else
            self.Btn:SetNameByGroup(1, text)
        end
    end
end

function XUiBiancaTheatreItemGrid:SetIsSelect(isSelect)
    if self.Normal then
        self.Normal.gameObject:SetActiveEx(not isSelect)
    end
    if self.Select then
        self.Select.gameObject:SetActiveEx(isSelect)
    end
end

function XUiBiancaTheatreItemGrid:GetTheatreItemId()
    return self.ItemId
end

--打开道具详情弹窗（可被外部重写）
function XUiBiancaTheatreItemGrid:OnBtnClick()
    XLuaUiManager.Open("UiBiancaTheatreTips", {
        TheatreItemId = self:GetTheatreItemId(),
    }, self.ItemType)
end

--设置是否显示锁
function XUiBiancaTheatreItemGrid:SetIsLock(unlock)
    if self.Lock then
        self.Lock.gameObject:SetActiveEx(not unlock)
    end
end

function XUiBiancaTheatreItemGrid:PlaySelectAnim()
    if self.GridEnable then
        self.GridEnable:Play()
    end
end

function XUiBiancaTheatreItemGrid:StopSelectAnim()
    if self.GridEnable then
        self.GridEnable:Stop()
        self.GridEnable:Evaluate()
    end
end

return XUiBiancaTheatreItemGrid