---@class XUiPanelWheelchairManualLotto: XUiNode
---@field _Control XWheelchairManualControl
local XUiPanelWheelchairManualLotto = XClass(XUiNode, 'XUiPanelWheelchairManualLotto')
local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")

function XUiPanelWheelchairManualLotto:OnStart()
    self._StartRun = true
    XDataCenter.LottoManager.GetLottoRewardInfoRequest(function() 
        self:InitAfterDataRequest()
        self:UpdatePanelAll()
        self._StartRun = false
    end, true)

    XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.ReddotKey.LottoNew)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_UPDATE_GROUP_DATA, self.OnUpdateGroupDataEvent, self)
end

function XUiPanelWheelchairManualLotto:OnEnable()
    if self._Invalid then
        return
    end

    if not self._StartRun then
        self:UpdatePanelAll()
    end
    self:AddEventListener()
end

function XUiPanelWheelchairManualLotto:OnDisable()
    self:RemoveEventListener()
end

function XUiPanelWheelchairManualLotto:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_UPDATE_GROUP_DATA, self.OnUpdateGroupDataEvent, self)
end

function XUiPanelWheelchairManualLotto:InitAfterDataRequest()
    self.LottoId = self._Control:GetCurActivityLottoId()
    self.LottoGroupData = XDataCenter.LottoManager.GetLottoGroupDataByGroupId(self.LottoId)

    if XTool.IsTableEmpty(self.LottoGroupData) then
        XLog.Error('Lotto活动未开启，数据不存在, LottoId:'..tostring(self.LottoId))
        self._Invalid = true
        return
    end

    self.PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self.Parent, self.LottoGroupData)

    self.PanelUseItem:GetObject("BtnUseItem").CallBack = function()
        self:OnBtnUseItemClick()
    end
    self.BtnDrawRule.CallBack = function()
        self:OnBtnDrawRuleClick()
    end
    self.PanelDrawButtons:GetObject("BtnDraw").CallBack = function()
        self:OnBtnDrawClick()
    end

    self.IsCanDraw = true

    local bannerBg = self.LottoGroupData:GetBanner()
    if bannerBg and self.PanelDrawBackGround then
        self.PanelDrawBackGround.gameObject:LoadPrefab(bannerBg)
    end
end

function XUiPanelWheelchairManualLotto:UpdatePanelAll()
    self.PanelLottoPreview:UpdatePanel()
    local lottoInfo = self.LottoGroupData.DrawDataDic[self.LottoId]
    if lottoInfo then
        local recordCount = XTool.GetTableCount(lottoInfo.LottoRecords)
        self.TxtTotalDrawCount.text = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('TotalDrawCount'), recordCount)
    else
        self.TxtTotalDrawCount.text = ''
    end
    self:UpdatePanelDrawButtons()
    self:UpdatePanelUseItem()
end

function XUiPanelWheelchairManualLotto:UpdatePanelDrawButtons()
    local drawData = self.LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())
    self.PanelDrawButtons:GetObject("BtnDraw").gameObject:SetActiveEx(not drawData:IsLottoCountFinish())
    self.PanelDrawButtons:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelDrawButtons:GetObject("TxtUseItemCount").text = drawData:GetConsumeCount() > 0 and
            drawData:GetConsumeCount() or XUiHelper.GetText("LottoDrawFreeText")
end

function XUiPanelWheelchairManualLotto:UpdatePanelUseItem()
    local drawData = self.LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())

    self.PanelUseItem:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelUseItem:GetObject("TxtUseItemCount").text = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
end

function XUiPanelWheelchairManualLotto:SetUiSprite(...)
    self.Parent:SetUiSprite(...)
end

function XUiPanelWheelchairManualLotto:OnBtnUseItemClick()
    local drawData = self.LottoGroupData:GetDrawData()
    local data = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId())
    XLuaUiManager.Open("UiTip", data)
end

function XUiPanelWheelchairManualLotto:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog", self.LottoGroupData)
end

function XUiPanelWheelchairManualLotto:OnBtnDrawClick()
    self:OnDraw()
end

function XUiPanelWheelchairManualLotto:OnDraw()
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return
    end
    local drawData = self.LottoGroupData:GetDrawData()
    local curItemCount = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
    local needItemCount = drawData:GetConsumeCount()
    if needItemCount > curItemCount then
        XUiManager.TipMsg(XUiHelper.GetText("DrawNotEnoughSkipText"))
        XLuaUiManager.Open("UiLottoTanchuang", drawData)
        return
    end

    if self.IsCanDraw then
        self.IsCanDraw = false
        characterRecord.Record()
        local drawData = self.LottoGroupData:GetDrawData()
        XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList, lottoRewardId)
            local lottoRewardEntity = self.LottoGroupData:GetDrawData():GetRewardDataById(lottoRewardId)
            XDataCenter.AntiAddictionManager.BeginDrawCardAction()
            self.ExtraRewardList = extraRewardList
            self.IsCanDraw = true
            local isNotifyWeaponFashionTransform = XDataCenter.WeaponFashionManager.GetIsNotifyWeaponFashionTransform()
            if isNotifyWeaponFashionTransform then
                XDataCenter.WeaponFashionManager.ResetIsNotifyWeaponFashionTransform()
            end
            rewardList = XDataCenter.LottoManager.HandleDrawShowRewardEffect(rewardList, lottoRewardEntity:GetShowEffectId())
            rewardList = XDataCenter.LottoManager.HandleDrawShowRewardQuality(rewardList, lottoRewardEntity:GetRareLevel())
            XLuaUiManager.Open("UiLottoCommonDrawShow", drawData, rewardList)
        end, function()
            self.IsCanDraw = true
        end)
    end
end

function XUiPanelWheelchairManualLotto:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.UpdatePanelAll, self)
end

function XUiPanelWheelchairManualLotto:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.UpdatePanelAll, self)
end

function XUiPanelWheelchairManualLotto:OnUpdateGroupDataEvent()
    self.LottoGroupData = XDataCenter.LottoManager.GetLottoGroupDataByGroupId(self.LottoId)
    if self.PanelLottoPreview then
        self.PanelLottoPreview:UpdateGroupData(self.LottoGroupData)
       
        if self:IsNodeShow() then
            -- 界面显示了才刷新显示
            self:UpdatePanelAll()
        end

        if not self:IsValid() then
            -- 保底检查下是否泄漏
            XLog.Error('XUiPanelWheelchairManualLotto界面实例已销毁，但仍响应了事件EVENT_LOTTO_UPDATE_GROUP_DATA')
        end
    end
end

return XUiPanelWheelchairManualLotto