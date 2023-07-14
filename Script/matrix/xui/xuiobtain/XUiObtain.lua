local XUiObtain = XLuaUiManager.Register(XLuaUi, "UiObtain")

-- auto
-- Automatic generation of code, forbid to edit
function XUiObtain:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiObtain:AutoInitUi()
    self.ScrView = self.Transform:Find("SafeAreaContentPane/ScrView"):GetComponent("ScrollRect")
    self.PanelContent = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent")
    self.GridCommon = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent/GridCommon")
    self.BtnBack = self.Transform:Find("SafeAreaContentPane/BtnBack"):GetComponent("Button")
    self.TxtTitle = self.Transform:Find("SafeAreaContentPane/GameObject/TxtTitle1"):GetComponent("Text")
    self.BtnCancel = self.Transform:Find("SafeAreaContentPane/BtnCancel"):GetComponent("Button")
    self.BtnSure = self.Transform:Find("SafeAreaContentPane/BtnSure"):GetComponent("Button")
end

function XUiObtain:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiObtain:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick)
end
-- auto
--初始化音效
function XUiObtain:InitBtnSound()
    self.SpecialSoundMap[self:GetAutoKey(self.BtnBack, "onClick")] = XSoundManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnCancel, "onClick")] = XSoundManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnSure, "onClick")] = XSoundManager.UiBasicsMusic.Confirm
end

function XUiObtain:OnBtnCancelClick()
    self:Close()
    if self.CancelCallback then
        self.CancelCallback()
    end
    self:CheckItemOverLimit()
end

function XUiObtain:OnBtnSureClick()
    self:Close()
    if self.OkCallback then
        self.OkCallback()
    end
    self:CheckItemOverLimit()
end

function XUiObtain:OnBtnBackClick()
    self:Close()
    if self.CancelCallback then
        self.CancelCallback()
    end
    self:CheckItemOverLimit()
end

function XUiObtain:CheckItemOverLimit()
    --XUiManager.TipMsg(CS.XTextManager.GetText("ItemOverLimit"))
end

function XUiObtain:OnAwake()
    self:InitAutoScript()
    self:InitBtnSound()
end

--horizontalNormalizedPosition：水平滚动位置，以 0 到 1 之间的值表示，0 表示位于左侧
function XUiObtain:OnStart(rewardGoodsList, title, closeCb, sureCb, horizontalNormalizedPosition)
    self.Items = {}
    self.GridCommon.gameObject:SetActive(false)
    self.CancelBtnPosX = self.BtnCancel.transform.localPosition.x
    self.SureBtnPosX = self.BtnSure.transform.localPosition.x
    if title then
        self.TxtTitle.text = title
    end
    self.OkCallback = sureCb
    self.CancelCallback = closeCb
    self:Refresh(rewardGoodsList, horizontalNormalizedPosition)
    self:Layout()

    self:CheckIsTimelimitGood(rewardGoodsList)
    self:PlayAnimationAniObtain()
end

function XUiObtain:OnEnable()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Common_UiObtain)
    -- 避免弹窗弹得过快，显示ui的动画被打断
    local animTrans = self.Transform:Find("Animation/AniObtain")
    if animTrans then
        local dctor = animTrans:GetComponent("PlayableDirector")
        if dctor.time <= 0 then
            dctor:Play()
        end
    end
end

function XUiObtain:Layout()
    self.BtnSure.gameObject:SetActive(false)
    self.BtnCancel.gameObject:SetActive(false)
    local CancelBtnPosY = self.BtnCancel.transform.localPosition.y
    local SureBtnPosY = self.BtnSure.transform.localPosition.y

    if self.OkCallback and self.CancelCallback then
        self.BtnSure.gameObject:SetActive(true)
        self.BtnCancel.gameObject:SetActive(true)
        self.BtnCancel.transform.localPosition = CS.UnityEngine.Vector3(self.CancelBtnPosX, CancelBtnPosY, 0)
        self.BtnSure.transform.localPosition = CS.UnityEngine.Vector3(self.SureBtnPosX, SureBtnPosY, 0)
    elseif self.OkCallback then
        self.BtnSure.gameObject:SetActive(true)
        self.BtnSure.transform.localPosition = CS.UnityEngine.Vector3(0, SureBtnPosY, 0)
    elseif self.CancelCallback then
        self.BtnCancel.gameObject:SetActive(true)
        self.BtnCancel.transform.localPosition = CS.UnityEngine.Vector3(0, CancelBtnPosY, 0)
    end
end

function XUiObtain:Refresh(rewardGoodsList, horizontalNormalizedPosition)
    rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    XUiHelper.CreateTemplates(self, self.Items, rewardGoodsList, XUiGridCommon.New, self.GridCommon, self.PanelContent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)

    if horizontalNormalizedPosition then
        self.ScrView.horizontalNormalizedPosition = horizontalNormalizedPosition
    end
end

function XUiObtain:CheckIsTimelimitGood(rewardGoodsList)
    for _, good in pairs(rewardGoodsList) do
        if XArrangeConfigs.GetType(good.TemplateId) == XArrangeConfigs.Types.Item then -- 是道具
            local itemData = XDataCenter.ItemManager.GetItemTemplate(good.TemplateId)
            if itemData.SubTypeParams[1] and XArrangeConfigs.GetType(itemData.SubTypeParams[1]) == XArrangeConfigs.Types.WeaponFashion then -- 对应武器涂装
                if itemData.SubTypeParams[2] and itemData.SubTypeParams[2] > 0 then
                    XUiManager.TipMsg(CS.XTextManager.GetText("WeaponFashionLimitGetInBag", itemData.Name,XUiHelper.GetTime(itemData.SubTypeParams[2], XUiHelper.TimeFormatType.ACTIVITY)))
                    break
                end
            end
        end
    end
end

function XUiObtain:Close()
    self:EmitSignal("Close")
    XUiObtain.Super.Close(self)
end

function XUiObtain:PlayAnimationAniObtain()
    self:PlayAnimation("AniObtain")
end

return XUiObtain