local XUiDrawNewYear = XLuaUiManager.Register(XLuaUi, "UiDrawNewYear")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")
local TextManager = CS.XTextManager

local type = {IN = 1, OUT = 2}
local UiType = 15
local startPlaySoundTime = CS.XGame.ClientConfig:GetFloat("DrawNewYearPlaySoundTime")

local MAX_GACHA_BTN_COUNT = 2

local ShowDrawTipTime = CS.XGame.ClientConfig:GetFloat("NewYearShowDrawTipsTime")
local RotateSpeed = CS.XGame.ClientConfig:GetFloat("LuckDrawCoinsRotateSpeed")
local NewYearCoinsPerDragAddSpeed = CS.XGame.ClientConfig:GetFloat("NewYearCoinsPerDragAddSpeed")
local NewYearCoinsMaxAddSpeed = CS.XGame.ClientConfig:GetFloat("NewYearCoinsMaxAddSpeed")
local NewYearCoinsDampAddSpeed = CS.XGame.ClientConfig:GetFloat("NewYearCoinsDampAddSpeed")
local NewYearCoinsMaxSpeed = CS.XGame.ClientConfig:GetFloat("NewYearCoinsMaxSpeed")
local NewYearCoinsDampSpeed = CS.XGame.ClientConfig:GetFloat("NewYearCoinsDampSpeed")

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiDrawNewYear:OnStart(id, signId)
    self.GachaId = id
    self.IsCanGacha = true
    self.SignId = signId
    self.IsFirst = true
    self.LastId = 1
    self.Coins = {}

    self.GachaCfg = XGachaConfigs.GetGachaCfgById(id)
    self.PreviewList = {}
    self.PreviewList[type.IN] = {}
    self.PreviewList[type.OUT] = {}

    local tempTab = {}
    table.insert(tempTab, UiType)
    XDataCenter.PurchaseManager.GetPurchaseListRequest(tempTab, function()
        self.PurchaseDatas = XDataCenter.PurchaseManager.GetDatasByUiType(UiType)
    end)
    self.GachaTemplate = XGachaConfigs.GetGachaCfgById(self.GachaId)

    self:InitAutoScript()
    self:InitUiScene()
    self:InitPanelPreview()
    self:InitDrawButtons()
    --初始化硬币常规速度以及加速度数据
    self.DragActivity:SetNormalRotateSpeed(RotateSpeed, NewYearCoinsPerDragAddSpeed, 
        NewYearCoinsMaxAddSpeed, NewYearCoinsDampAddSpeed, NewYearCoinsMaxSpeed, NewYearCoinsDampSpeed)
    self.DragActivity.gameObject:SetActiveEx(false)
    --self.BuyAssert = XUiDrawBuyAssert.New(self, self.PanelBuyAsset)
    self.ImgMask.gameObject:SetActiveEx(false)

    self.CStartPos.gameObject:SetActiveEx(true)
    self.CCanDrawPos.gameObject:SetActiveEx(false)
    self.HeiPingPingMuGo.gameObject:SetActiveEx(false)
end

function XUiDrawNewYear:OnEnable()
    --XEventManager.AddEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.UpdateInfo, self)
    self:UpdateInfo()
    self.IsReadyForGacha = false
    XUiHelper.SetDelayPopupFirstGet(true)
    self.ImgMask.gameObject:SetActiveEx(true)
    self:PlayAnimation("DrawBegan", function() self.ImgMask.gameObject:SetActiveEx(false) end)
    self:PlayLoopAnime()

    self.DragActivity.gameObject:SetActiveEx(false)
    self.CStartPos.gameObject:SetActiveEx(true)
    self.CCanDrawPos.gameObject:SetActiveEx(false)
    self.BtnToStart.gameObject:SetActiveEx(false)
    self.PurpleEffectGo.gameObject:SetActiveEx(false)
    self.OrangeEffectGo.gameObject:SetActiveEx(false)
    for i = 1, MAX_GACHA_BTN_COUNT do
        self.Coins[i].gameObject:SetActiveEx(false)
    end
    
    self.RefreshId = CS.XScheduleManager.ScheduleForever(function()
            self:UpdateInfo()
        end, 1000, 0)
end

function XUiDrawNewYear:OnDisable()
    for i = 1, 6 do
        self.BackGround.transform:Find("TimeLine/Level" .. i).gameObject:SetActiveEx(false)
    end
    
    self.PurpleEffectGo.gameObject:SetActiveEx(false)
    self.OrangeEffectGo.gameObject:SetActiveEx(false)
    self:ClearTimer()
    if self.RefreshId then
        CS.XScheduleManager.UnSchedule(self.RefreshId)
        self.RefreshId = nil
    end
    
    if self.SoundTimeId then
        CS.XScheduleManager.UnSchedule(self.SoundTimeId)
        self.SoundTimeId = nil
    end
end

function XUiDrawNewYear:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiDrawNewYear:PlayLoopAnime()
    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
end

function XUiDrawNewYear:Update()
    if self.IsReadyForGacha then
        self:ShowGacha()
    end
end

--按钮绑定
function XUiDrawNewYear:InitAutoScript()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnMore.CallBack = function()
        self:OnBtnMore()
    end
    self.BtnUseItem.CallBack = function()
        self:OnBtnUseItemClick()
    end
    self.BtnToStart.CallBack = function()
        self:OnBtnToStartClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end

--获取场景中的内容
function XUiDrawNewYear:InitUiScene()
    local root = self.UiModelGo.transform
    self.BackGround = root.parent.parent:FindTransform("GroupBase")
    self.CStartPos = self.BackGround:FindTransform("CStartPos")
    self.CCanDrawPos = self.BackGround:FindTransform("CCanDrawPos")
    self.CoinsParentPoint = self.BackGround:FindTransform("CoinsParentPoint")
    for i = 0, self.CoinsParentPoint.childCount - 1 do
        self.CoinsParentPoint:GetChild(i).gameObject:SetActiveEx(false)
    end
    self.Coins[1] = self.BackGround:FindTransform("UiLuckdraw03Yingbi01")
    self.Coins[2] = self.BackGround:FindTransform("UiLuckdraw03Yingbi")
    self.DrawShowTipGo = self.BackGround:FindTransform("FxUiJPDrawYuandanTishi")
    self.OrangeEffectGo = self.BackGround:FindTransform("FxUiJPDrawYuandanLingdangOrange")
    self.PurpleEffectGo = self.BackGround:FindTransform("FxUiJPDrawYuandanLingdangPurple")
    self.HeiPingPingMuGo = self.BackGround:FindTransform("FxHeipingpingmuYuanDan")
    self.DrawShowTipGo.gameObject:SetActiveEx(false)

    for i = 1, MAX_GACHA_BTN_COUNT do
        self.Coins[i].gameObject:SetActiveEx(false)
    end
end

--初始化两个抽奖按钮
function XUiDrawNewYear:InitDrawButtons()
    self.UseItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.GachaCfg.ConsumeId)
    for i = 1, MAX_GACHA_BTN_COUNT do
        local btnName = "BtnDraw" .. i
        local btn = XUiHelper.TryGetComponent(self.PanelDrawButtons, btnName)
        if btn then
            self:InitButton(btn, i)
        end
    end
end

--初始化每个按钮信息
function XUiDrawNewYear:InitButton(btn, index)
    local gachaCount = self.GachaCfg.BtnGachaCount[index]
    btn.transform:Find("TxtDrawDesc"):GetComponent("Text").text = CS.XTextManager.GetText("NewYearGachaCount", gachaCount)
    local itemIcon = btn.transform:Find("ImgUseItemIcon"):GetComponent("RawImage")
    itemIcon:SetRawImage(self.UseItemIcon)
    btn.transform:Find("TxtUseItemCount"):GetComponent("Text").text = gachaCount * self.GachaCfg.ConsumeCount

    self:RegisterClickEvent(btn:GetComponent("Button"), function()
            self:OnBtnDrawClick(btn, gachaCount, index)
        end)
end

--初始化面板信息，奖励，展示
function XUiDrawNewYear:InitPanelPreview()
    local gachaInfo = {}
    gachaInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(self.GachaId)
    
    self.AllPreviewPanel = {}
    self.AllPreviewPanel.Transform = self.PanelPreview.transform
    XTool.InitUiObject(self.AllPreviewPanel)
    --奖励预览关闭按钮
    self.AllPreviewPanel.BtnPreviewConfirm.CallBack = function()
        self.PanelPreview.gameObject:SetActiveEx(false)
    end
    self.AllPreviewPanel.BtnPreviewClose.CallBack = function()
        self.PanelPreview.gameObject:SetActiveEx(false)
    end
    self:SetPreviewData(gachaInfo, self.AllPreviewPanel.GridDrawActivity, self.AllPreviewPanel.PanelDrawItemSP, self.AllPreviewPanel.PanelDrawItemNA, self.PreviewList[type.IN], type.IN)
    self:SetPreviewData(gachaInfo, self.GridDrawActivity, nil, nil, self.PreviewList[type.OUT], type.OUT)

    --奖励预览界面的已获得描述
    self.AllPreviewPanel.TxetFuwenben.text = string.format("%d%s%d", XDataCenter.GachaManager.GetCurCountOfAll(), '/', XDataCenter.GachaManager.GetMaxCountOfAll())--CS.XTextManager.GetText("AlreadyobtainedCount", XDataCenter.GachaManager.GetCurCountOfAll(), XDataCenter.GachaManager.GetMaxCountOfAll())
    --主界面的已获得
    self.TxtNumber.text = string.format("%d%s%d", XDataCenter.GachaManager.GetCurCountOfAll(), '/', XDataCenter.GachaManager.GetMaxCountOfAll())
    --活动名字
    self.TxtActivityTime.text = CS.XTextManager.GetText("NewYearChouJiang")
end

--设置奖励展示
function XUiDrawNewYear:SetPreviewData(gachaInfo, obj, parentSP, parentNA, previewList, previewType)
    local count = 1

    for i = 1, 6 do
        self["GridDrawActivity" .. i].gameObject:SetActiveEx(false)
    end

    for k,v in pairs(gachaInfo) do
        local go = nil
        if previewType == type.IN then
            if v.Rare and parentSP then
                go = CS.UnityEngine.Object.Instantiate(obj, parentSP)
            elseif (not v.Rare) and parentNA then
                go = CS.UnityEngine.Object.Instantiate(obj, parentNA)
            end
        else
            if v.Rare then
                go = self["GridDrawActivity" .. count]
                count = count + 1
            end
        end

        if go then
            local item = XUiGridCommon.New(self, go)
            local tmpData = {}
            previewList[k] = item
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count
            go.gameObject:SetActiveEx(true)
            item:Refresh(tmpData, nil, nil, nil, v.CurCount)
        end
    end
end

--更新金币信息
function XUiDrawNewYear:UpdateInfo()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(self.GachaCfg.ConsumeId)
    self.ImgUseItemIcon:SetRawImage(icon)
    self:UpdateItemCount()
end

--更新持有的抽奖金币数量
function XUiDrawNewYear:UpdateItemCount()
    self.TxtUseItemCount.text = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
end

--显示获取的奖励信息
function XUiDrawNewYear:ShowGacha()
    self.BtnToStart.gameObject:SetActiveEx(false)
    XDataCenter.AntiAddictionManager.BeginDrawCardAction()
    self.SoundTimeId = nil
    self.SoundTimeId = CS.XScheduleManager.ScheduleOnce(function()
            self.OpenSound = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiLuckDraw_DragCoin)
        end, startPlaySoundTime)
    
    self:UpdateItemCount()
    self.IsCanGacha = self.RewardList and #self.RewardList > 0
    self.IsReadyForGacha = false
    self:PushShow(self.RewardList)

    self:UpDataPreviewData()
end

function XUiDrawNewYear:UpDataPreviewData()
    local gachaInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(self.GachaId)
    for i = 1, 2 do
        for k,v in pairs(self.PreviewList[i] or {}) do
            local tmpData = {}
            tmpData.TemplateId = gachaInfo[k].TemplateId
            tmpData.Count = gachaInfo[k].Count
            v:Refresh(tmpData, nil, nil, nil, gachaInfo[k].CurCount)
        end
    end
    self.AllPreviewPanel.TxetFuwenben.text = CS.XTextManager.GetText("AlreadyobtainedCount", XDataCenter.GachaManager.GetCurCountOfAll(), XDataCenter.GachaManager.GetMaxCountOfAll())
    self.TxtNumber.text = XDataCenter.GachaManager.GetCurCountOfAll() .. "/" .. XDataCenter.GachaManager.GetMaxCountOfAll()
end

--显示抽奖完成展示界面
function XUiDrawNewYear:PushShow(rewardList)
    self:OpenChildUi("UiDrawNewYearActivityShow")
    self:FindChildUiObj("UiDrawNewYearActivityShow"):SetData(rewardList, function()
            if self.OpenSound then
                self.OpenSound:Stop()
            end
            self:PushResult(rewardList)
            self:UpdateInfo()
        end, self.BackGround)
end

function XUiDrawNewYear:PushResult(rewardList)
    XLuaUiManager.Open("UiDrawResult", nil, rewardList, function() end)
end

function XUiDrawNewYear:OnBtnBackClick()
    self:Close()
end

function XUiDrawNewYear:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDrawNewYear:OnBtnMore()
    self.PanelPreview.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelPreviewEnable")
end

function XUiDrawNewYear:OnBtnUseItemClick()
    local data = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId)
    XLuaUiManager.Open("UiTip", data)
end

function XUiDrawNewYear:OnBtnToStartClick()
    self:PlayAnimation("DrawBegan")
    self:ClearTimer()
    self.BtnToStart.gameObject:SetActiveEx(false)
    self.CStartPos.gameObject:SetActiveEx(true)
    self.CCanDrawPos.gameObject:SetActiveEx(false)
    for i = 1, MAX_GACHA_BTN_COUNT do
        self.Coins[i].gameObject:SetActiveEx(false)
    end
    
    self.DragActivity.gameObject:SetActiveEx(false)
end

function XUiDrawNewYear:OnBtnHelpClick()
    XLuaUiManager.Open("UiNewYearDrawLog", self.SignId)
end

--抽奖
function XUiDrawNewYear:OnBtnDrawClick(btn, gachaCount, index)
    local ownItemCount = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
    local lackItemCount = self.GachaCfg.ConsumeCount * gachaCount - ownItemCount
    if lackItemCount > 0 then
        local leftTimes = XDataCenter.GachaManager.GetMaxCountOfAll() - XDataCenter.GachaManager.GetCurCountOfAll()
        if  gachaCount > leftTimes then
            XUiManager.TipText("DrawNewYearLeftTimes")
            return
        end

        local titleText = TextManager.GetText("DrawNewYearBuyCosumeItemTitle")
        local contentText = TextManager.GetText("DrawNewYearBuyCosumeItemContent")
        XUiManager.DialogTip(titleText, contentText, XUiManager.DialogType.Normal, nil, function()
                XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB, nil, 3)
            end)
        --local purchaseCfg
        --for _, v in pairs(self.PurchaseDatas) do
            --if v.Id == self.GachaTemplate.BtnGachaPurchaseID[index] then
                --purchaseCfg = v
            --end
        --end

        --if not XDataCenter.PayManager.CheckCanBuy(purchaseCfg.Id) then
            --return
        --end

        --if purchaseCfg.PayKeySuffix then
            --local key
            --if Platform == RuntimePlatform.Android then
                --key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), purchaseCfg.PayKeySuffix)
            --else
                --key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), purchaseCfg.PayKeySuffix)
            --end
            --XDataCenter.PayManager.Pay(key, 1, { purchaseCfg.Id }, purchaseCfg.Id)
        --end
        return
    end
    
    self:PlayAnimation("DrawRetract", function()
        if not self.CCanDrawPos.gameObject.activeSelf then
            self.CStartPos.gameObject:SetActiveEx(false)
            self.CCanDrawPos.gameObject:SetActiveEx(true)
        end
        self.DragActivity.gameObject:SetActiveEx(true)
        for i = 1, MAX_GACHA_BTN_COUNT do
            self.Coins[i].gameObject:SetActiveEx(false)
        end

        if self.Coins[index] then
            self.Coins[index].gameObject:SetActiveEx(true)
        end
        self.DragActivity:SetOperatorGo(self.Coins[index].gameObject, function()
                self:OnStartDraw(gachaCount)
            end)

        self.IsFirst = false
        self.LastId = index
    end)

    self.DrawTipTimeId = CS.XScheduleManager.ScheduleOnce(function ()
            self.DrawShowTipGo.gameObject:SetActiveEx(true)
        end, ShowDrawTipTime * 1000)
    self.BtnToStart.gameObject:SetActiveEx(true)
end

--硬币滑动结束后开始抽奖
function XUiDrawNewYear:OnStartDraw(gachaCount)
    local dtCount = XDataCenter.GachaManager.GetMaxCountOfAll() - XDataCenter.GachaManager.GetCurCountOfAll()
    if dtCount < gachaCount then
        XUiManager.TipMsg(CS.XTextManager.GetText("GachaIsNotEnough"))
        return
    end

    --if not XDataCenter.GachaManager.CheckGachaIsOpenById(self.GachaCfg.Id, true) then
    --self:PlayAnimation("DrawBegan")
        --return
    --end
    if self.IsCanGacha then
        self.IsCanGacha = false

        characterRecord.Record()
        self.ImgMask.gameObject:SetActiveEx(true)

        XDataCenter.GachaManager.DoGacha(self.GachaCfg.Id, gachaCount, function(rewardList)
            self.IsReadyForGacha = true
            self.RewardList = rewardList
        end, function()
            self:OnBtnToStartClick()
            self.ImgMask.gameObject:SetActiveEx(false)
            self.IsCanGacha = true
        end)
    end

    self:ClearTimer()
end

function XUiDrawNewYear:ClearTimer()
    self.DrawShowTipGo.gameObject:SetActiveEx(false)
    if self.DrawTipTimeId then
        CS.XScheduleManager.UnSchedule(self.DrawTipTimeId)
        self.DrawTipTimeId = nil
    end
end