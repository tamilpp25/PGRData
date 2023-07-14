--
-- Author: wujie
-- Note: 重复打开单选礼包界面中的子项，与XUiBagItem多了显示人物全名、拥有状态

XUiGridSelectGift = XClass(XUiBagItem, "XUiGridSelectGift")

--说明，以下修改为了适用于外部控制统一控制最大选择数量的情况

-- 初始化
function XUiGridSelectGift:Ctor()
    self:ExtraInit()
end

function XUiGridSelectGift:ExtraInit()
    self.TxtOwned = XUiHelper.TryGetComponent(self.Transform, "TxtOwned", "Text")
    -- 选择Transform
    self.ImgSelect = XUiHelper.TryGetComponent(self.Transform, "ImgSelect", nil)
end

-- 主要是修改物品名字，当物品名字为角色时显示为全名
function XUiGridSelectGift:RefreshSelf(NeedDefulatQulity, isSmallIcon, notCommonBg)
    if self.BtnUse then
        local isUseable = XDataCenter.ItemManager.IsUseable(self.TemplateId)
        self.BtnUse.gameObject:SetActive(isUseable)
        self.BtnUse.interactable = self.SelectCount > 0
    end

    if self.ImgCanUse then
        local isUseable = XDataCenter.ItemManager.IsUseable(self.TemplateId)
        self.ImgCanUse.gameObject:SetActive(isUseable)
    end

    if self.BtnOk then
        local isUseable = XDataCenter.ItemManager.IsUseable(self.TemplateId)
        self.BtnOk.gameObject:SetActive(not isUseable)
    end

    self:RefreshSelfCount()

    local template = self.Template
    if self.TxtName then
        --对人物显示全名
        if self.Template.RewardType == XRewardManager.XRewardType.Character then
            self.TxtName.text = XCharacterConfigs.GetCharacterFullNameStr(self.TemplateId)
        else
            self.TxtName.text = template.Name
        end
    end

    if self.TxtDescription then
        self.TxtDescription.text = template.Description
    end

    if self.TxtWorldDesc then
        self.TxtWorldDesc.text = template.WorldDesc
    end

    if self.TxtUseLevel then
        self.TxtUseLevel.text = CS.XTextManager.GetText("CharacterUpgradeSkillConsumeTitle") .. "Lv." .. template.UseLevel
    end

    if self.TxtCount and self.Data.Count ~= nil then
        self.TxtCount.text = self.Data.Count
    end

    if self.RImgIcon and isSmallIcon then
        self.RImgIcon:SetRawImage(template.Icon)
    elseif self.RImgIcon and not isSmallIcon then
        self.RImgIcon:SetRawImage(template.BigIcon)
    end

    local quality = template.Quality

    -- 角色品质背景特殊处理
    if template.RewardType == XRewardManager.XRewardType.Character then
        quality = quality < 3 and 5 or 6
    end
    
    -- 宠物品质背景特殊处理
    if template.RewardType == XRewardManager.XRewardType.Partner then
        quality = quality < 3 and 5 or 6
    end

    if self.ImgIconBg then
        if self.BtnGet or notCommonBg then
            XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconBg, quality)
        else
            self.RootUi:SetUiSprite(self.ImgIconBg, XArrangeConfigs.GeQualityBgPath(quality))
        end
    end

    if self.ImgIconQuality then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconQuality, quality)
    end

    if NeedDefulatQulity and self.ImgIconBg then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconBg, quality)
    end

    if self.ImgState then
        local sprite = nil
        local text = ""

        if XDataCenter.ItemManager.IsCanConvert(self.TemplateId) then
            sprite = XUiHelper.TagBgPath.Blue
            text = CS.XTextManager.GetText("ItemCanConvert")
        elseif XDataCenter.ItemManager.IsTimeLimit(self.TemplateId) then
            local leftTime = self.RecycleBatch and self.RecycleBatch.RecycleTime - XTime.GetServerNowTimestamp()
            or XDataCenter.ItemManager.GetRecycleLeftTime(self.Data.Id)
            text, sprite = XUiHelper.GetBagTimeLimitTimeStrAndBg(leftTime)
        end

        if sprite then
            self.RootUi:SetUiSprite(self.ImgState, sprite)
            self.ImgState.gameObject:SetActive(true)
        else
            self.ImgState.gameObject:SetActive(false)
        end

        if text then
            self.TxtState.text = text
            self.TxtState.gameObject:SetActive(true)
        else
            self.TxtState.gameObject:SetActive(false)
        end
    end

    if self.RefreshCallback then
        self.RefreshCallback()
    end
end

function XUiGridSelectGift:SetOwnedStatus(status)
    if self.TxtOwned then
        self.TxtOwned.gameObject:SetActiveEx(status)
    end
end