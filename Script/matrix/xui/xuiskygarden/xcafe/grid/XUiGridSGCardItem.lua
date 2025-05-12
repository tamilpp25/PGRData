---@class XUiGridSGCardItem : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiSkyGardenCafeHandBook
---@field _Control XSkyGardenCafeControl
local XUiGridSGCardItem = XClass(XUiNode, "XUiGridSGCardItem")

local XUiGridSGCardTag = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardTag")
local XUiGridSGCardTagWithDetail = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardTagWithDetail")
local XUiPanelSGValueChange = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGValueChange")

function XUiGridSGCardItem:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiGridSGCardItem:OnDisable()
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiGridSGCardItem:InitCb()
    if self.BtnCheck then
        self.BtnCheck.gameObject:SetActiveEx(true)
        self.BtnCheck.CallBack = function()
            self:OnBtnCheckClick()
        end
    end

    if self.TxtDetail then
        self.TxtDetail.requestImage = XMVCA.XSkyGardenCafe.RichTextImageCallBackCb
    end
end

function XUiGridSGCardItem:InitView()
    if self.PanelCoffee then
        self._PanelCoffee = XUiPanelSGValueChange.New(self.PanelCoffee)
    end

    if self.PanelReview then
        self._PanelReview = XUiPanelSGValueChange.New(self.PanelReview)
    end

    if self.GridTag then
        self.GridTag.gameObject:SetActiveEx(false)
    end

    if not self.RImgBg then
        self.RImgBg = self.Transform:FindTransform("RImgBg"):GetComponent("RawImage")
    end
end

--- 刷新小卡牌
---@param card XSGCafeCard 
--------------------------
function XUiGridSGCardItem:RefreshSmall(card)
    local cardId = card:GetId()

    self._CardId = cardId
    self.RImgHead:SetRawImage(self._Control:GetCustomerIcon(cardId))
    local quality = self._Control:GetCustomerQuality(cardId)
    self.ImgCard5.gameObject:SetActiveEx(quality == 5)
    self.ImgCard4.gameObject:SetActiveEx(quality == 4)
    self.ImgCard3.gameObject:SetActiveEx(quality == 3)
    self.TxtName.text = self._Control:GetCustomerName(cardId)
    local count = card:Count()
    self.TxtNum.text = string.format("x%d", count)
    self.Effect.gameObject:SetActiveEx(false)
end

function XUiGridSGCardItem:PlayEnableEffect()
    if not self.Effect then
        return
    end
    self.Effect.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(true)
end

--- 刷新大卡牌
---@param card XSGCafeCard  
---@param useCount number 已经使用掉的数量  
--------------------------
function XUiGridSGCardItem:RefreshBig(card, useCount)
    local cardId = card:GetId()
    self._CardId = cardId
    --local unlock = self._Control:CheckCardUnlock(cardId)
    local unlock = true
    self.PanelLock.gameObject:SetActiveEx(not unlock)
    self.TxtDetail.gameObject:SetActiveEx(unlock)
    self.PanelCard.gameObject:SetActiveEx(true)
    self.PanelNum.gameObject:SetActiveEx(true)
    
    if not unlock then
        self.TxtLock.text = self._Control:GetCustomerUnlockDesc(cardId)
    end

    self.RImgHead:SetRawImage(self._Control:GetCustomerIcon(cardId))
    self.TxtName.text = self._Control:GetCustomerName(cardId)
    local coffee = self._Control:GetCustomerCoffee(cardId)
    local review = self._Control:GetCustomerReview(cardId)

    self._PanelCoffee:RefreshView(coffee, coffee)
    self._PanelReview:RefreshView(review, review)
    
    local count = card:PreviewCount(useCount)
    local isValid = count > 0
    self.PanelNum.gameObject:SetActiveEx(isValid)
    if self.NothingMask then
        self.NothingMask.gameObject:SetActiveEx(not isValid)
    end
    if isValid then
        self.TxtCount.text = string.format("x%d", count)
    end

    if unlock then
        self.TxtDetail.text = self._Control:IsShowCardDetail() and self._Control:GetCustomerDetails(cardId) or self._Control:GetCustomerDesc(cardId)
    end
    if self.RImgBg then
        self.RImgBg:SetRawImage(self._Control:GetCustomerQualityIcon(cardId))
    end
    self:RefreshTags(self._Control:GetCustomerTags(cardId))
end

--- 刷新卡组卡牌
---@param cardId number
function XUiGridSGCardItem:RefreshLibrary(cardId)
    self._CardId = cardId
    self.PanelLock.gameObject:SetActiveEx(false)
    self.TxtDetail.gameObject:SetActiveEx(true)
    self.PanelCard.gameObject:SetActiveEx(true)
    self.PanelNum.gameObject:SetActiveEx(false)

    self.RImgHead:SetRawImage(self._Control:GetCustomerIcon(cardId))
    self.TxtDetail.text = self._Control:GetCustomerDesc(cardId)
    self.TxtName.text = self._Control:GetCustomerName(cardId)
    local coffee = self._Control:GetCustomerCoffee(cardId)
    local review = self._Control:GetCustomerReview(cardId)
    self._PanelCoffee:RefreshView(coffee, coffee)
    self._PanelReview:RefreshView(review, review)
    if self.RImgBg then
        self.RImgBg:SetRawImage(self._Control:GetCustomerQualityIcon(cardId))
    end
    self:RefreshTags(self._Control:GetCustomerTags(cardId))
end

function XUiGridSGCardItem:RefreshDetail(cardId)
    self._CardId = cardId
    --local unlock = self._Control:CheckCardUnlock(cardId)
    local unlock = true
    self.PanelLock.gameObject:SetActiveEx(not unlock)
    self.TxtDetail.gameObject:SetActiveEx(unlock)
    self.PanelCard.gameObject:SetActiveEx(true)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelNum.gameObject:SetActiveEx(false)
    self.BtnCheck.gameObject:SetActiveEx(false)
    if not unlock then
        self.TxtLock.text = self._Control:GetCustomerUnlockDesc(cardId)
    end
    self.RImgHead:SetRawImage(self._Control:GetCustomerIcon(cardId))
    self.TxtName.text = self._Control:GetCustomerName(cardId)
    local coffee = self._Control:GetCustomerCoffee(cardId)
    local review = self._Control:GetCustomerReview(cardId)

    self._PanelCoffee:RefreshView(coffee, coffee)
    self._PanelReview:RefreshView(review, review)
    self.TxtDetail.text = self._Control:GetCustomerDetails(cardId)
    local worldDesc = self._Control:GetCustomerWorldDesc(cardId)
    local validDesc = not string.IsNilOrEmpty(worldDesc)
    self.PanelStory.gameObject:SetActiveEx(validDesc)
    if validDesc then
        self.TxtWorldDesc.text = worldDesc
    end
    if self.RImgBg then
        self.RImgBg:SetRawImage(self._Control:GetCustomerQualityIcon(cardId))
    end
    self:RefreshTags(self._Control:GetCustomerTags(cardId), true)
end

function XUiGridSGCardItem:RefreshTags(tags, isDetail)
    if not self._GridTags then
        self._GridTags = {}
    end
    local hasTag = not XTool.IsTableEmpty(tags)
    if isDetail then
        if not self._GridTagDetails then
            self._GridTagDetails = {}
        end
        self.ListTagDetail.gameObject:SetActiveEx(hasTag)
    end
    if hasTag then
        for i, tagId in pairs(tags) do
            local gridTag = self:GetTagGrid(i, false)
            local tagName = self._Control:GetTagName(tagId)
            gridTag:Refresh(tagName)
            if isDetail then
                local gridTagWithDetail = self:GetTagGrid(i, true)
                gridTagWithDetail:Refresh(tagName, self._Control:GetTagDesc(tagId))
            end
        end
    end
end

function XUiGridSGCardItem:GetTagGrid(index, isDetail)
    local grids = isDetail and self._GridTagDetails or self._GridTags
    local grid = grids[index]
    if not grid then
        local ui
        if index == 1 then
            ui = isDetail and self.GridTagDetail or self.GridTag
        else
            local name = isDetail and "GridTagDetail" .. index or "GridTag" .. index
            ui = self.Transform:FindTransform(name)
            if not ui then
                local prefab = isDetail and self.GridTagDetail or self.GridTag
                local parent = isDetail and self.ListTagDetail or self.PanelTag
                ui =  XUiHelper.Instantiate(prefab, parent)
                ui.gameObject.name = name
            end
        end
        grid = isDetail and XUiGridSGCardTagWithDetail.New(ui) or XUiGridSGCardTag.New(ui)
        grids[index] = grid
    end
    return grid
end

function XUiGridSGCardItem:Recycle()
    if not XTool.IsTableEmpty(self._GridTags) then
        for _, grid in pairs(self._GridTags) do
            grid:Close()
        end
    end
    
    if not XTool.IsTableEmpty(self._GridTagDetails) then
        for _, grid in pairs(self._GridTagDetails) do
            grid:Close()
        end
    end
    self._GridTags = nil
    self._GridTagDetails = nil
end

function XUiGridSGCardItem:OnBtnCheckClick()
    if not self._CardId or self._CardId <= 0 then
        return
    end
    XLuaUiManager.Open("UiSkyGardenCafePopupCardDetail", self._CardId)
end

function XUiGridSGCardItem:GetCardId()
    return self._CardId
end

return XUiGridSGCardItem