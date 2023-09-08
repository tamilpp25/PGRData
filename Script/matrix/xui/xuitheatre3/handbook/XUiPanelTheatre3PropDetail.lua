local XUiGridTheatre3Equipment = require("XUi/XUiTheatre3/Handbook/XUiGridTheatre3Equipment")
local XUiPanelTheatre3BubbleAffixTip = require("XUi/XUiTheatre3/Tips/XUiPanelTheatre3BubbleAffixTip")

---@class XUiPanelTheatre3PropDetail : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Handbook
---@field Transform UnityEngine.RectTransform
local XUiPanelTheatre3PropDetail = XClass(XUiNode, "XUiPanelTheatre3PropDetail")

function XUiPanelTheatre3PropDetail:OnStart()
    self.GridSetUi = XTool.InitUiObjectByUi({}, self.GridSet)
    self.GridPropUi = XTool.InitUiObjectByUi({}, self.GridProp)
    self.PanelPropUi = XTool.InitUiObjectByUi({}, self.PanelProp)
    self.PanelSetUi = XTool.InitUiObjectByUi({}, self.PanelSet)
    ---@type XUiGridTheatre3Equipment[]
    self.GridEquipmentList = {}
    ---@type XUiPanelTheatre3BubbleAffixTip
    self.PanelBubbleAffixTip = nil
    self.IsShowSuitAffix = false
    if self.GridPropUi.RedPoint then
        self.GridPropUi.RedPoint.gameObject:SetActiveEx(false)
    end
    if self.PanelPropUi.PanelCondition then
        self.PanelPropUi.PanelCondition.gameObject:SetActiveEx(false)
    end
    if self.PanelSetUi.TxtStory then
        self.PanelSetUi.TxtStory.transform.parent.gameObject:SetActiveEx(false)
    end

    self.QualityObjDir = {
        [3] = self.GridPropUi.ImgQualityBlue,
        [4] = self.GridPropUi.ImgQualityPurple,
        [5] = self.GridPropUi.ImgQualityOrange,
    }
end

function XUiPanelTheatre3PropDetail:OnDisable()
    self:OnHideSuitEffectDetail()
    
end

function XUiPanelTheatre3PropDetail:Refresh(id)
    self.Id = id
    self:RefreshStatus()
    self:RefreshView()
end

function XUiPanelTheatre3PropDetail:RefreshView()
    local isProp = self.Parent:CheckCurTypeIsProp()
    local isSet = self.Parent:CheckCurTypeIsSet()
    if isProp then
        -- 是否解锁
        local isUnlock = self._Control:CheckUnlockItemId(self.Id)
        local itemConfig = self._Control:GetItemConfigById(self.Id)
        -- 名称
        self.TxtName.text = isUnlock and itemConfig.Name or self._Control:GetClientConfig("HandbookPropLockName")
        -- 图片和品质图
        self.GridPropUi.RImgIcon:SetRawImage(itemConfig.Icon)
        if not XTool.IsTableEmpty(self.QualityObjDir) then
            for i, obj in pairs(self.QualityObjDir) do
                obj.gameObject:SetActiveEx(i == itemConfig.Quality)
            end
        end
        -- 效果 解锁条件 简介
        self.PanelPropUi.TxtWorldDesc.text = itemConfig.WorldDesc
        -- 屏蔽 道具 动态效果描述
        self.PanelPropUi.TxtDesc.text = XUiHelper.FormatText(itemConfig.Description, "")

        self.GridPropUi.PanelLock.gameObject:SetActiveEx(not isUnlock)
        self.PanelPropUi.PanelWorldDesc.gameObject:SetActiveEx(isUnlock)
        self.PanelPropUi.PanelDesc.gameObject:SetActiveEx(isUnlock)
        self.TextLock.gameObject:SetActiveEx(not isUnlock)
        if not isUnlock then
            local conditionId = self._Control:GetItemUnlockConditionId(self.Id)
            self.TextLock.text = XConditionManager.GetConditionDescById(conditionId)
        end
    end
    if isSet then
        -- 是否解锁
        local isUnlock = self._Control:CheckAnyEquipIdUnlock(self.Id)
        local equipSuitConfig = self._Control:GetSuitById(self.Id)
        -- 名称
        self.TxtName.text = isUnlock and equipSuitConfig.SuitName or self._Control:GetClientConfig("HandbookPropLockName")
        -- 图片
        self.GridSetUi.RImgIcon:SetRawImage(equipSuitConfig.Icon)
        self.GridSetUi.PanelLock.gameObject:SetActiveEx(not isUnlock)
        -- 状态设置
        self.PanelSetUi.GameObject:SetActiveEx(isUnlock)
        self.TextLock.gameObject:SetActiveEx(not isUnlock)
        if not isUnlock then
            self.TextLock.text = self._Control:GetClientConfig("HandbookPropDetailLockTips", 2)
        end
        if isUnlock then
            self.PanelSetUi.TxtDesc.gameObject:SetActiveEx(false)
            self.PanelSetUi.TxtDesc.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(XUiHelper.FormatText(equipSuitConfig.Desc, equipSuitConfig.TraitName)))
            self.PanelSetUi.TxtDesc.gameObject:SetActiveEx(true)
            --self.PanelSetUi.TxtStory.text = equipSuitConfig.StoryDesc
            self.PanelSetUi.BtnBuff.CallBack = function()
                self:OnShowSuitEffectDetail()
            end
            local equipConfigs = self._Control:GetAllSuitEquip(self.Id)
            for i = 1, 3 do
                local grid = self.GridEquipmentList[i]
                if not grid then
                    local equipmentUi = self.PanelSetUi["UiEquipment" .. i]
                    grid = XUiGridTheatre3Equipment.New(equipmentUi, self)
                    self.GridEquipmentList[i] = grid
                end
                local config = equipConfigs[i]
                if config then
                    grid:Open()
                    grid:Refresh(config.Id)
                else
                    grid:Close()
                end
            end
            if not self.PanelBubbleAffixTip then
                self.PanelBubbleAffixTip = XUiPanelTheatre3BubbleAffixTip.New(self.PanelSetUi.BubbleAffix, self)
            end
            -- 默认隐藏
            self:OnHideSuitEffectDetail()
        end
    end
end

function XUiPanelTheatre3PropDetail:RefreshStatus()
    local isProp = self.Parent:CheckCurTypeIsProp()
    local isSet = self.Parent:CheckCurTypeIsSet()
    self.GridSet.gameObject:SetActiveEx(isSet)
    self.GridProp.gameObject:SetActiveEx(isProp)
    self.PanelSet.gameObject:SetActiveEx(isSet)
    self.PanelProp.gameObject:SetActiveEx(isProp)
    self.TextLock.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre3PropDetail:OnShowSuitEffectDetail()
    local isSet = self.Parent:CheckCurTypeIsSet()
    if not isSet then
        return
    end
    local equipSuitConfig = self._Control:GetSuitById(self.Id)
    if not equipSuitConfig or XTool.IsTableEmpty(equipSuitConfig.TraitName) then
        return
    end
    self.IsShowSuitAffix = not self.IsShowSuitAffix
    if self.IsShowSuitAffix then
        self.PanelBubbleAffixTip:Open()
        self.PanelBubbleAffixTip:Refresh(equipSuitConfig)
    else
        self.PanelBubbleAffixTip:Close()
    end
end

function XUiPanelTheatre3PropDetail:OnHideSuitEffectDetail()
    if self.PanelBubbleAffixTip then
        self.IsShowSuitAffix = false
        self.PanelBubbleAffixTip:Close()
    end
end

return XUiPanelTheatre3PropDetail