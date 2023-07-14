local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiMoeWarRecruitGrid = require("XUi/XUiMoeWar/Recruit/XUiMoeWarRecruitGrid")
local XUiMoeWarRecruitMsgPanel = require("XUi/XUiMoeWar/Recruit/XUiMoeWarRecruitMsgPanel")

--招募通讯和答题
local XUiMoeWarRecruit = XLuaUiManager.Register(XLuaUi, "UiMoeWarRecruit")

function XUiMoeWarRecruit:OnAwake()
    self:AutoAddListener()

    self:InitAssetPanel()
    self:InitCommunicateItem()
    self.ContactButtons = {}
    self.ContactButtonObjList = {}
end

function XUiMoeWarRecruit:OnStart(jumpToHelperId)
    self.JumpToHelperId = jumpToHelperId    --定位到帮手Id的位置并选中
    self:SetCurrOpenMatch()

    self:InitMsgListPanel()
    self:RefreshAssetPanel()
    self:RefreshRecruitCount()
end

function XUiMoeWarRecruit:OnEnable()
    self:Refresh()
    self:StartTimer()
    XDataCenter.MoeWarManager.JudgeGotoMainWhenFightOver()
end

function XUiMoeWarRecruit:OnDisable()
    self:StopTimer()
    self.MsgListPanel:OnDisable()
    for _, contactButtonObj in ipairs(self.ContactButtonObjList) do
        contactButtonObj:OnDisable()
    end
end

function XUiMoeWarRecruit:InitMsgListPanel()
    local data = {
        RefreshContactButtonCb = handler(self, self.RefreshCurrSelectContactButton),
        PlayAnimation = handler(self, self.PlayAnimation),
        ContactButtonClickCallBack = handler(self, self.RequestMoeWarPreparationHelperCommunicate),
        ResetCurrSelectContactBtnIndexCb = handler(self, self.ResetCurrSelectContactBtnIndex),
    }
    self.MsgListPanel = XUiMoeWarRecruitMsgPanel.New(self.MsgList, data)
end

function XUiMoeWarRecruit:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnCommunicateIcon, handler(self, self.OnBtnCommunicateIconClick))
end

function XUiMoeWarRecruit:SetCurrOpenMatch()
    self.CurrOpenMatchId = XMoeWarConfig.GetPreparationCurrOpenMatchId()
    if not self.CurrOpenMatchId then
        self:Close()
        return
    end
    local timeId = XMoeWarConfig.GetPreparationMatchTimeId(self.CurrOpenMatchId)
    self.CurrOpenMatchEndTime = XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XUiMoeWarRecruit:RefreshCurrOpenMatch()
    self:SetCurrOpenMatch()
    self:Refresh()
end

function XUiMoeWarRecruit:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE,
        XEventId.EVENT_MOE_WAR_HELPER_NOTIFY,
    }
end

function XUiMoeWarRecruit:OnNotify(event, ...)
    if event == XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE then
        self:RefreshCurrOpenMatch()
    elseif event == XEventId.EVENT_MOE_WAR_HELPER_NOTIFY then
        self:RefreshContactButtonGroup()
    end
end

function XUiMoeWarRecruit:InitAssetPanel()
    if not self.PanelSpecialTool then
        return
    end
    local actInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    local currencyIdList = actInfo and actInfo.CurrencyId or {}
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)

    XDataCenter.ItemManager.AddCountUpdateListener(currencyIdList, function()
        self.AssetActivityPanel:Refresh(currencyIdList)
    end, self.AssetActivityPanel)
end

function XUiMoeWarRecruit:InitCommunicateItem()
    XDataCenter.ItemManager.AddCountUpdateListener({XDataCenter.ItemManager.ItemId.MoeWarCommunicateItemId}, function()
        self:RefreshRecruitCount()
    end, self.AssetActivityPanel)
end

function XUiMoeWarRecruit:OnBtnCommunicateIconClick()
    local itemId = XDataCenter.ItemManager.ItemId.MoeWarCommunicateItemId
    XLuaUiManager.Open("UiTip", itemId)
end

function XUiMoeWarRecruit:RefreshAssetPanel()
    if not self.AssetActivityPanel then
        return
    end
    local actInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    local currencyIdList = actInfo and actInfo.CurrencyId or {}
    self.AssetActivityPanel:Refresh(currencyIdList)
end

function XUiMoeWarRecruit:Refresh()
    self:RefreshAndCheckActivityTime()
    self:RefreshContactButtonGroup()
    self:RefreshMsgList()
end

function XUiMoeWarRecruit:RefreshMsgList(isNotRefreshMsgPanel)
    if not self.MsgListPanel then
        return
    end
    if isNotRefreshMsgPanel then
        self.MsgListPanel:RefreshAnswerRecord()
    else
        self.MsgListPanel:Refresh()
    end
end

function XUiMoeWarRecruit:RefreshContactButtonGroup()
    if not self.CurrOpenMatchId then return end

    local defaultSelect
    self.HelperIds = XMoeWarConfig.GetPreparationMatchHelperIds(self.CurrOpenMatchId)
    for i, helperId in ipairs(self.HelperIds) do
        local gridObj = self.ContactButtonObjList[i]
        if not gridObj then
            local obj = i == 1 and self.GridPanel or CS.UnityEngine.Object.Instantiate(self.GridPanel, self.Contact)
            gridObj = XUiMoeWarRecruitGrid.New(obj, i)
            self.ContactButtonObjList[i] = gridObj
            self.ContactButtons[i] = XUiHelper.TryGetComponent(obj.transform, "BtnBackground", "XUiButton") 
        end
        gridObj:SetHelperId(helperId)
        gridObj:Refresh()
        gridObj:SetActive(true)

        if self.JumpToHelperId == helperId then
            defaultSelect = i
        end
    end

    local contactCount = #self.ContactButtonObjList
    for i = #self.HelperIds + 1, contactCount do
        self.ContactButtonObjList:SetActive(false)
    end
    self.ContactButtonGroup:Init(self.ContactButtons, function(index) self:OnSelectContactButton(index) end)
    if defaultSelect then
        self.ContactButtonGroup:SelectIndex(defaultSelect)
    end

    self.JumpToHelperId = nil
end

function XUiMoeWarRecruit:RefreshCurrSelectContactButton()
    local currSelectContactButtonIndex = self.CurrSelectContactBtnIndex
    local obj = currSelectContactButtonIndex and self.ContactButtonObjList[currSelectContactButtonIndex]
    if not obj then
        return
    end
    obj:Refresh()
end

function XUiMoeWarRecruit:OnSelectContactButton(index)
    local obj = self.ContactButtonObjList[index]
    local helperId = obj and obj:GetHelperId()
    if self.CurrSelectContactBtnIndex == index then
        if not helperId then
            return
        end

        local helperStatus = XDataCenter.MoeWarManager.GetRecruitHelperStatus(helperId)
        if helperStatus == XMoeWarConfig.PreparationHelperStatus.Communicating or 
            helperStatus == XMoeWarConfig.PreparationHelperStatus.RecruitFinish or
            helperStatus == XMoeWarConfig.PreparationHelperStatus.RecruitFinishAndCommunicating then
            return
        end
    end

    if helperId then
        self:ContactButtonClickCallBack(helperId, index)
    end
end

--通讯点击回调
function XUiMoeWarRecruit:ContactButtonClickCallBack(helperId, currSelectContactBtnIndex)
    local status = XDataCenter.MoeWarManager.GetRecruitHelperStatus(helperId)
    local isDefaltLock = XMoeWarConfig.GetPreparationHelperDefaultLock(helperId)
    local isNotReq = status == XMoeWarConfig.PreparationHelperStatus.RecruitFinish or not isDefaltLock
    if status == XMoeWarConfig.PreparationHelperStatus.Communicating or 
        status == XMoeWarConfig.PreparationHelperStatus.RecruitFinishAndCommunicating or
        status == XMoeWarConfig.PreparationHelperStatus.RecruitFinish then
        self:RequestMoeWarPreparationHelperCommunicate(helperId, currSelectContactBtnIndex, isNotReq)
    else
        local title = CSXTextManagerGetText("TipTitle")
        local desc = CSXTextManagerGetText("MoeWarRecruitTipsDesc")
        local okFunc = function()
            self:RequestMoeWarPreparationHelperCommunicate(helperId, currSelectContactBtnIndex)
        end
        XUiManager.DialogTip(title, desc, XUiManager.DialogType.Normal, handler(self, self.CancelSelect), okFunc)
    end
end

function XUiMoeWarRecruit:CancelSelect()
    self.ContactButtonGroup:CancelSelect()
    if self.CurrSelectContactBtnIndex then
        self.ContactButtonGroup:SelectIndex(self.CurrSelectContactBtnIndex, false)
    end
end

function XUiMoeWarRecruit:ResetCurrSelectContactBtnIndex()
    self.CurrSelectContactBtnIndex = nil
end

function XUiMoeWarRecruit:RequestMoeWarPreparationHelperCommunicate(helperId, currSelectContactBtnIndex, isNotRequest)
    currSelectContactBtnIndex = currSelectContactBtnIndex or self.CurrSelectContactBtnIndex

    local setMsgListPanelHelperIdCb = function(helperId)
        self.MsgListPanel:SetHelperId(helperId)
    end

    local receiveChatHandlerCb = function(chatData)
        self.MsgListPanel:ReceiveChatHandler(chatData)
    end

    local refreshCb = function(helperId, currSelectContactBtnIndex, isNotRefreshMsgPanel)
        self:PlayAnimation("QieHuan")
        local obj = self.ContactButtonObjList[currSelectContactBtnIndex]
        if obj then
            obj:Refresh()
        end
        self:RefreshMsgList(isNotRefreshMsgPanel)
        self.CurrSelectContactBtnIndex = currSelectContactBtnIndex
    end

    local requestFailCb = handler(self, self.CancelSelect)

    if isNotRequest then
        setMsgListPanelHelperIdCb(helperId)
        refreshCb(helperId, currSelectContactBtnIndex)
        return
    end

    XDataCenter.MoeWarManager.RequestMoeWarPreparationHelperCommunicate(helperId, refreshCb, receiveChatHandlerCb, currSelectContactBtnIndex, setMsgListPanelHelperIdCb, requestFailCb)
end

function XUiMoeWarRecruit:StartTimer()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshAndCheckActivityTime()
    end, XScheduleManager.SECOND)
end

function XUiMoeWarRecruit:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoeWarRecruit:RefreshAndCheckActivityTime()
    local nowServerTime = XTime.GetServerNowTimestamp()
    local lastTime = self.CurrOpenMatchEndTime and self.CurrOpenMatchEndTime - nowServerTime or 0
    if lastTime <= 0 then
        self:StopTimer()
        self:Close()
        return
    end
end

function XUiMoeWarRecruit:RefreshRecruitCount()
    local itemId = XDataCenter.ItemManager.ItemId.MoeWarCommunicateItemId
    local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
    self.CommunicateIcon:SetRawImage(icon)

    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    local itemMaxCount = XDataCenter.ItemManager.GetMaxCount(itemId)
    self.NumTxt.text = CSXTextManagerGetText("MoeWarLastRecruitCount", itemCount, itemMaxCount)

    local itemName = XItemConfigs.GetItemNameById(itemId)
    local residueDesc = CSXTextManagerGetText("Residue")
    self.InfoText.text = residueDesc .. itemName
end