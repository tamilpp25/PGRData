local XUiLotto = XLuaUiManager.Register(XLuaUi, "UiLotto")
local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiLotto:OnStart(groupData, closeCb, backGround)
    self.LottoGroupData = groupData
    self.CloseCb = closeCb
    self.BackGroundPath = backGround
    self.TxtTitle.text = groupData:GetName()
    self.IsCanDraw = true
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, groupData)
    self:SetBtnCallBack()
    self:InitDrawBackGround(self.BackGroundPath)

end

function XUiLotto:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiLotto:OnEnable()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("DrawBegan", function()
            XLuaUiManager.SetMask(false)
            self:ShowExtraReward()
        end)
    self:UpdateAllPanel()
    self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    self.PlayableDirector:Stop()
    self.PlayableDirector:Evaluate()
end


function XUiLotto:SetBtnCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.PanelUseItem:GetObject("BtnUseItem").CallBack = function()
        self:OnBtnUseItemClick()
    end
    self.BtnDrawRule.CallBack = function()
        self:OnBtnDrawRuleClick()
    end
    self.PanelDrawButtons:GetObject("BtnDraw").CallBack = function()
        self:OnBtnDrawClick()
    end
end

function XUiLotto:OnBtnBackClick()
    self:Close()
end

function XUiLotto:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLotto:OnBtnUseItemClick()
    local drawData = self.LottoGroupData:GetDrawData()
    local data = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId())
    XLuaUiManager.Open("UiTip", data)
end

function XUiLotto:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog",self.LottoGroupData)
end

function XUiLotto:OnBtnDrawClick()
    self:OnDraw()
end

function XUiLotto:InitDrawBackGround(backgroundName)
    local root = self.UiSceneInfo.Transform
    self.BackGround = root:FindTransform("GroupBase"):LoadPrefab(backgroundName)
    CS.XShadowHelper.AddShadow(self.BackGround:FindTransform("BoxModeParent").gameObject)
end

function XUiLotto:UpdateAllPanel()
    self:UpdatePanelPreview()
    self:UpdatePanelDrawButtons()
    self:UpdatePanelUseItem()
end

function XUiLotto:UpdatePanelPreview()
    self.PanelLottoPreview:UpdatePanel()
end

function XUiLotto:UpdatePanelDrawButtons()
    local drawData = self.LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())
    self.PanelDrawButtons:GetObject("BtnDraw").gameObject:SetActiveEx(not drawData:IsLottoCountFinish())
    self.PanelDrawButtons:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelDrawButtons:GetObject("TxtUseItemCount").text = drawData:GetConsumeCount() > 0 and 
    drawData:GetConsumeCount() or CSTextManagerGetText("LottoDrawFreeText")
end

function XUiLotto:UpdatePanelUseItem()
    local drawData = self.LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())

    self.PanelUseItem:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelUseItem:GetObject("TxtUseItemCount").text = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
end

function XUiLotto:ShowExtraReward(cb)
    if self.ExtraRewardList and next(self.ExtraRewardList) then
        XUiManager.OpenUiObtain(self.ExtraRewardList, nil, function ()
                if cb then cb() end
            end)
        self.ExtraRewardList = nil
    else
        if cb then cb() end
    end
end

function XUiLotto:OnDraw()
    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
        return
    end
    local drawData = self.LottoGroupData:GetDrawData()
    local curItemCount = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
    local needItemCount = drawData:GetConsumeCount()
    if needItemCount > curItemCount then
        XUiManager.TipMsg(CSTextManagerGetText("DrawNotEnoughSkipText"))
        XLuaUiManager.Open("UiLottoTanchuang", drawData, function ()
                self:UpdateAllPanel()
            end)
        return
    end

    if self.IsCanDraw then
        self.IsCanDraw = false
        characterRecord.Record()
        local drawData = self.LottoGroupData:GetDrawData()
        XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList)
                XDataCenter.AntiAddictionManager.BeginDrawCardAction()
                self.ExtraRewardList = extraRewardList
                self:HideUiView(rewardList)
            end, function ()
                self.IsCanDraw = true
            end)
    end
end

function XUiLotto:HideUiView(rewardList)
    self.OpenSound = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiDrawCard_BoxOpen)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("DrawRetract", function()
            if rewardList and next(rewardList) then
                self.IsCanDraw = true
                self:PushShow(rewardList)
            end
            XLuaUiManager.SetMask(false)
        end)
end

function XUiLotto:PushShow(rewardList)
    self:OpenChildUi("UiLottoShow")
    self:FindChildUiObj("UiLottoShow"):SetData(rewardList, function()
            if self.OpenSound then
                self.OpenSound:Stop()
            end
            XLuaUiManager.Open("UiDrawResult", nil, rewardList, function() end)
        end, self.BackGround)
end