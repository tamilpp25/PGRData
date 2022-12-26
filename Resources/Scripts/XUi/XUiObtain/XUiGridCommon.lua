local type = type

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

XUiGridCommon = XClass(nil, "XUiGridCommon")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
function XUiGridCommon:Ctor(rootUi, ui)
    if not ui then
        ui = rootUi
    else
        self.RootUi = rootUi
    end

    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
    self.TextCount = XUiHelper.TryGetComponent(self.Transform, "TextCount", nil)
end

function XUiGridCommon:Init(rootUi)
    self.RootUi = rootUi
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridCommon:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridCommon:AutoInitUi()
    self.TxtCount = XUiHelper.TryGetComponent(self.Transform, "TxtCount", "Text")
    if not self.TxtCount then self.TxtCount = XUiHelper.TryGetComponent(self.Transform, "PanelTxt/TxtCount", "Text") end -- 兼容不同grid结构
    self.TxtName = XUiHelper.TryGetComponent(self.Transform, "TxtName", "Text")
    self.TxtHave = XUiHelper.TryGetComponent(self.Transform, "TxtHave", "Text")
    if not self.TxtHave then self.TxtHave = XUiHelper.TryGetComponent(self.Transform, "PanelTxt/TxtHave", "Text") end -- 兼容不同grid结构
    self.ImgNew = XUiHelper.TryGetComponent(self.Transform, "ImgNew", "Image")
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgIcon", "RawImage")
    self.HeadIconEffect = XUiHelper.TryGetComponent(self.Transform, "RImgIcon/Effect", "XUiEffectLayer")
    self.ImgQuality = XUiHelper.TryGetComponent(self.Transform, "ImgQuality", "Image")
    self.PanelSite = XUiHelper.TryGetComponent(self.Transform, "PanelSite", nil)
    self.TxtSite = XUiHelper.TryGetComponent(self.Transform, "PanelSite/TxtSite", "Text")
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "BtnClick", "Button")
    self.ImgUp = XUiHelper.TryGetComponent(self.Transform, "ImgUp", "Image")
    self.ImgRail = XUiHelper.TryGetComponent(self.Transform, "ImgRail", "Image")
    self.ImgReceived = XUiHelper.TryGetComponent(self.Transform, "ImgReceived", "Image")
    self.ImgQualityTag = XUiHelper.TryGetComponent(self.Transform, "ImgQualityTag", "Image")
    self.TxtStock = XUiHelper.TryGetComponent(self.Transform, "TxtStock", "Text")
    self.ImgNone = XUiHelper.TryGetComponent(self.Transform, "ImgNone", nil)
end

function XUiGridCommon:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
end

function XUiGridCommon:SetBtnNotClick(statue)
    self.BtnNotClick = statue
end

-- auto
function XUiGridCommon:OnBtnClickClick()
    if self.Disable or self.BtnNotClick then
        return
    end
    -- 匹配中
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    if self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Character then
        --从Tips的ui跳转需要关闭Tips的UI
        if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
            self.RootUi:Close()
        end

        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
        XLuaUiManager.Open("UiCharacterDetail", self.TemplateId)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
        XLuaUiManager.Open("UiEquipDetail", self.TemplateId, true)
        --从Tips的ui跳转需要关闭Tips的UI
        if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
            self.RootUi:Close()
        end

        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Furniture then
        local cfg = XFurnitureConfigs.GetFurnitureReward(self.TemplateId)
        local furnitureRewardId = self.TemplateId
        local configId = cfg.FurnitureId
        XLuaUiManager.Open("UiFurnitureDetail", self.Data.InstanceId, configId, furnitureRewardId, nil, true)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Fashion then
        local buyData
        if self.Data and self.Data.ItemCount and self.Data.ItemIcon and self.Data.BuyCallBack then
            buyData = {}
            local isHave, isLimitTime = XRewardManager.CheckRewardOwn(self.GoodsShowParams.RewardType, self.GoodsShowParams.TemplateId)
            buyData.IsHave = isHave and not isLimitTime
            buyData.ItemIcon = self.Data.ItemIcon
            buyData.ItemCount = self.Data.ItemCount
            buyData.BuyCallBack = self.Data.BuyCallBack
        end
        XLuaUiManager.Open("UiFashionDetail", self.TemplateId, false, buyData)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Partner then
        --从Tips的ui跳转需要关闭Tips的UI
        if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
            self.RootUi:Close()
        end
        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
        
        local partnerData = {Id = 0,TemplateId = self.TemplateId}
        local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
        XLuaUiManager.Open("UiPartnerPreview", partner)
        
    elseif XDataCenter.ItemManager.IsWeaponFashion(self.TemplateId) then
        local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(self.TemplateId)
        XLuaUiManager.Open("UiFashionDetail", weaponFashionId, true)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Nameplate then
        XLuaUiManager.Open("UiNameplateTip", self.TemplateId, true, true)
    else
        XLuaUiManager.Open("UiTip", self.Data and self.Data or self.TemplateId, self.HideSkipBtn, self.RootUi.Name)
    end
end

function XUiGridCommon:SetUiActive(ui, active)
    if not ui or not ui.gameObject then
        return
    end

    if ui.gameObject.activeSelf == active then
        return
    end

    ui.gameObject:SetActiveEx(active)
end

function XUiGridCommon:ResetUi()
    self:SetUiActive(self.TxtCount, false)
    self:SetUiActive(self.TxtName, false)
    self:SetUiActive(self.ImgNew, false)
    self:SetUiActive(self.RImgIcon, false)
    self:SetUiActive(self.ImgQuality, false)
    self:SetUiActive(self.PanelSite, false)
    self:SetUiActive(self.ImgUp, false)
    self:SetUiActive(self.ImgRail, false)
    self:SetUiActive(self.ImgReceived, false)
    self:SetUiActive(self.ImgQualityTag, false)
    self:SetUiActive(self.IconLevel, false)
    self:SetUiActive(self.TxtHave, false)
    self:SetUiActive(self.TxtStock, false)
    self:SetUiActive(self.ImgNone, false)
end

-- data支持数据结构： XEquipData XItemData XCharacterData
-- tags可包含: { ShowUp, ShowNew }
function XUiGridCommon:Refresh(data, params, isBigIcon, hideSkipBtn, curCount)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.GameObject:SetActiveEx(data)
    if not data then
        return
    end

    self:ResetUi()

    self.HideSkipBtn = hideSkipBtn

    local count, costCount

    if type(data) == "number" then
        self.TemplateId = data
    else
        self.Data = data
        self.TemplateId = (data.TemplateId and data.TemplateId > 0) and data.TemplateId or data.Id
        count = data.Count
        costCount = data.CostCount
    end

    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TemplateId)

    params = params or {}

    -- 名字
    if self.TxtName and self.GoodsShowParams.Name then
        if self.GoodsShowParams.RewardType == XArrangeConfigs.Types.Character then
            self.TxtName.text = self.GoodsShowParams.TradeName
        else
            self.TxtName.text = self.GoodsShowParams.Name
        end

        self:SetUiActive(self.TxtName, true)
    end

    -- 数量
    if self.TxtCount and count then
        self.TxtCount.text = CS.XTextManager.GetText("ShopGridCommonCount", count)
        self:SetUiActive(self.TxtCount, true)
    end

    -- 可消耗数量
    if self.TxtHaveCount and count and self.TxtNeedCount and costCount then
        self.TxtHaveCount.text = count
        self.TxtNeedCount.text = "/" .. costCount
        self.TxtHaveCount.color = CONDITION_COLOR[count >= costCount]
        self:SetUiActive(self.TxtHaveCount, true)
        self:SetUiActive(self.TxtNeedCount, true)
    end

    -- 图标
    if self.RImgIcon then
        local icon = self.GoodsShowParams.Icon
        if isBigIcon and self.GoodsShowParams.BigIcon then
            icon = self.GoodsShowParams.BigIcon
        end

        if icon and #icon > 0 then
            --self.RootUi:SetUiSprite(self.RImgIcon, icon)
            self.RImgIcon:SetRawImage(icon)
            self:SetUiActive(self.RImgIcon, true)
        end
    end

    -- 特效
    if self.HeadIconEffect then
        local effect = self.GoodsShowParams.Effect
        if effect then
            self.HeadIconEffect.gameObject:LoadPrefab(effect)
            self.HeadIconEffect.gameObject:SetActiveEx(true)
        else
            self.HeadIconEffect.gameObject:SetActiveEx(false)
        end
    end

    -- 品质底图
    if self.ImgQuality and self.GoodsShowParams.Quality then
        local qualityIcon = self.GoodsShowParams.QualityIcon

        if qualityIcon then
            self.RootUi:SetUiSprite(self.ImgQuality, qualityIcon)
        else
            XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, self.SyncQuality or self.GoodsShowParams.Quality)
        end

        self:SetUiActive(self.ImgQuality, true)
    end

    -- 品质底图（大）
    if self.ImgIconQuality and self.GoodsShowParams.Quality then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconQuality, self.SyncQuality or self.GoodsShowParams.Quality)
        self:SetUiActive(self.ImgQuality, true)
    end

    -- 创世纪标签
    if self.ImgQualityTag and self.GoodsShowParams.QualityTag then
        self:SetUiActive(self.ImgQualityTag, true)
    end

    if self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
        -- 星数
        if self.PanelStars then
            self:ShowStar(self.GoodsShowParams.Star, self.GoodsShowParams.Star)
        end
        --
        if self.PanelSite then
            self:SetUiActive(self.PanelSite, self.GoodsShowParams.Site ~= XEquipConfig.EquipSite.Weapon)
            self.TxtSite.text = "0" .. self.GoodsShowParams.Site
        end
    end
    --铭牌
    if self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Nameplate then
        self:SetUiActive(self.ImgQuality, false)
        self:SetUiActive(self.RImgIcon, false)
        local BtnSiblingIndex = 0
        if self.BtnClick then
            BtnSiblingIndex = self.BtnClick.transform:GetSiblingIndex()
        end

        if not self.PanelNamePlate then
            local prefab = self.GameObject:LoadPrefab(XMedalConfigs.XNameplatePanelPath)
            prefab.transform:SetSiblingIndex(BtnSiblingIndex)
            local rectTransform =  prefab.transform:GetComponent("RectTransform")
            if rectTransform then
                rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
                rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
                rectTransform.anchoredPosition = CS.UnityEngine.Vector2(0, 15)
                rectTransform.localScale = CS.UnityEngine.Vector3(0.8, 0.8, 0.8)
            end
            self.PanelNamePlate = XUiPanelNameplate.New(prefab, self.RootUi)
        end
        self.PanelNamePlate.GameObject:SetActiveEx(true)
        self.PanelNamePlate:UpdateDataById(self.TemplateId)
    else
        if self.PanelNamePlate then
            self.PanelNamePlate.GameObject:SetActiveEx(false)
        else
            local prefab = self.GameObject:LoadPrefab(XMedalConfigs.XNameplatePanelPath)
            prefab.gameObject:SetActiveEx(false)
        end
    end
    -- 特殊 : Params
    -- Params.ShowUp
    if self.ImgUp then
        self:SetUiActive(self.ImgUp, params.ShowUp)
    end

    -- Params.ShowNew
    if self.ImgNew then
        self:SetUiActive(self.ImgNew, params.ShowNew)
    end

    -- Params.ShowReceived 已领取
    if self.ImgReceived then
        self:SetUiActive(self.ImgReceived, params.ShowReceived)
    end

    -- Params.Disable 不可点击
    self.Disable = params.Disable

    --特殊抽奖中奖品的剩余数
    if self.TxtStock then
        if curCount then
            self.TxtStock.text = CS.XTextManager.GetText("ResidueStockText", curCount)
            self:SetUiActive(self.TxtStock, true) 
        end
        self:SetUiActive(self.TxtName, false)
    end

    --特殊抽奖中是否有库存的提示
    if self.ImgNone then
        self:SetUiActive(self.ImgNone, curCount and curCount <= 0)
    end

    --收藏品等级
    if self.IconLevel and self.GoodsShowParams.LevelIcon then
        local levelIcon = self.SyncLevelIcon or self.GoodsShowParams.LevelIcon
        if levelIcon then
            self.RootUi:SetUiSprite(self.IconLevel, levelIcon)
            self:SetUiActive(self.IconLevel, true)
        end
    end

    --是否已拥有
    if self.TxtHave then
        local isHave, isLimitTime = XRewardManager.CheckRewardOwn(self.GoodsShowParams.RewardType, self.GoodsShowParams.TemplateId)
        local isShowTextHave = isHave and not isLimitTime
        self:SetUiActive(self.TxtHave, isShowTextHave)
        self:SetUiActive(self.TxtCount, not isShowTextHave)
    end

    --清除临时的同步数据
    self:ClearSynData()
end

function XUiGridCommon:ShowCount(show)
    if (self.TxtCount) then
        self.TxtCount.gameObject:SetActiveEx(show)
    end
    if self.TextCount then
        self.TextCount.gameObject:SetActiveEx(show)
    end
end

function XUiGridCommon:ShowStar(count, max)
    local showStar = max > 0
    self.PanelStars.gameObject:SetActiveEx(showStar)

    if not showStar then
        return
    end

    for i = 1, 6 do
        local starPanel = self["PanelStar" .. i]
        if starPanel then
            starPanel.gameObject:SetActiveEx(i <= max)
        end

        local imgStar = self["ImgStar" .. i]
        if imgStar then
            imgStar.gameObject:SetActiveEx(i <= count)
        end
    end
end

function XUiGridCommon:SetReceived(isReceive)
    if self.ImgReceived then
        self:SetUiActive(self.ImgReceived, isReceive)
    end
end

function XUiGridCommon:SetShowUp(isShow)
    if self.ImgUp then
        self:SetUiActive(self.ImgUp, isShow)
    end
end

function XUiGridCommon:SetUpText(text)
    if self.UpText then
        self.UpText.text = text
    end
end

function XUiGridCommon:SetUpImg(img)
    if self.ImgUp then
        self.ImgUp:SetRawImage(img)
    end
end

function XUiGridCommon:SetClickCallback(callback)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, callback, true)
end

function XUiGridCommon:SetSyncQuality(quality)
    self.SyncQuality = quality
end

function XUiGridCommon:SetSyncLevelIcon(levelIcon)
    self.SyncLevelIcon = levelIcon
end

function XUiGridCommon:ClearSynData()
    self.SyncQuality = nil
    self.SyncLevelIcon = nil
end

function XUiGridCommon:GetQuality()
    return self.GoodsShowParams.Quality
end

return XUiGridCommon