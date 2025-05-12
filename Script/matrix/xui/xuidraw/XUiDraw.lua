local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiDraw = XLuaUiManager.Register(XLuaUi, "UiDraw")
local drawControl = require("XUi/XUiDraw/XUiDrawControl")
local XUiGridSuitDetail = require("XUi/XUiEquipAwarenessReplace/XUiGridSuitDetail")
local gridParams = { ShowUp = true }
local IndexBaseRule = 1
local IndexPreview = 2
local IndexEventRule = 4
function XUiDraw:OnAwake()
    self:InitAutoScript()
end

function XUiDraw:OnStart(groupId, closeCb, backGround)
    self.GroupId = groupId
    self.CloseCb = closeCb
    self.BackGroundPath = backGround
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.UpShows = {}
    self.UpSuitShows = {}
    self.BottomInfoTxts = {}

    self.FirstAnim = true
    self.FirstAutoOpen = true
    local upShow = XUiGridCommon.New(self, self.GridCommon)
    table.insert(self.UpShows, upShow)
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(groupId)
    self.DrawControl = drawControl.New(self, drawInfo, function()
            self:UpdateItemCount()
        end, self)
    self:UpdateInfo(drawInfo)
    self.ImgMask.gameObject:SetActiveEx(false)
    self:LoadMainRule()
    self:UpdateResetTime()
    self:InitDrawBackGround(self.BackGroundPath)
    self.PanelCharacterBottomInfo.gameObject:SetActiveEx(false)
end

function XUiDraw:OnDestroy()
    XCountDown.RemoveTimer(self.Name)
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiDraw:OnEnable()
    XUiHelper.SetDelayPopupFirstGet(true)
    self.ImgMask.gameObject:SetActiveEx(true)
    self:PlayAnimation("DrawBegan", function()
            self.ImgMask.gameObject:SetActiveEx(false)
            self:ShowExtraReward(function ()
                    self:CheckAutoOpen()
                end)
        end)
    self:PlaySpcalAnime()
    self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    self.PlayableDirector:Stop()
    self.PlayableDirector:Evaluate()
end

function XUiDraw:LoadMainRule()
    local groupRule = XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId)
    self.TxtTitle.text = groupRule.TitleCN
    local mainRules = groupRule.MainRules
    local mainRule = mainRules[1]
    for i = 2, #mainRules do
        mainRule = mainRule .. "\n" .. mainRules[i]
    end
    self.TxtDesc.text = mainRule
end

function XUiDraw:UpdateResetTime()
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    if groupInfo and groupInfo.EndTime > 0 then
        local remainTime = groupInfo.EndTime - XTime.GetServerNowTimestamp()
        XCountDown.CreateTimer(self.GameObject.name, remainTime)
        XCountDown.BindTimer(self.GameObject, self.GameObject.name, function(v)
                if groupInfo.Type == XDataCenter.DrawManager.DrawEventType.Activity then
                    self.TxtRemainTime.text = CS.XTextManager.GetText("DrawResetTimeActivity", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.DRAW))
                elseif groupInfo.Type == XDataCenter.DrawManager.DrawEventType.OldActivity then
                    self.TxtRemainTime.text = CS.XTextManager.GetText("DrawResetTimeOldActivity", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.DRAW))
                else
                    self.TxtRemainTime.text = CS.XTextManager.GetText("DrawResetTime", XUiHelper.GetTime(v, XUiHelper.TimeFormatType.DRAW))
                end
            end)
        self.TxtRemainTime.gameObject:SetActiveEx(false)
    else
        self.TxtRemainTime.gameObject:SetActiveEx(false)
    end
end

function XUiDraw:UpdateInfo(drawInfo)
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    self.DrawInfo = drawInfo
    self.DrawControl:Update(self.DrawInfo)
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawInfo.UseItemId)
    self.ImgUseItemIcon:SetRawImage(icon)
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawInfo.Id)
    self.PanelUp.gameObject:SetActiveEx(false)
    self.PanelSuitUpShow.gameObject:SetActiveEx(false)
    self.BtnPreviewLeft.gameObject:SetActiveEx(false)
    self.PanelCharacter.gameObject:SetActiveEx(false)
    self.PanelNewUp.gameObject:SetActiveEx(false)
    self.PanelUpShow.gameObject:SetActiveEx(false)
    self.PanelUpShowCharacter.gameObject:SetActiveEx(false)
    self.BtnOptionalDraw.gameObject:SetActiveEx(false)
    if combination then
        self.CurDrawType = combination.Type
        if combination.Type == XDrawConfigs.CombinationsTypes.Normal then
            self:UpdateLeftUpInfo(combination)
        elseif combination.Type == XDrawConfigs.CombinationsTypes.Aim then
            self:UpdateLeftAimUpInfo(combination, groupInfo)
        elseif combination.Type == XDrawConfigs.CombinationsTypes.NewUp then
            self:UpdateNewUpInfo(combination)
        elseif combination.Type == XDrawConfigs.CombinationsTypes.Furniture then
            self:UpdateLeftUpInfo(combination)
        elseif combination.Type == XDrawConfigs.CombinationsTypes.EquipSuit then
            self:UpdateLeftSuitUpInfo(combination)
        elseif combination.Type == XDrawConfigs.CombinationsTypes.CharacterUp then
            self.PanelCharacter.gameObject:SetActiveEx(true)
            self:UpdateCharacterInfo(combination)
        end
    end
    self:UpdateItemCount()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelLeft)

    if groupInfo.Type == XDataCenter.DrawManager.DrawEventType.NewHand then
        if drawInfo.MaxBottomTimes == XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId).NewHandBottomCount then
            self.PanelNewHand.gameObject:SetActiveEx(true)
            self.NewHandCount.text = CS.XTextManager.GetText("DrawNewHandCount",drawInfo.BottomTimes.."/"..drawInfo.MaxBottomTimes)
        else
            self.PanelNewHand.gameObject:SetActiveEx(false)
        end
    else
        self.PanelNewHand.gameObject:SetActiveEx(false)
    end

    local Rules = XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId)
    local IsBottomHintShow = drawInfo.IsTriggerSpecified and drawInfo.IsTriggerSpecified or false
    local hintText = Rules and Rules.DrawBottomHint and Rules.DrawBottomHint or ""
    self.TxtBottomHint.text = hintText
    self.PanelBottomHint.gameObject:SetActiveEx(IsBottomHintShow and #hintText > 0)

    self:UpdateCharacterTxt()
    self:UpdatePurchaseLB()
end
--更新一般物品Up保底显示列表（左边）
function XUiDraw:UpdateLeftUpInfo(combination)
    local parentObj = nil
    local startIndex = 1
    local list = combination and combination.GoodsId or {}
    for i = startIndex, #list do
        if not self.UpShows[i] then
            local go = CS.UnityEngine.Object.Instantiate(self.GridCommon, parentObj)
            local upShow = XUiGridCommon.New(self, go)
            table.insert(self.UpShows, upShow)
        end

        self.UpShows[i]:Refresh(list[i], gridParams)
    end

    for i = #list + 1, #self.UpShows do
        self.UpShows[i].GameObject:SetActiveEx(false)
    end

    if #list > 0 then
        self.BtnPreviewLeft.gameObject:SetActiveEx(true)
    else
        self.BtnPreviewLeft.gameObject:SetActiveEx(false)
    end
end
--更新狙击物品Up保底显示列表（左边）
function XUiDraw:UpdateLeftAimUpInfo(combination, groupInfo)
    local parentObj
    local startIndex = 1
    local list = combination and combination.GoodsId or {}
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    local IsSpAim = not(#list > 0)

    self:CheckAimHaveActivty()
    self.BtnOptionalDraw.gameObject:SetActiveEx(true)
    self.TxtAimProbability.gameObject:SetActiveEx(false)
    self.PanelUp.gameObject:SetActiveEx(true)

    self.BtnPreviewLeft.gameObject:SetActiveEx(true)
    self.PanelUpShowBase.gameObject:SetActiveEx(IsSpAim)

    if drawAimProbability[combination.Id] then
        self.TxtAimProbability.text = drawAimProbability[combination.Id].UpProbability or ""
        self.TxtAimProbability.gameObject:SetActiveEx(drawAimProbability[combination.Id].UpProbability ~= nil)
    end

    local maxSwitchCount = groupInfo.MaxSwitchDrawIdCount
    local curSwitchCount = groupInfo.SwitchDrawIdCount
    self.PanelSycs.gameObject:SetActiveEx(maxSwitchCount > 0)
    if maxSwitchCount > 0 then
        local count = maxSwitchCount - curSwitchCount
        self.PanelSycs:GetObject("TxtCount").text = CS.XTextManager.GetText("DrawSelectCountText", count)
        self.PanelSycs:GetObject("TxtNone").text = CS.XTextManager.GetText("DrawSelectNotCountText")
        self.PanelSycs:GetObject("TxtCount").gameObject:SetActiveEx(count > 0)
        self.PanelSycs:GetObject("TxtNone").gameObject:SetActiveEx(count <= 0)
    end
    
    if IsSpAim then
        return
    end

    self.AimType = XArrangeConfigs.GetType(combination.GoodsId[1])
    if self.AimType ~= XArrangeConfigs.Types.Character then
        parentObj = self.PanelUpShow
        self.PanelUpShow.gameObject:SetActiveEx(true)
        for i = startIndex, #list do
            if not self.UpShows[i] then
                local go = CS.UnityEngine.Object.Instantiate(self.GridCommon, parentObj)
                local upShow = XUiGridCommon.New(self, go)
                table.insert(self.UpShows, upShow)
            end

            self.UpShows[i]:Refresh(list[i], gridParams)
        end

        for i = #list + 1, #self.UpShows do
            self.UpShows[i].GameObject:SetActiveEx(false)
        end
    else
        self.PanelUpShowCharacter.gameObject:SetActiveEx(true)
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[1])
        self.AimImgBottomIco:SetRawImage(self.GoodsShowParams.Icon)
        local quality = XMVCA.XCharacter:GetCharMinQuality(combination.GoodsId[1])
        self.AimImgBottomRank:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(quality))

        if self.GoodsShowParams.Quality then
            local qualityIcon = self.GoodsShowParams.QualityIcon

            if qualityIcon then
                self:SetUiSprite(self.AimImgQuality, qualityIcon)
            else
                XUiHelper.SetQualityIcon(self, self.AimImgQuality, self.GoodsShowParams.Quality)
            end
        end
    end

    if #list > 0 then
        self.BtnPreviewLeft.gameObject:SetActiveEx(true)
    else
        self.BtnPreviewLeft.gameObject:SetActiveEx(false)
    end
    
end

--更新Up保底显示列表（意识组合Up类）（左边）
function XUiDraw:UpdateLeftSuitUpInfo(combination)
    self.GridSuitCommon.gameObject:SetActiveEx(false)
    self.PanelSuitUpShow.gameObject:SetActiveEx(true)
    self.PanelUp.gameObject:SetActiveEx(false)

    if self.DrawInfo then
        local list = combination and combination.GoodsId or {}
        for i = 1, #list do
            if not self.UpSuitShows[i] then
                local go = CS.UnityEngine.Object.Instantiate(self.GridSuitCommon, self.PanelSuitUpShow)
                go.gameObject:SetActiveEx(true)
                local upShow = XUiGridSuitDetail.New(go, self)
                table.insert(self.UpSuitShows, upShow)
            end

            self.UpSuitShows[i]:Refresh(list[i], nil, true)
        end

        for i = #list + 1, #self.UpSuitShows do
            self.UpSuitShows[i].GameObject:SetActiveEx(false)
        end

        if #list > 0 then
            self.BtnPreviewLeft.gameObject:SetActiveEx(true)
        else
            self.BtnPreviewLeft.gameObject:SetActiveEx(false)
        end
    end
end
--更新角色Up保底显示信息（左边）
function XUiDraw:UpdateCharacterInfo(combination)
    --self.TxtBottomTimes.text = CS.XTextManager.GetText("DrawRuleHint","asd","asd")--, self.DrawInfo.BottomTimes
    if self.DrawInfo then
        -- self.ImgBottomIco = self.Transform:Find("SafeAreaContentPane/PanelDrawGroup/PanelDraw/PanelLeft/PanelCharacter/PanelCharacterBottom/UpCharacter/ImgBottomIco"):GetComponent("RawImage")
        -- self.ImgBottomRank = self.Transform:Find("SafeAreaContentPane/PanelDrawGroup/PanelDraw/PanelLeft/PanelCharacter/PanelCharacterBottom/UpCharacter/ImgBottomRank"):GetComponent("RawImage")
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[1])
        self.ImgBottomIco:SetRawImage(self.GoodsShowParams.Icon)
        local quality = XMVCA.XCharacter:GetCharMinQuality(combination.GoodsId[1])
        self.ImgBottomRank:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(quality))
        if #combination.GoodsId > 1 then
            -- self.Transform:Find("SafeAreaContentPane/PanelDrawGroup/PanelDraw/PanelLeft/PanelCharacter/PanelCharacterUpShow/UpCharacter2").gameObject:SetActiveEx(true)
            -- self.ImgBottomIco2 = self.Transform:Find("SafeAreaContentPane/PanelDrawGroup/PanelDraw/PanelLeft/PanelCharacter/PanelCharacterUpShow/UpCharacter2/ImgBottomIco2"):GetComponent("RawImage")
            -- self.ImgBottomRank2 = self.Transform:Find("SafeAreaContentPane/PanelDrawGroup/PanelDraw/PanelLeft/PanelCharacter/PanelCharacterUpShow/UpCharacter2/ImgBottomRank2"):GetComponent("RawImage")
            self.UpCharacter2.gameObject:SetActiveEx(true)
            self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[2])
            self.ImgBottomIco2:SetRawImage(self.GoodsShowParams.Icon)
            local tmpQuality = XMVCA.XCharacter:GetCharMinQuality(combination.GoodsId[2])
            self.ImgBottomRank2:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(tmpQuality))
        else
            -- self.Transform:Find("SafeAreaContentPane/PanelDrawGroup/PanelDraw/PanelLeft/PanelCharacter/PanelCharacterUpShow/UpCharacter2").gameObject:SetActiveEx(false)
            self.UpCharacter2.gameObject:SetActiveEx(false)
        end
    end
end

--更新角色Up保底显示信息（左边）
function XUiDraw:UpdateNewUpInfo(combination)
    self.PanelNewUp.gameObject:SetActiveEx(true)
    self.NewUpItem.gameObject:SetActiveEx(false)
    self.NewUpCharacter.gameObject:SetActiveEx(false)
    self.BtnPreviewLeft.gameObject:SetActiveEx(true)
    if self.DrawInfo then
        if XArrangeConfigs.GetType(combination.GoodsId[1]) ~= XArrangeConfigs.Types.Character then
            local upShow = XUiGridCommon.New(self, self.NewUpItem)
            upShow:Refresh(combination.GoodsId[1], gridParams)
            self.NewUpItem.gameObject:SetActiveEx(true)
        else
            self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[1])
            self.ImgNewUpIco:SetRawImage(self.GoodsShowParams.Icon)
            local quality = XMVCA.XCharacter:GetCharMinQuality(combination.GoodsId[1])
            self.ImgNewUpRank:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(quality))

            if self.GoodsShowParams.Quality then
                local qualityIcon = self.GoodsShowParams.QualityIcon

                if qualityIcon then
                    self:SetUiSprite(self.ImgQuality, qualityIcon)
                else
                    XUiHelper.SetQualityIcon(self, self.ImgQuality, self.GoodsShowParams.Quality)
                end
            end

            self.NewUpCharacter.gameObject:SetActiveEx(true)
        end
    end
end

function XUiDraw:UpdateCharacterTxt()
    local combination = XDataCenter.DrawManager.GetDrawCombination(self.DrawInfo.Id)
    if combination then
        if combination.Type == XDrawConfigs.CombinationsTypes.CharacterUp then
            self.TxtBottomTimes.text = CS.XTextManager.GetText("DrawBottomTimes", self.DrawInfo.BottomTimes)
        end
        if combination.Type == XDrawConfigs.CombinationsTypes.NewUp then
            local type = XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId).UpType
            local quality = XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId).UpQuality
            local probability = XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId).UpProbability
            self.TxtNewUpTimes.text = CS.XTextManager.GetText("DrawRuleHint",quality,type,probability)
        end
    end
end

function XUiDraw:UpdatePurchaseLB()
    if self.DrawInfo then
        if self.DrawInfo.PurchaseId and next(self.DrawInfo.PurchaseId) then
            self.BtnDrawPurchaseLB.gameObject:SetActiveEx(true)
            if self.DrawInfo.PurchaseUiType and self.DrawInfo.PurchaseUiType ~= 0 then
                local uiType = self.DrawInfo.PurchaseUiType
                XDataCenter.PurchaseManager.GetPurchaseListRequest({uiType})
            end
        else
            self.BtnDrawPurchaseLB.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDraw:UpdateItemCount()
    if not self.DrawInfo then
        return
    end
    self.TxtUseItemCount.text = XDataCenter.ItemManager.GetItem(self.DrawInfo.UseItemId).Count
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiDraw:InitAutoScript()
    self:AutoAddListener()
end

function XUiDraw:AutoAddListener()
    self:RegisterClickEvent(self.BtnCloseBottomInfo, self.OnBtnCloseBottomInfoClick)
    self:RegisterClickEvent(self.ScrollView, self.OnScrollViewClick)
    self:RegisterClickEvent(self.Scrollbar, self.OnScrollbarClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnCharacterBottomInfo, self.OnBtnCharacterBottomInfoClick)
    self:RegisterClickEvent(self.BtnOptionalDraw, self.OnBtnOptionalDrawClick)
    self:RegisterClickEvent(self.BtnUseItem, self.OnBtnUseItemClick)
    self:RegisterClickEvent(self.BtnPreview, self.OnBtnPreviewClick)
    self:RegisterClickEvent(self.BtnDrawRule, self.OnBtnDrawRuleClick)
    self:RegisterClickEvent(self.BtnMainRule, self.OnBtnMainRuleClick)
    self:RegisterClickEvent(self.BtnPreviewLeft, self.OnBtnPreviewLeftClick)
    self:RegisterClickEvent(self.BtnNewUpInfo, self.OnBtnCharacterBottomInfoClick)
    self:RegisterClickEvent(self.BtnDrawPurchaseLB, self.OnBtnDrawPurchaseLBClick)
end
-- auto

function XUiDraw:OnScrollViewClick()

end

function XUiDraw:OnScrollbarClick()

end

function XUiDraw:OnBtnCloseBottomInfoClick()
    for _, v in pairs(self.BottomInfoTxts) do
        CS.UnityEngine.Object.Destroy(v.gameObject)
    end
    self.BottomInfoTxts = {}
    self.PanelCharacterBottomInfo.gameObject:SetActiveEx(false)
end

function XUiDraw:OnBtnCharacterBottomInfoClick()
    self.BtnDrawRule.interactable = false
    XLuaUiManager.Open("UiDrawLog",self.DrawInfo,IndexEventRule,function()
            self.BtnDrawRule.interactable = true
        end)
end
function XUiDraw:OnBtnMainRuleClick(...)
    self:OnBtnDrawRuleClick(...)
end

function XUiDraw:OnBtnPreviewLeftClick(...)
    self:OnBtnPreviewClick(...)
end

function XUiDraw:OnBtnBackClick()
    self:Close()
end

function XUiDraw:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDraw:OnBtnOptionalDrawClick()
    self:OpenChildUi("UiDrawOptional",self,
        function(drawId)
            local drawInfo = XDataCenter.DrawManager.GetDrawInfo(drawId)
            self:UpdateInfo(drawInfo)
        end,
        function ()
            self:Close()
        end)
end

function XUiDraw:OnBtnPreviewClick()
    self.BtnDrawRule.interactable = false
    XLuaUiManager.Open("UiDrawLog",self.DrawInfo,IndexPreview,function()
            self.BtnDrawRule.interactable = true
        end)
end

function XUiDraw:OnBtnDrawRuleClick()
    self.BtnDrawRule.interactable = false
    XLuaUiManager.Open("UiDrawLog",self.DrawInfo,IndexBaseRule,function()
            self.BtnDrawRule.interactable = true
        end)
end

function XUiDraw:OnBtnUseItemClick()
    local data = XDataCenter.ItemManager.GetItem(self.DrawInfo.UseItemId)
    XLuaUiManager.Open("UiTip", data)
end

function XUiDraw:OnBtnDrawPurchaseLBClick()
    self:OpenChildUi("UiDrawPurchaseLB", self)
end

function XUiDraw:HideUiView(onAnimFinish)
    self.OpenSound = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiDrawCard_BoxOpen)

    self:PlayAnimation("DrawRetract", function()
            onAnimFinish()
        end, function()
            self.ImgMask.gameObject:SetActiveEx(true)
        end)
end

function XUiDraw:ResetScene()
    XRTextureManager.SetTextureCache(self.RImgDrawCard)
end

function XUiDraw:PushShow(drawInfo, rewardList)
    self:OpenChildUi("UiDrawShow")
    self.PanelNewHand.gameObject:SetActiveEx(false)
    self:FindChildUiObj("UiDrawShow"):SetData(drawInfo, rewardList, function()
            if self.OpenSound then
                self.OpenSound:Stop()
            end

            local fun = function()
                self:PushResult(drawInfo, rewardList)
                self:UpdateInfo(drawInfo)
                local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
                if groupInfo.Type == XDataCenter.DrawManager.DrawEventType.NewHand then
                    if drawInfo.MaxBottomTimes == XDataCenter.DrawManager.GetDrawGroupRule(self.GroupId).NewHandBottomCount then
                        self.PanelNewHand.gameObject:SetActiveEx(true)
                    else
                        self.PanelNewHand.gameObject:SetActiveEx(false)
                    end
                else
                    self.PanelNewHand.gameObject:SetActiveEx(false)
                end
            end

            if self.CurDrawType and self.CurDrawType == XDrawConfigs.CombinationsTypes.Aim then
                XDataCenter.DrawManager.GetDrawInfoList(drawInfo.GroupId,fun,true)
            else
                fun()
            end


        end, self.BackGround)
end

function XUiDraw:PushResult(drawInfo, rewardList)
    XLuaUiManager.Open("UiDrawResult", drawInfo, rewardList, function() end)
end

function XUiDraw:CheckAimHaveActivty()
    local IsHaveActivty = false
    local drawInfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(self.GroupId)
    for _,drawInfo in pairs(drawInfoList) do
        if drawInfo.EndTime > 0 then
            IsHaveActivty = true
            break
        end
    end
    self.BtnOptionalDraw:ShowTag(IsHaveActivty)
end

function XUiDraw:CheckAutoOpen()
    if not self.FirstAutoOpen then
        return
    end
    if self.CurDrawType ~= XDrawConfigs.CombinationsTypes.Aim then
        return
    end
    local IsHaveActivty = false
    local activtyTime = 0
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    local drawInfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(self.GroupId)
    for _,drawInfo in pairs(drawInfoList) do
        if drawInfo.StartTime > 0 then
            IsHaveActivty = true
            if drawInfo.StartTime > activtyTime then
                activtyTime = drawInfo.StartTime
            end
        end
    end
    
    local IsCanActivtyOpen = IsHaveActivty and XDataCenter.DrawManager.IsCanAutoOpenAimGroupSelect(activtyTime,self.GroupId)
    if IsCanActivtyOpen or (groupInfo.MaxSwitchDrawIdCount > 0 and groupInfo.UseDrawId == 0) then
        self:OnBtnOptionalDrawClick()
    end
    self.FirstAutoOpen = false
end

function XUiDraw:PlaySpcalAnime()
    local combination = XDataCenter.DrawManager.GetDrawCombination(self.DrawInfo.Id)
    if combination then
        if combination.Type == XDrawConfigs.CombinationsTypes.Aim then
            if self.FirstAnim then
                self.FirstAnim = false
            else
                self:PlayAnimation("AniZixuan")
            end
        end
    end
end

function XUiDraw:ShowExtraReward(cb)
    if self.ExtraRewardList and next(self.ExtraRewardList) then
        XUiManager.OpenUiObtain(self.ExtraRewardList, nil, function ()
                if cb then cb() end
            end)
        self.ExtraRewardList = nil
    else
        if cb then cb() end
    end
end

function XUiDraw:SetExtraRewardList(list)
    self.ExtraRewardList = list
end

function XUiDraw:OnDisable()
    XUiHelper.SetDelayPopupFirstGet()
end


function XUiDraw:InitDrawBackGround(backgroundName)
    local root = self.UiSceneInfo.Transform
    self.BackGround = root:FindTransform("GroupBase"):LoadPrefab(backgroundName)
    CS.XShadowHelper.AddShadow(self.BackGround:FindTransform("BoxModeParent").gameObject)
end