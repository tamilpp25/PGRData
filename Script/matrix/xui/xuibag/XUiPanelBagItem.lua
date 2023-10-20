local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
local XUiGridSuitDetail = require("XUi/XUiEquipAwarenessReplace/XUiGridSuitDetail")
local XUiGridBagPartner = require("XUi/XUiPartner/PartnerCommon/XUiGridBagPartner")
local XUiPanelBagItem = XClass(XUiNode, "XUiPanelBagItem")

-- function XUiPanelBagItem:Ctor(ui)
--     self.GameObject = ui.gameObject
--     self.Transform = ui.transform
--     XTool.InitUiObject(self)
-- end

function XUiPanelBagItem:Init(rootUi, page, isfirstanimation)
    self.GameObject:SetActive(true)
    self.Parent = rootUi
    self.Page = page
    self.IsFirstAnimation = isfirstanimation
    local clickCb = function(data, grid)
        self.Parent:OnGridClick(data, grid)
    end

    self.EquipGrid = XUiGridEquip.New(self.GridEquip, rootUi, clickCb)
    self.SuitGrid = XUiGridSuitDetail.New(self.GridSuitSimple, rootUi, clickCb)
    self.BagItemGrid = XUiBagItem.New(rootUi, self.GridBagItem, nil, clickCb)
    self.BagPartnerGrid = XUiGridBagPartner.New(self.GridPartner, clickCb)

    ---@type UnityEngine.CanvasGroup
    self._GridEquipCanvas = XUiHelper.TryGetComponent(self.Transform, "GridEquip/GridEquipRectangle", "CanvasGroup")
    self._IsResetAlpha = false
end

function XUiPanelBagItem:SetupCommon(data, pageType, operation, gridSize)
    self.BagItemGrid:Refresh(data)
    self.BagItemGrid.GameObject:SetActive(true)
    self.GridBagItemRect.sizeDelta = gridSize
    self.EquipGrid:Close()
    self.SuitGrid.GameObject:SetActive(false)
    self.BagPartnerGrid.GameObject:SetActive(false)
end

function XUiPanelBagItem:SetupEquip(equipId, gridSize)
    self.EquipGrid:Refresh(equipId)
    self.EquipGrid:Open()
    self.GridEquipRect.sizeDelta = gridSize
    self.SuitGrid.GameObject:SetActive(false)
    self.BagItemGrid.GameObject:SetActive(false)
    self.BagPartnerGrid.GameObject:SetActive(false)
end

function XUiPanelBagItem:SetupSuit(suitId, defaultSuitIds, gridSize)
    self.SuitGrid:Refresh(suitId, defaultSuitIds, true)
    self.SuitGrid.GameObject:SetActive(true)
    self.GridSuitSimpleRect.sizeDelta = gridSize
    self.EquipGrid:Close()
    self.BagItemGrid.GameObject:SetActive(false)
    self.BagPartnerGrid.GameObject:SetActive(false)
end

function XUiPanelBagItem:SetupPartner(partner, gridSize, isInPrefab)
    self.BagPartnerGrid:UpdateGrid(partner, isInPrefab)
    self.BagPartnerGrid.GameObject:SetActive(true)
    self.BagPartnerGrid.sizeDelta = gridSize
    self.EquipGrid:Close()
    self.BagItemGrid.GameObject:SetActive(false)
    self.SuitGrid.GameObject:SetActive(false)
end

function XUiPanelBagItem:SetSelectedEquip(bSelect)
    self.EquipGrid:SetSelected(bSelect)
end

function XUiPanelBagItem:SetSelectedCommon(bSelect)
    self.BagItemGrid:SetSelectState(bSelect)
end

function XUiPanelBagItem:SetSelectedPartner(bSelect)
    self.BagPartnerGrid:SetSelected(bSelect)
end

function XUiPanelBagItem:PlayAnimation()
    if not self.IsFirstAnimation then
        return
    end

    self.IsFirstAnimation = false
    if self.Page == XItemConfigs.PageType.Equip or self.Page == XItemConfigs.PageType.Awareness then
        self:PlayTimelineAnimation(self.GridEquipTimeline.gameObject, function()
            -- bug 在动画播放到一半时，滚动列表，导致透明度错误
            if self._GridEquipCanvas and self._GridEquipCanvas.alpha < 1 then
                self._IsResetAlpha = true
            end
        end)
    elseif self.Page == XItemConfigs.PageType.SuitCover then
        self:PlayTimelineAnimation(self.GridSuitSimpleTimeline.gameObject)
    elseif self.Page == XItemConfigs.PageType.Partner then
        self:PlayTimelineAnimation(self.GridPartnerTimeline.gameObject)
    else
        self:PlayTimelineAnimation(self.GridBagItemTimeline.gameObject)
    end
end

---@param gameObject UnityEngine.GameObject
function XUiPanelBagItem:PlayTimelineAnimation(gameObject, finish, begin, wrapMode)
    if XTool.UObjIsNil(gameObject) then
        return
    end

    if not gameObject.activeInHierarchy then
        return
    end
    wrapMode = wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold
    gameObject:PlayTimelineAnimation(finish, begin, wrapMode)
end

function XUiPanelBagItem:ResetCanvasAlpha()
    if self._IsResetAlpha and self._GridEquipCanvas then
        self._GridEquipCanvas.alpha = 1
    end
end

return XUiPanelBagItem