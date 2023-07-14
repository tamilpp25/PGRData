--
-- Author: wujie
-- Note: 重复打开单选礼包界面中的子项，与XUiGridSelectGift区分，显示选择数量、长按将数量设置为0

XUiGridSelectReplicatedGift = XClass(XUiBagItem, "XUiGridSelectReplicatedGift")

--说明，以下修改为了适用于外部控制统一控制最大选择数量的情况

-- 初始化
function XUiGridSelectReplicatedGift:Ctor()
    self:ExtraInit()
end

function XUiGridSelectReplicatedGift:ExtraInit()
    self.TxtOwned = XUiHelper.TryGetComponent(self.Transform, "TxtOwned", "Text")
    -- 选择Transform
    self.ImgSelect = XUiHelper.TryGetComponent(self.Transform, "ImgSelect", nil)
    if self.BtnMinusSelect then
        self.XUiBtnMinusSelect = self.BtnMinusSelect.transform:GetComponent("XUiButton")
    end
end

function XUiGridSelectReplicatedGift:AddSelectCount()
    self:UpdateSelectCount(self.SelectCount + 1)
end

-- 选择操作接口,剔除由自身控制最大数量的判断，仅靠外部统一判断当前数量是否达到最大值
function XUiGridSelectReplicatedGift:UpdateSelectCount(count)
    local newCount = math.max(count, self.DefaultMinSelectCount)
    -- 此处来在外部进行最大数量的控制判断
    if self.SelectCountChangeCondition and not self.SelectCountChangeCondition(newCount) then
        return
    end

    if newCount == self.SelectCount then
        return
    end


    self:SetSelectCount(newCount)
end

-- 变更SetSelectState与OnSelectCountChanged调用顺序，便于外部控制一些状态
function XUiGridSelectReplicatedGift:SetSelectCount(newCount)
    local oldCount = self.SelectCount
    self.SelectCount = math.max(newCount, self.DefaultMinSelectCount)
    if self.BtnUse then
        self.BtnUse.interactable = newCount > 0
    end

    self:SetSelectState(newCount > self.DefaultMinSelectCount, true)
    if self.OnSelectCountChanged then
        self.OnSelectCountChanged(newCount - oldCount)
    end
end

-- 移除数量达到自身最大时禁止BtnAddSelect交互相关代码，由外部调用SetIsMaxCount控制是否达到最大值
function XUiGridSelectReplicatedGift:RefreshSelectState()
    if self.BtnMinusSelect then
        self.BtnMinusSelect.interactable = self.SelectState
        if self.SelectCount <= self.DefaultMinSelectCount then
            if (not self.IsShowBtnMinusWhenMinSelectCount) then
                self.BtnMinusSelect.gameObject:SetActive(false)
                -- 处理bug，长按减少按钮按钮隐藏时，按钮为按下状态，需要更改为普通状态
                if self.XUiBtnMinusSelect then
                    self.XUiBtnMinusSelect:SetButtonState(XUiButtonState.Normal)
                end
            end
        else
            self.BtnMinusSelect.gameObject:SetActive(true)
        end
    end

    if self.TxtSelect then
        self.TxtSelect.text = self.SelectCount
        if self.SelectCount == 0 then
            self.TxtSelect.text = ""
        end
    end

    if self.TxtSelectHide then
        self.TxtSelectHide.gameObject:SetActive(self.SelectState)
        if self.SelectState then
            self.TxtSelectHide.text = self.SelectCount
        end
    end

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActive(self.SelectState)
    end

    if self.ImgSelectBg then
        self.ImgSelectBg.gameObject:SetActive(self.SelectState)
    end

    if self.TxtNeedCount and self.NeedCount then
        if self.Data.Count >= self.NeedCount then
            self.TxtNeedCount.text = self.Data.Count .. "/" .. self.NeedCount
            if self.TxtHaveCount then
                self.TxtHaveCount.gameObject:SetActive(false)
            end
        else
            self.TxtNeedCount.text = "/" .. self.NeedCount
            if self.TxtHaveCount then
                self.TxtHaveCount.text = self.Data.Count
                self.TxtHaveCount.gameObject:SetActive(true)
            end
        end
    end
end

-- 主要是修改物品名字，当物品名字为角色时显示为全名
function XUiGridSelectReplicatedGift:RefreshSelf(NeedDefulatQulity, isSmallIcon, notCommonBg)
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

-- 策划新需求，长按一会儿将数量设置为0
function XUiGridSelectReplicatedGift:BtnMinusSelectLongClickCallback(time)
    if self.SelectCount == 0 then
        return
    end
    local count = self.SelectCount
    local longClickClearSelelctionTime = CS.XGame.ClientConfig:GetInt("SelectReplicatedGiftMinusBtnLongClickTime")
    if time > longClickClearSelelctionTime then
        count = 0
    else
        count = count - 1
        if count <= 0 then
            count = 0
        end
    end
    self:UpdateSelectCount(count)
end

-- 由外部统一判断是否达到总数量上限
function XUiGridSelectReplicatedGift:SetIsMaxCount(status)
    if self.BtnAddSelect then
        self.BtnAddSelect.interactable = not status
    end
end

function XUiGridSelectReplicatedGift:SetOwnedStatus(status)
    if self.TxtOwned then
        self.TxtOwned.gameObject:SetActiveEx(status)
    end
end