local HeadMaxNum = 4
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridTRPGBuff = require("XUi/XUiTRPG/XUiGridTRPGBuff")

--使用道具界面
local XUiTRPGItemUsePanel = XClass(nil, "XUiTRPGItemUsePanel")

function XUiTRPGItemUsePanel:Ctor(ui, rootUi, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Cb = cb
    XTool.InitUiObject(self)

    self:Init()
    self:AutoAddListener()
end

function XUiTRPGItemUsePanel:Init()
    self.ButtonGroup = {}
    local headIcon
    local allRoleIds = XTRPGConfigs.GetAllRoleIds()
    local roleId
    for i = 1, HeadMaxNum do
        roleId = allRoleIds[i]
        headIcon = XTRPGConfigs.GetRoleHeadIcon(roleId)
        self["head" .. i]:SetRawImage(headIcon)
        self.ButtonGroup[i] = self["head" .. i]
    end

    self.PanelHead:Init(self.ButtonGroup, function(groupIndex) self:ButtonGroupSkip(groupIndex) end)

    self.BuffGrids = {}
end

function XUiTRPGItemUsePanel:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnTongBlack, function() self:OnBtnUseClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnTongBlue, function() self:Close() end)
    CsXUiHelper.RegisterClickEvent(self.BtnTanchuangClose, function() self:Close() end)
end

function XUiTRPGItemUsePanel:OnBtnUseClick()
    local allRoleIds = XTRPGConfigs.GetAllRoleIds()
    local roleId = allRoleIds[self.SelectCharacter]
    XDataCenter.TRPGManager.RequestUseItemRequestSend(self.ItemId, 1, roleId, self.Cb)
    self:Close()
end

function XUiTRPGItemUsePanel:ButtonGroupSkip(groupIndex)
    if self.SelectCharacter == groupIndex then return end

    local allRoleIds = XTRPGConfigs.GetAllRoleIds()
    local roleId  = allRoleIds[groupIndex]
    local isRoleOwn = XDataCenter.TRPGManager.IsRoleOwn(roleId)
    if not isRoleOwn then return end

    self.SelectCharacter = groupIndex
    self:UpdateBuff()
end

function XUiTRPGItemUsePanel:Open(itemId)
    self.RootUi:PlayAnimation("AnimPanelPickEnable")
    self.ItemId = itemId
    self:Refresh()
    self.GameObject:SetActiveEx(true)
    self:SelectOwnCharacter()
end

function XUiTRPGItemUsePanel:SelectOwnCharacter()
    local allRoleIds = XTRPGConfigs.GetAllRoleIds()
    local roleId
    for i = 1, HeadMaxNum do
        roleId = allRoleIds[i]
        if XDataCenter.TRPGManager.IsRoleOwn(roleId) then
            self.PanelHead:SelectIndex(i)
            return
        end
    end
end

function XUiTRPGItemUsePanel:Refresh()
    local ownItemCount = XDataCenter.ItemManager.GetCount(self.ItemId)
    self.TxtCount.text = CSXTextManagerGetText("TRPGUseNum", 1)
    self.TextDesc.text = XDataCenter.ItemManager.GetItemDescription(self.ItemId)
    self.TextOwn.text = CSXTextManagerGetText("TRPGHaveDesc", ownItemCount)

    local quality = XDataCenter.ItemManager.GetItemQuality(self.ItemId)
    local qualityPath = XArrangeConfigs.GeQualityPath(quality)
    self.RootUi:SetUiSprite(self.ImgQuality, qualityPath)

    local itemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.ItemId)
    self.RImgIcon:SetRawImage(itemIcon)

    self:UpdateHead()
end

function XUiTRPGItemUsePanel:UpdateHead()
    local isRoleOwn
    local allRoleIds = XTRPGConfigs.GetAllRoleIds()
    local roleId
    for i = 1, HeadMaxNum do
        roleId = allRoleIds[i]
        isRoleOwn = XDataCenter.TRPGManager.IsRoleOwn(roleId)
        self.ButtonGroup[i]:SetDisable(not isRoleOwn)
        self:UpdateBuffTag(roleId, isRoleOwn, i)
    end
end

function XUiTRPGItemUsePanel:UpdateBuff()
    if not self.FuBenTRPGBuff or not self.PanelBuffContent then
        return
    end
    local allRoleIds = XTRPGConfigs.GetAllRoleIds()
    local roleId = allRoleIds[self.SelectCharacter]
    local buffIds = XDataCenter.TRPGManager.GetRoleBuffIds(roleId)
    local buffGrids = self.BuffGrids
    for index, buffId in pairs(buffIds) do
        local grid = buffGrids[index]
        if not grid then
            local ui = index == 1 and self.FuBenTRPGBuff or CSUnityEngineObjectInstantiate(self.FuBenTRPGBuff, self.PanelBuffContent)
            grid = XUiGridTRPGBuff.New(ui, self.RootUi)
            buffGrids[index] = grid
        end

        grid:Refresh(buffId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #buffIds + 1, #buffGrids do
        local grid = buffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiTRPGItemUsePanel:UpdateBuffTag(roleId, isRoleOwn, index)
    local imgUp = self["ImgUp" .. index]
    local imgDown = self["ImgDown" .. index]
    if not roleId or not isRoleOwn then
        if imgUp then
            imgUp.gameObject:SetActiveEx(false)
        end
        if imgDown then
            imgDown.gameObject:SetActiveEx(false)
        end
        return
    end

    local isUp = XDataCenter.TRPGManager.IsRoleHaveBuffUp(roleId)
    if imgUp then
        imgUp.gameObject:SetActiveEx(isUp)
    end
    local isDown = XDataCenter.TRPGManager.IsRoleHaveBuffDown(roleId)
    if imgDown then
        imgDown.gameObject:SetActiveEx(isDown)
    end
end

function XUiTRPGItemUsePanel:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiTRPGItemUsePanel