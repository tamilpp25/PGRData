local type = type

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

---@class XUiGridCommon
local XUiGridCommon = XClass(nil, "XUiGridCommon")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
---@param rootUi XLuaUi
function XUiGridCommon:Ctor(rootUi, ui)
    if not ui then
        ui = rootUi
    else
        ---@type XLuaUi
        self.RootUi = rootUi
    end

    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
    self.TextCount = XUiHelper.TryGetComponent(self.Transform, "TextCount", nil)
    self.ProxyClickFunc = nil
    self.CustomItemTipFunc = nil
    self._WeaopnFashionId = nil
    self._ShowWeaopnFashionDesc = nil
end

function XUiGridCommon:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridCommon:SetProxyClickFunc(value)
    self.ProxyClickFunc = value
end

function XUiGridCommon:SetCustomItemTip(value)
    self.CustomItemTipFunc = value
end

---【显示武器涂装】勾选框
function XUiGridCommon:SetCustomWeaopnFashionId(fashionId, desc)
    self._WeaopnFashionId = fashionId
    self._ShowWeaopnFashionDesc = desc
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
    if not self.TxtCount then self.TxtCount = XUiHelper.TryGetComponent(self.Transform, "ImgCountBg/TxtCount", "Text") end -- 兼容不同grid结构
    self.TxtName = XUiHelper.TryGetComponent(self.Transform, "TxtName", "Text")
    self.TxtHave = XUiHelper.TryGetComponent(self.Transform, "TxtHave", "Text")
    if not self.TxtHave then self.TxtHave = XUiHelper.TryGetComponent(self.Transform, "PanelTxt/TxtHave", "Text") end -- 兼容不同grid结构
    self.Bg = XUiHelper.TryGetComponent(self.Transform, "Bg", "Image")
    self.ImgNew = XUiHelper.TryGetComponent(self.Transform, "ImgNew", "Image")
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgIcon", "RawImage")
    self.HeadIconEffect = XUiHelper.TryGetComponent(self.Transform, "RImgIcon/Effect", "XUiEffectLayer")
    self.ImgQuality = XUiHelper.TryGetComponent(self.Transform, "ImgQuality", "Image")
    self.PanelFirst = XUiHelper.TryGetComponent(self.Transform, "PanelFirst", "Image")
    self.PanelSite = XUiHelper.TryGetComponent(self.Transform, "PanelSite", nil)
    self.TxtSite = XUiHelper.TryGetComponent(self.Transform, "PanelSite/TxtSite", "Text")
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "BtnClick", "Button")
    self.ImgUp = XUiHelper.TryGetComponent(self.Transform, "ImgUp", "Image")
    self.ImgRail = XUiHelper.TryGetComponent(self.Transform, "ImgRail", "Image")
    self.ImgReceived = XUiHelper.TryGetComponent(self.Transform, "ImgReceived", nil)
    self.ImgQualityTag = XUiHelper.TryGetComponent(self.Transform, "ImgQualityTag", "Image")
    self.TxtStock = XUiHelper.TryGetComponent(self.Transform, "TxtStock", "Text")
    self.ImgNone = XUiHelper.TryGetComponent(self.Transform, "ImgNone", nil)
    -- 特殊标记
    self.PanelTag = XUiHelper.TryGetComponent(self.Transform, "PanelTag")
    self.PanelDrawTag = XUiHelper.TryGetComponent(self.Transform, "PanelDrawTag")
    --赠品标记
    self.GiftTag = XUiHelper.TryGetComponent(self.Transform, "CoatingTips")
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
    --if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
    --    return
    --end

    if self.ProxyClickFunc then
        local continue = self.ProxyClickFunc()
        if not continue then
            return
        end
    end

    if self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Character then
        --从Tips的ui跳转需要关闭Tips的UI
        if self.RootUi and self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
            self.RootUi:Close()
        end

        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
        XLuaUiManager.Open("UiCharacterDetail", self.TemplateId)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
        XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(self.TemplateId)
        --从Tips的ui跳转需要关闭Tips的UI
        if self.RootUi and self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
            self.RootUi:Close()
        end

        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Furniture then
        local cfg = XFurnitureConfigs.GetFurnitureReward(self.TemplateId)
        local furnitureRewardId = self.TemplateId
        local configId = cfg.FurnitureId
        if self.Data then
            XLuaUiManager.Open("UiFurnitureDetail", self.Data.InstanceId, configId, furnitureRewardId, nil, true)
        else
            XLuaUiManager.Open("UiFurnitureDetail", nil, configId, furnitureRewardId, nil, true)
        end
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Fashion then
        local buyData = self:GetBuyData()
        -- WeaopnFashionId如果有值，则在界面左下角显示一个勾选框，勾选后显示该自定义武器涂装
        XLuaUiManager.Open("UiFashionDetail", self.TemplateId, false, buyData, nil, nil, self._WeaopnFashionId, self._ShowWeaopnFashionDesc)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Partner then
        --从Tips的ui跳转需要关闭Tips的UI
        if self.RootUi and self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
            self.RootUi:Close()
        end
        -- 暂停自动弹窗
        XDataCenter.AutoWindowManager.StopAutoWindow()

        local partnerData = { Id = 0, TemplateId = self.TemplateId }
        local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
        XLuaUiManager.Open("UiPartnerPreview", partner)

    elseif XDataCenter.ItemManager.IsWeaponFashion(self.TemplateId) then
        local buyData = self:GetBuyData()
        local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(self.TemplateId)
        XLuaUiManager.Open("UiFashionDetail", weaponFashionId, true, buyData)
    elseif self.GoodsShowParams.RewardType == XArrangeConfigs.Types.WeaponFashion then
        XLuaUiManager.Open("UiFashionDetail", self.TemplateId, true, self:GetBuyData())
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Nameplate then
        XLuaUiManager.Open("UiNameplateTip", self.TemplateId, true, true, true)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Medal then
        XLuaUiManager.Open("UiMeadalDetail", self.GoodsShowParams.Config, XDataCenter.MedalManager.Preview)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Background then    -- v1.29 场景预览
        XLuaUiManager.Open("UiSceneTip", self.TemplateId)
    elseif self.GoodsShowParams.RewardType == XRewardManager.XRewardType.DlcHuntChip then    -- DLC
        local itemId = self.TemplateId
        if XDlcHuntChipConfigs.IsExist(itemId) then
            local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")
            ---@type XDlcHuntChip
            local virtualChip = XDlcHuntChip.New()
            virtualChip:SetData({
                Id = -1,
                TemplateId = itemId,
                Level = 1,
                Exp = 0,
                Breakthrough = 0,
                IsLock = false,
                CreateTime = 0
            })
            XLuaUiManager.Open("UiDlcHuntChipDetails", virtualChip)
        else
            XLuaUiManager.Open("UiDlcHuntTip", self.Data and self.Data or self.TemplateId, self.HideSkipBtn, self.RootUi and self.RootUi.Name, self.LackNum)
        end
        
    else
        if self.CustomItemTipFunc then
            self.CustomItemTipFunc(self.Data and self.Data or self.TemplateId, self.HideSkipBtn, self.RootUi and self.RootUi.Name, self.LackNum)
            return
        end
        XLuaUiManager.Open("UiTip", self.Data and self.Data or self.TemplateId, self.HideSkipBtn, self.RootUi and self.RootUi.Name, self.LackNum)
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
    self.GameObject:SetActiveEx(data ~= nil)
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
    self.GoodsShowParams = self:GetGoodsShowParams()
    if not self.GoodsShowParams then
        XLog.Error("获取道具数据有误，Data :", data)
        return
    end
    -- 如果Data是下发的XRewardGoods（关联RewardGoods.tab）希望能使配置自定义品质的功能生效
    if type(self.Data) == "table" then
        if XTool.IsNumberValid(self.Data.Quality) then
            self.GoodsShowParams.Quality = self.Data.Quality
        end
    end
    
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
        self.LackNum = costCount - count --记录缺少数量
        self:SetUiActive(self.TxtHaveCount, true)
        self:SetUiActive(self.TxtNeedCount, true)
    end

    -- 图标
    if self.RImgIcon then
        local icon = self.GoodsShowParams.Icon
        if isBigIcon and self.GoodsShowParams.BigIcon then
            icon = self.GoodsShowParams.BigIcon
        end

        if icon and #icon > 0 and self.GoodsShowParams.RewardType ~= XRewardManager.XRewardType.Nameplate then
            --self.RootUi:SetUiSprite(self.RImgIcon, icon)
            self.RImgIcon:SetRawImage(icon)
            self:SetUiActive(self.RImgIcon, true)
        end
        if self.GoodsShowParams.IsShowMedalEffect then
            XDataCenter.MedalManager.LoadMedalEffect(self, self.RImgIcon, self.Data.TemplateId)
        elseif not XTool.UObjIsNil(self.MedalEffectPrefab) then
            self.MedalEffectPrefab.gameObject:SetActiveEx(false)
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

        if self.RootUi and qualityIcon then
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
            self:SetUiActive(self.PanelSite, self.GoodsShowParams.Site ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON)
            self.TxtSite.text = "0" .. self.GoodsShowParams.Site
        end
    end
    --铭牌
    self:RefreshNameplate()
    
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
    
    --赠品
    if self.GiftTag then
        if not XTool.IsTableEmpty(self.Data) then
            self.GiftTag.gameObject:SetActiveEx(self.Data.IsGift and true or false)
        else
            self.GiftTag.gameObject:SetActiveEx(false)
        end
    end
    self:RefreshLabel()
    --清除临时的同步数据
    self:ClearSynData()
end

function XUiGridCommon:ShowIcon(icon)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
        self.RImgIcon.gameObject:SetActiveEx(true)
    end
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

function XUiGridCommon:SetPanelFirst(isFirst)
    if self.PanelFirst then
        self.PanelFirst.gameObject:SetActiveEx(isFirst)
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

function XUiGridCommon:SetPanelTag(isTag)
    if self.PanelTag then
        self.PanelTag.gameObject:SetActiveEx(isTag)
    end
end

function XUiGridCommon:SetPanelDrawTag(isTag)
    if self.PanelDrawTag then
        self.PanelDrawTag.gameObject:SetActiveEx(isTag)
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

function XUiGridCommon:SetName(value)
    if not self.TxtName then return end
    self.TxtName.text = value
end

function XUiGridCommon:SetNeedCount(value)
    if self.TxtNeedCount then
        self.TxtNeedCount.text = value
    end
end

function XUiGridCommon:SetCount(value)
    if self.TxtCount then
        self.TxtCount.text = value
        self:SetUiActive(self.TxtCount, true)
    end
end
--============
--获取物品显示数据
--============
function XUiGridCommon:GetGoodsShowParams()
    if not self.TemplateId then
        XLog.Error("错误日志：显示的道具数据TemplateId为空！")
        return
    end
    local templateType = self.Data and self.Data.RewardType and self:GetRewardType(self.Data.RewardType) or "Default"
    return self["Get" .. templateType .. "GoodsShowParams"](self)
end

function XUiGridCommon:GetRewardType(rewardType)
    --===============
    --XRewardType <=> 道具数据类型
    --===============
    if rewardType == XRewardManager.XRewardType.Medal then
        return "Medal"
    end
    return "Default"
end

--=============
--获取一般道具显示数据(默认项)
--=============
function XUiGridCommon:GetDefaultGoodsShowParams()
    return XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TemplateId)
end
--=============
--获取勋章显示数据
--=============
function XUiGridCommon:GetMedalGoodsShowParams()
    --勋章的物品数据中，用TemplateId代替了表中的Params[0]，即勋章Id
    local medal = XDataCenter.MedalManager.GetMedalById(self.Data.TemplateId)
    if not medal then return end
    local goodsShowParams = {
        Name = medal.Name,
        Icon = medal.MedalImg,
        IsShowMedalEffect = true,
        Config = medal,
        RewardType = XRewardManager.XRewardType.Medal
    }
    return goodsShowParams
end

function XUiGridCommon:RefreshNameplate()
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
            local rectTransform = prefab.transform:GetComponent("RectTransform")
            if rectTransform then
                local vX = 0
                local vY = 15
                local scale = CS.UnityEngine.Vector3(0.6, 0.6, 0.6)
                if self.Bg then
                    local tmpTrans = self.Bg:GetComponent("RectTransform")
                    local vect = tmpTrans.anchoredPosition
                    rectTransform.anchorMin = tmpTrans.anchorMin
                    rectTransform.anchorMax = tmpTrans.anchorMax
                    vX = vect.x
                    vY = vect.y
                    local bgX= self.Bg:GetComponent("RectTransform").sizeDelta.x
                    local bgScale = self.Bg.transform.localScale.x
                    local realBgWidth = bgX * bgScale
                    local tempX = rectTransform.sizeDelta.x
                    local scaleNum = 0.9 * realBgWidth/tempX
                    scale = CS.UnityEngine.Vector3(scaleNum, scaleNum, scaleNum)  -- 铭牌大小为标准背景宽高的90%防止超出格子
                end
                rectTransform.anchoredPosition = CS.UnityEngine.Vector2(vX, vY)
                rectTransform.localScale = scale
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
end

function XUiGridCommon:SetNameplateEffectActive(isActive)
    if self.PanelNamePlate then
        self.PanelNamePlate:SetEffectActive(isActive)
    end
end

function XUiGridCommon:RefreshLabel()
    if self.GoodsLabel then
        self.GoodsLabel:Close()
    end
    if XTool.IsTableEmpty(self.GoodsShowParams) then
        return
    end
    local templateId = self.GoodsShowParams.TemplateId
    if not XUiConfigs.CheckHasLabel(templateId) then
        return
    end
    if not self.GoodsLabel then
        self.GoodsLabel = XUiHelper.CreateGoodsLabel(templateId, self.Transform, self.PanelPet)
    end
    self.GoodsLabel:Refresh(templateId, self.PanelPet ~= nil)
end

function XUiGridCommon:GetBuyData()
    local buyData
    if self.Data and self.Data.ItemCount and self.Data.ItemIcon and self.Data.BuyCallBack then
        buyData = {}
        local isHave, isLimitTime = XRewardManager.CheckRewardOwn(self.GoodsShowParams.RewardType, self.GoodsShowParams.TemplateId)
        buyData.IsHave = isHave and not isLimitTime
        buyData.ItemIcon = self.Data.ItemIcon
        buyData.ItemCount = self.Data.ItemCount
        buyData.GiftRewardId = self.Data.GiftRewardId
        buyData.BuyCallBack = self.Data.BuyCallBack

        if not XTool.IsTableEmpty(self._BuyDataCustomParams) then
            for k, v in pairs(self._BuyDataCustomParams) do
                buyData[k] = v
            end
        end
    end
    
    return buyData
end

function XUiGridCommon:SetQualityShowCustom(quality)
    -- 品质底图
    if self.ImgQuality then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, quality)

        self:SetUiActive(self.ImgQuality, true)
    end

    -- 品质底图（大）
    if self.ImgIconQuality then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconQuality, quality)
        self:SetUiActive(self.ImgQuality, true)
    end
end

function XUiGridCommon:SetBuyDataCustomParams(params)
    self._BuyDataCustomParams = params
end

return XUiGridCommon