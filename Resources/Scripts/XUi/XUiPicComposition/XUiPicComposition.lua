local XUiPicComposition = XLuaUiManager.Register(XLuaUi, "UiPicComposition")
local DialogueMax = 4
local FirstIndex = 1
local TimeFormat = "MM/dd"
local tableInsert = table.insert
local stringGsub = string.gsub
local CSTextManagerGetText = CS.XTextManager.GetText
local PhoneState = {
    Other = 1,
    My = 2,
    Edit = 3
    }

------------草稿到期后需要删除--------------
function XUiPicComposition:OnStart()
    self:AddListener()
    self:InitData()
    self:InitPhonePanel()
    self:InitPicComposition()
    self:SetButtonCallBack()
    self:ChangePhoneState()
    self:InitNormalPhone()
    self:InitEditPhone()
    self:AddRedPointEvent()
    self:UpdateActivityState()
    self.InTimeSchedule = XScheduleManager.ScheduleForever(function()
            if not XDataCenter.MarketingActivityManager.CheckIsIntime() then
                XUiManager.TipText("PicCompositionTimeQver")
                XLuaUiManager.RunMain()
                return
            end
            self:UpdateActivityState()
        end, 1000)
end

function XUiPicComposition:OnEnable()

end

function XUiPicComposition:OnDestroy()
    if self.InTimeSchedule then
        XScheduleManager.UnSchedule(self.InTimeSchedule)
        self.InTimeSchedule = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, self.OpenChatRank, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, self.SetOtherComposition, self)
end

function XUiPicComposition:InitData()
    self.OtherDialogueDataAllList = {}--储存其他玩家的过审作文
    self.MyDialogueDataAllList = {}--储存自己的所有

    self.EditDialogueDataList = {}--储存编辑中的一篇作文
    self.EditOldDialogueDataList = {}

    self.NormalDialogueList = {}
    self.EditDialogueList = {}

    self.Normal = {}
    self.Edit = {}

    self.MyDialogueDataAllList = XDataCenter.MarketingActivityManager.GetMyCompositionDataList()
    local picCompositionCfg = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()

    self.CurActivityId = XDataCenter.MarketingActivityManager.GetNowActivityId()

    self.LikeItem = self.CurActivityId and picCompositionCfg[self.CurActivityId] and
    picCompositionCfg[self.CurActivityId].PraiseItemId or nil

    self.TaskItem = self.CurActivityId and picCompositionCfg[self.CurActivityId] and
    picCompositionCfg[self.CurActivityId].ScheduleItemId or nil


    self.CurPhoneState = PhoneState.Other

    self.HeadPortraitSelect = XUiHeadPortraitSelect.New(self,self.HeadPotrait)
    self.PicCompositionTask = XUiPicCompositionTask.New(self,self.PanelTask)

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, true)

end

function XUiPicComposition:AddRedPointEvent()
    XRedPointManager.AddRedPointEvent(self.IconTaskBtn, self.CheckTaskRedDot, self,
    { XRedPointConditions.Types.CONDITION_PIC_COMPOSITION_TASK_FINISHED })
end

function XUiPicComposition:AddListener()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, self.OpenChatRank, self)
    XEventManager.AddEventListener(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, self.SetOtherComposition, self)
end

function XUiPicComposition:OnTaskChangeSync()
    self.PicCompositionTask:Refresh()
end


function XUiPicComposition:InitPicComposition()
    local PicCompositionInfo = XDataCenter.MarketingActivityManager.GetPicCompositionInfo()
    local beginTime  = XDataCenter.MarketingActivityManager.GetPicCompositionTime(XMarketingActivityConfigs.TimeDataType.BeginTime)
    local endTime  = XDataCenter.MarketingActivityManager.GetPicCompositionTime(XMarketingActivityConfigs.TimeDataType.EndTime)

    if PicCompositionInfo then
        if PicCompositionInfo.Img then
            self.PicRawImage:SetRawImage(PicCompositionInfo.Img)
            self.PicRawImageSmall:SetRawImage(PicCompositionInfo.Img)
        end
        self.TitleText.text = PicCompositionInfo.Name
    end

    local beginTimeStr = XTime.TimestampToGameDateTimeString(beginTime, TimeFormat)
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, TimeFormat)
    self.ActTime.text = CSTextManagerGetText("PicCompositionTotalTime", beginTimeStr, endTimeStr)

    if XDataCenter.MarketingActivityManager.IsCanAutoOpenGuide() then
        self:OnBtnHelpClick()
    end
end

function XUiPicComposition:InitPhonePanel()
    self:InitPhoneObj(self.Normal,self.NormalPhone)
    self:InitPhoneObj(self.Edit,self.EditPhone)
end

function XUiPicComposition:InitPhoneObj(tmp,obj)
    tmp.Transform = obj.transform
    tmp.GameObject = obj.gameObject
    XTool.InitUiObject(tmp)
end

function XUiPicComposition:ChangePhoneState()
    self.Normal.GameObject:SetActiveEx(
        self.CurPhoneState == PhoneState.Other or
        self.CurPhoneState == PhoneState.My)

    self.OtherBtnGroup.gameObject:SetActiveEx(self.CurPhoneState == PhoneState.Other)
    self.Normal.PanelOther.gameObject:SetActiveEx(self.CurPhoneState == PhoneState.Other)

    self.MyBtnGroup.gameObject:SetActiveEx(self.CurPhoneState == PhoneState.My)
    self.Normal.PanelMy.gameObject:SetActiveEx(self.CurPhoneState == PhoneState.My)

    self.Edit.GameObject:SetActiveEx(self.CurPhoneState == PhoneState.Edit)

    if self.CurPhoneState == PhoneState.Edit then
        self:PlayAnimation("EditPhoneEnable")
    else
        self:PlayAnimation("NormalPhoneEnable")
    end
end

function XUiPicComposition:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackRead()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnNew.CallBack = function()
        self:OnBtnNewClick()
    end
    self.BtnHotRank.CallBack = function()
        self:OnBtnHotRankClick()
    end
    self.BtnMyUpLoad.CallBack = function()
        self:OnBtnMyUpLoadClick()
    end
    self.IconTaskBtn.CallBack = function()
        self:OnIconTaskBtnClick()
    end
    self.IconMagnifierBtn.CallBack = function()
        self:OnIconMagnifierBtnClick()
    end
    self.BtnImageClose.CallBack = function()
        self:OnBtnImageCloseClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    self:BindHelpBtnOnly(self.BtnHelp)
end


function XUiPicComposition:OnBtnBackClick()
    if self.CurPhoneState == PhoneState.Other then
        self:Close()
        return
    elseif self.CurPhoneState == PhoneState.My then
        self.CurPhoneState = PhoneState.Other
        self:UpdateOtherDialogueList()
    elseif self.CurPhoneState == PhoneState.Edit then
        self.CurPhoneState = PhoneState.My
    end
    self:ChangePhoneState()
end

function XUiPicComposition:OnBtnBackRead()
    if self.CurPhoneState == PhoneState.Edit then
        self:CheckSave(function ()
            self:OnBtnBackClick()
        end)
    else
        self:OnBtnBackClick()
    end
end

function XUiPicComposition:OnBtnMainUiClick()
    if self.CurPhoneState == PhoneState.Edit then
        self:CheckSave(function ()
            XLuaUiManager.RunMain()
        end)
    else
        XLuaUiManager.RunMain()
    end
end

function XUiPicComposition:CheckSave(cb)
    local IsTextChange = false
    local IsHeadChange = false
    local IsChange = true

    for index,data in pairs(self.EditOldDialogueDataList.Dialogue or {}) do
        if #self.EditOldDialogueDataList.Dialogue == #self.EditDialogueDataList.Dialogue then
            IsHeadChange = IsHeadChange or
            self.EditDialogueDataList.Dialogue[index].CharacterId ~= data.CharacterId

            IsTextChange = IsTextChange or
            self.EditDialogueDataList.Dialogue[index].Content ~= data.Content

            IsChange = IsHeadChange or IsTextChange
        end
        if IsChange then
           break
        end
    end

    if #self.EditDialogueDataList.Dialogue > 0 and IsChange then
        local cancelCb = function ()
            if cb then cb() end
        end
        local confirmCb = function ()
            self:OnBtnSaveClick(
                function ()
                    if cb then cb() end
                end)
        end
        self:TipDialog(cancelCb,confirmCb,"PicCompositionNotSave")
    else
        if cb then cb() end
    end
end

function XUiPicComposition:OnBtnNewClick()

    local upLoadTimeType = XDataCenter.MarketingActivityManager.CheckIsCanUpLoad()
    if upLoadTimeType == XMarketingActivityConfigs.TimeType.After then
        XUiManager.TipText("PicCompositionUpLoadTimeAfter")
        return
    end

    local upLoadMaxCount = XDataCenter.MarketingActivityManager.GetUpLoadMaxCount()
    if upLoadMaxCount == 0 then
        XUiManager.TipText("PicCompositionMaxUpLoad")
        return
    end


    self.CurPhoneState = PhoneState.Edit
    self.EditDialogueDataList = {}
    self.EditOldDialogueDataList = {}
    self.EditDialogueDataList.Dialogue = {}
    self.CurMemoIndex = nil
    self:UpdateEditDialogueList()
    self:ChangePhoneState()
    self:OpenRuleDialog()
end

function XUiPicComposition:OpenRuleDialog()
    local ruleText = stringGsub(CSTextManagerGetText("PicCompositionRuleText"), "\\n", "\n")
    local ruleTitle = CSTextManagerGetText("PicCompositionRuleTitle")
    XUiManager.UiFubenDialogTip(ruleTitle, ruleText)
end

function XUiPicComposition:OnBtnHotRankClick()
    XDataCenter.MarketingActivityManager.InitRankCompositionDataList()
end

function XUiPicComposition:OpenChatRank(IsOpen)
    if IsOpen then
        XLuaUiManager.Open("UiPicChatRank")
    else
        self:ErrorExit()
    end
end

function XUiPicComposition:OnBtnMyUpLoadClick()
    self.CurPhoneState = PhoneState.My
    self:UpdateMyDialogueList()
    self:ChangePhoneState()
end

function XUiPicComposition:OnIconTaskBtnClick()
    self.PicCompositionTask:ShowPanel()
    self.PicCompositionTask:UpdateActiveness()
    self:PlayAnimation("TaskEnable")
end

function XUiPicComposition:OnIconMagnifierBtnClick()
    self.PicPlus.gameObject:SetActiveEx(true)
    self:PlayAnimation("PicPlusEnable")
end

function XUiPicComposition:OnBtnImageCloseClick()
    self.PicPlus.gameObject:SetActiveEx(false)
end

function XUiPicComposition:OnBtnHelpClick()
    local PicCompositionInfo = XDataCenter.MarketingActivityManager.GetPicCompositionInfo()
    local helpId = PicCompositionInfo.HelpId
    local helpCourseTemplate = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    XUiManager.ShowHelpTip(helpCourseTemplate.Function)
end


function XUiPicComposition:OnBtnEditClick()
    local upLoadTimeType = XDataCenter.MarketingActivityManager.CheckIsCanUpLoad()
    if upLoadTimeType == XMarketingActivityConfigs.TimeType.After then
        XUiManager.TipText("PicCompositionUpLoadTimeAfter")
        return
    end

    local upLoadMaxCount = XDataCenter.MarketingActivityManager.GetUpLoadMaxCount()
    if upLoadMaxCount == 0 then
        XUiManager.TipText("PicCompositionMaxUpLoad")
        return
    end

    self.CurPhoneState = PhoneState.Edit
    self.EditDialogueDataList = XTool.Clone(self.MyDialogueDataAllList[self.CurMyDialogueIndex])
    self.EditOldDialogueDataList = XTool.Clone(self.MyDialogueDataAllList[self.CurMyDialogueIndex])
    self.CurMemoIndex = nil
    self:UpdateEditDialogueList()
    self:ChangePhoneState()
end

function XUiPicComposition:OnBtnLikeClick()
    local id = self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].Id
    if XDataCenter.MarketingActivityManager.IsDoPicCompositionLike(id) then
        XUiManager.TipText("PicCompositionLikeHint")
        return
    end
    if self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].UserId == XPlayer.Id then
        XUiManager.TipText("PicCompositionLikeSelf")
        return
    end

    local itemCount = XDataCenter.ItemManager.GetCount(self.LikeItem)
    if not XDataCenter.MarketingActivityManager.CheckItemEnough(itemCount) then
        XUiManager.TipText("PicCompositionNotEnough")
        return
    end

    XDataCenter.MarketingActivityManager.GivePraise(id, function ()
            self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].Hot =
            self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].Hot + 1
            self:UpdateOtherDialogueList()
    end)
end

function XUiPicComposition:OnBtnLeftClick()
    if self.CurPhoneState == PhoneState.Other then
        self.CurOtherDialogueIndex = self.CurOtherDialogueIndex - 1
        if self.CurOtherDialogueIndex < 1 then
            self:GetOtherComposition(XMarketingActivityConfigs.GetType.Before)
        else
            self:UpdateOtherDialogueList()
        end
    elseif self.CurPhoneState == PhoneState.My then
        self.CurMyDialogueIndex = self.CurMyDialogueIndex > 1 and
        (self.CurMyDialogueIndex - 1) or (self.CurMyDialogueIndex)
        self:UpdateMyDialogueList()
    end
    self:PlayAnimation("NormalPhoneEnable")
end

function XUiPicComposition:OnBtnRightClick()
    if self.CurPhoneState == PhoneState.Other then
        self.CurOtherDialogueIndex = self.CurOtherDialogueIndex + 1
        if self.CurOtherDialogueIndex > #self.OtherDialogueDataAllList then
            self:GetOtherComposition(XMarketingActivityConfigs.GetType.After)
        else
            self:UpdateOtherDialogueList()
        end
    elseif self.CurPhoneState == PhoneState.My then
        self.CurMyDialogueIndex = self.CurMyDialogueIndex < #self.MyDialogueDataAllList and
        (self.CurMyDialogueIndex + 1) or self.CurMyDialogueIndex
        self:UpdateMyDialogueList()
    end
    self:PlayAnimation("NormalPhoneEnable")
end

function XUiPicComposition:HideHeadPortraitSelect()
    self.HeadPotraitSelect.GameObject:SetActiveEx(false)
end

function XUiPicComposition:UpdateActivityState()
    local upLoadTimeType = XDataCenter.MarketingActivityManager.CheckIsCanUpLoad()
    local upLoadMaxCount = XDataCenter.MarketingActivityManager.GetUpLoadMaxCount()
    local upLoadDayCount = XDataCenter.MarketingActivityManager.GetUpLoadDayCount()
    local upLoadBeginTime = XDataCenter.MarketingActivityManager.GetPicCompositionTime(XMarketingActivityConfigs.TimeDataType.UploadBeginTime)
    local upLoadEndTime = XDataCenter.MarketingActivityManager.GetPicCompositionTime(XMarketingActivityConfigs.TimeDataType.UploadEndTime)
    local endTime = XDataCenter.MarketingActivityManager.GetPicCompositionTime(XMarketingActivityConfigs.TimeDataType.EndTime)
    local nowTime = XTime.GetServerNowTimestamp()

    local btnNewStatus = (upLoadTimeType == XMarketingActivityConfigs.TimeType.After or upLoadMaxCount == 0) and
    CS.UiButtonState.Disable or CS.UiButtonState.Normal

    local btnUpLoadStatus = (upLoadTimeType ~= XMarketingActivityConfigs.TimeType.In or upLoadDayCount == 0 or upLoadMaxCount == 0) and
    CS.UiButtonState.Disable or CS.UiButtonState.Normal


    self.Edit.UploadNum.gameObject:SetActiveEx(upLoadTimeType == XMarketingActivityConfigs.TimeType.In)

    self.IconTaskBtn.gameObject:SetActiveEx(upLoadTimeType ~= XMarketingActivityConfigs.TimeType.Before)


    self.BtnNew:SetButtonState(btnNewStatus)
    self.Edit.BtnUpLoad:SetButtonState(btnUpLoadStatus)

    if upLoadTimeType == XMarketingActivityConfigs.TimeType.Before then
        local timeStr = upLoadBeginTime - nowTime
        timeStr = timeStr > 0 and timeStr or 0
        self.TimeCount.text = CSTextManagerGetText("PicCompositionUpLoadOpenTimeCount",
            XUiHelper.GetTime(timeStr, XUiHelper.TimeFormatType.ACTIVITY))
    elseif upLoadTimeType == XMarketingActivityConfigs.TimeType.In then
        local timeStr = upLoadEndTime - nowTime
        timeStr = timeStr > 0 and timeStr or 0
        self.TimeCount.text = CSTextManagerGetText("PicCompositionUpLoadOverTimeCount",
            XUiHelper.GetTime(timeStr, XUiHelper.TimeFormatType.ACTIVITY))
    elseif upLoadTimeType == XMarketingActivityConfigs.TimeType.After then
        local timeStr = endTime - nowTime
        timeStr = timeStr > 0 and timeStr or 0
        self.TimeCount.text = CSTextManagerGetText("PicCompositionOverTimeCount",
            XUiHelper.GetTime(timeStr, XUiHelper.TimeFormatType.ACTIVITY))
    end

end

function XUiPicComposition:CheckTaskRedDot(count)
    self.IconTaskBtn:ShowReddot(count >= 0)
end

function XUiPicComposition:ErrorExit()
    XUiManager.TipText("PicCompositionNetError")
    XLuaUiManager.RunMain()
end
-----------------------------NormalPhone-------------------------------
function XUiPicComposition:InitNormalPhone()

    self:InitBtnGroup()
    self:SetNormalPhoneButtonCallBack()
    self.CurMyDialogueIndex = 1
    self.CurOtherDialogueIndex = 1
    self.Normal.DialogueObj = {
        self.Normal.Dialogue1,
        self.Normal.Dialogue2,
        self.Normal.Dialogue3,
        self.Normal.Dialogue4
    }

    for index = 1,DialogueMax do
        self.NormalDialogueList[index] = XUiGridNormalDialogue.New(self.Normal.DialogueObj[index],self)
    end
    self.Normal.BtnGroup:SelectIndex(self.Normal.CurSortType)
end

function XUiPicComposition:InitBtnGroup()
    self.Normal.CurSortType = XMarketingActivityConfigs.SortType.Hot
    self.Normal.BtnList = {
        [1] = self.Normal.BtnHot,
        [2] = self.Normal.BtnTime}

    self.Normal.BtnGroup:Init(self.Normal.BtnList, function(index) self:SelectSortType(index) end)

end

function XUiPicComposition:UpdateOtherDialogueList()
    if #self.OtherDialogueDataAllList == 0 then
        local upLoadTimeType = XDataCenter.MarketingActivityManager.CheckIsCanUpLoad()
        self:SetOtherDialogueStateShow(false)
        if upLoadTimeType == XMarketingActivityConfigs.TimeType.Before then
            local bTime,eTime = XDataCenter.MarketingActivityManager.GetUpLoadTime(false)
            self.Normal.TipsText.text = CSTextManagerGetText("PicCompositionUpLoadTimeText")
            self.Normal.TimeText.text = string.format("%s--%s",bTime,eTime)
            self.Normal.TimeText.gameObject:SetActiveEx(true)
        else
            self.Normal.TipsText.text = CSTextManagerGetText("NotHaveOtherComposition")
            self.Normal.TimeText.gameObject:SetActiveEx(false)
        end
    else
        if self.OtherDialogueDataAllList[self.CurOtherDialogueIndex] then
            local hot = self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].Hot or 0
            local name = self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].UserName
            local id = self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].Id
            local IsLike = XDataCenter.MarketingActivityManager.IsDoPicCompositionLike(id)
            local dialogueDataList = self.OtherDialogueDataAllList[self.CurOtherDialogueIndex].Dialogue
            local btnStatus = IsLike and CS.UiButtonState.Select or CS.UiButtonState.Normal

            self.Normal.OtherHotNum.text = XMarketingActivityConfigs.GetCountUnitChange(hot)
            self.Normal.PlayerName.text = CSTextManagerGetText("PicCompositionPlayerName",name)

            self:SetOtherDialogueStateShow(true)
            self.Normal.BtnLike:SetButtonState(btnStatus)

            for index = 1,DialogueMax do
                self.NormalDialogueList[index]:Update(dialogueDataList[index])
            end
        end
    end

    local item = XDataCenter.ItemManager.GetItem(self.LikeItem)
    if item then
        self.AssetActivityPanel:Refresh({self.LikeItem})
    else
        self.AssetActivityPanel:Refresh(nil)
    end

end

function XUiPicComposition:SetOtherDialogueStateShow(IsShow)
    self.Normal.Tips.gameObject:SetActiveEx(not IsShow)

    self.Normal.PanelChatView.gameObject:SetActiveEx(IsShow)

    self.Normal.OtherLike.gameObject:SetActiveEx(IsShow)

    self.Normal.PlayerName.gameObject:SetActiveEx(IsShow)

    local curAfterCount = XDataCenter.MarketingActivityManager.GetPicCompositionAfterStartIndex()
    local allCount = XDataCenter.MarketingActivityManager.GetPicCompositionAllCount()
    local maxCount = XDataCenter.MarketingActivityManager.GetPicCompositionGetMaxCount()
    local IsRightBtnNotShow
    if maxCount == #self.OtherDialogueDataAllList then
        IsRightBtnNotShow = curAfterCount == allCount and self.CurOtherDialogueIndex == #self.OtherDialogueDataAllList
    else
        IsRightBtnNotShow = curAfterCount > allCount and self.CurOtherDialogueIndex == #self.OtherDialogueDataAllList
    end
    IsRightBtnNotShow = IsRightBtnNotShow or #self.OtherDialogueDataAllList == 0
    self.Normal.BtnRight.gameObject:SetActiveEx(not IsRightBtnNotShow)

    local curBeforCount = XDataCenter.MarketingActivityManager.GetPicCompositionBeforStartIndex()
    local IsLeftBtnNotShow = #self.OtherDialogueDataAllList == 0 or curBeforCount == 0 and self.CurOtherDialogueIndex == 1
    self.Normal.BtnLeft.gameObject:SetActiveEx(not IsLeftBtnNotShow)
end

function XUiPicComposition:UpdateMyDialogueList()
    if #self.MyDialogueDataAllList == 0 then
        self:SetMyDialogueStateShow(false)
        self.Normal.TimeText.gameObject:SetActiveEx(false)
        self.Normal.TipsText.text = CSTextManagerGetText("NotHaveMyComposition")
    else
        if self.MyDialogueDataAllList[self.CurMyDialogueIndex] then
            local hot = self.MyDialogueDataAllList[self.CurMyDialogueIndex].Hot or 0
            self.Normal.MyHotNum.text = XMarketingActivityConfigs.GetCountUnitChange(hot)
            local dialogueDataList = self.MyDialogueDataAllList[self.CurMyDialogueIndex].Dialogue
            self:SetMyDialogueStateShow(true)
            for index = 1,DialogueMax do
                self.NormalDialogueList[index]:Update(dialogueDataList[index])
            end
        end
    end
end

function XUiPicComposition:SetMyDialogueStateShow(IsShow)
    self.Normal.FailedPass.gameObject:SetActiveEx(IsShow and
        self.MyDialogueDataAllList[self.CurMyDialogueIndex].Type ==
        XMarketingActivityConfigs.CompositionType.UnExamine)

    self.Normal.Examine.gameObject:SetActiveEx(IsShow and
        self.MyDialogueDataAllList[self.CurMyDialogueIndex].Type ==
        XMarketingActivityConfigs.CompositionType.Examining)

    self.Normal.UpLoad.gameObject:SetActiveEx(IsShow and
        self.MyDialogueDataAllList[self.CurMyDialogueIndex].Type ==
        XMarketingActivityConfigs.CompositionType.Memo)

    self.Normal.Pass.gameObject:SetActiveEx(IsShow and
        self.MyDialogueDataAllList[self.CurMyDialogueIndex].Type ==
        XMarketingActivityConfigs.CompositionType.Examined)

    self.Normal.MyLike.gameObject:SetActiveEx(IsShow and
        self.MyDialogueDataAllList[self.CurMyDialogueIndex].Type ==
        XMarketingActivityConfigs.CompositionType.Examined)

    self.Normal.BtnEdit.gameObject:SetActiveEx(IsShow and
        self.MyDialogueDataAllList[self.CurMyDialogueIndex].Type ==
        XMarketingActivityConfigs.CompositionType.Memo)

    self.Normal.PanelChatView.gameObject:SetActiveEx(IsShow)

    self.Normal.Tips.gameObject:SetActiveEx(not IsShow)

    local IsLeftBtnNotShow = #self.MyDialogueDataAllList == 0 or self.CurMyDialogueIndex == 1
    self.Normal.BtnLeft.gameObject:SetActiveEx(not IsLeftBtnNotShow)

    local IsRightBtnNotShow = #self.MyDialogueDataAllList == 0 or self.CurMyDialogueIndex == #self.MyDialogueDataAllList
    self.Normal.BtnRight.gameObject:SetActiveEx(not IsRightBtnNotShow)

    self.Normal.FailedPassText.text = CSTextManagerGetText("PicCompositionFailedPass")
    self.Normal.ExamineText.text = CSTextManagerGetText("PicCompositionExamine")
    self.Normal.UpLoadText.text = CSTextManagerGetText("PicCompositionNotUpLoad")
    self.Normal.PassText.text = CSTextManagerGetText("PicCompositionPass")
end

function XUiPicComposition:SelectSortType(index)
    self.CurSortType = index
    XDataCenter.MarketingActivityManager.ResetPicCompositionStartIndex()
    self:GetOtherComposition(XMarketingActivityConfigs.GetType.After)
    self:PlayAnimation("NormalPhoneEnable")
end

function XUiPicComposition:GetOtherComposition(type)
    self.Normal.GameObject:SetActiveEx(false)
    XDataCenter.MarketingActivityManager.InitOtherCompositionDataList(self.CurSortType,type)
end

function XUiPicComposition:SetOtherComposition(IsGet,type)
    if IsGet then
        self.OtherDialogueDataAllList = XDataCenter.MarketingActivityManager.GetOtherCompositionDataList(self.CurSortType)
        self.CurOtherDialogueIndex = type == XMarketingActivityConfigs.GetType.After and
        1 or #self.OtherDialogueDataAllList
        self:UpdateOtherDialogueList()
    else
        self:ErrorExit()
    end
    self.Normal.GameObject:SetActiveEx(true)
end

function XUiPicComposition:SetNormalPhoneButtonCallBack()
    self.Normal.BtnLeft.CallBack = function()
        self:OnBtnLeftClick()
    end
    self.Normal.BtnRight.CallBack = function()
        self:OnBtnRightClick()
    end
    self.Normal.BtnEdit.CallBack = function()
        self:OnBtnEditClick()
    end
    self.Normal.BtnLike.CallBack = function()
        self:OnBtnLikeClick()
    end
    --Zhang
end
-----------------------------NormalPhone-------------------------------
------------------------------EditPhone--------------------------------
function XUiPicComposition:InitEditPhone()
    self:SetEditPhoneButtonCallBack()
    self.Edit.DialogueObj = {
        self.Edit.Dialogue1,
        self.Edit.Dialogue2,
        self.Edit.Dialogue3,
        self.Edit.Dialogue4
        }

    for index = 1,DialogueMax do
        self.EditDialogueList[index] = XUiGridEditDialogue.New(self.Edit.DialogueObj[index],self)
    end
end

function XUiPicComposition:SetEditPhoneButtonCallBack()
    self.Edit.BtnSave.CallBack = function()
        self:OnBtnSaveClick()
    end

    self.Edit.BtnUpLoad.CallBack = function()
        self:OnBtnUpLoadClick()
    end
end

function XUiPicComposition:UpdateEditDialogueList()
    for index = 1,DialogueMax do
        local IsCanEdit = false
        if index == FirstIndex then
            IsCanEdit = true
        else
            if self.EditDialogueDataList.Dialogue[index - 1] then
                IsCanEdit = true
            end
        end
        self.EditDialogueList[index]:Update(index,IsCanEdit)
    end

    local upLoadMaxCount = XDataCenter.MarketingActivityManager.GetUpLoadMaxCount()
    self.Edit.UploadNum.text = CSTextManagerGetText("PicCompositionUpLoadCount",upLoadMaxCount)
end

function XUiPicComposition:CheckEditDialogueClear()
    for i = #self.EditDialogueDataList.Dialogue, 1, -1 do
        if self.EditDialogueDataList.Dialogue[i].IsClear then
            table.remove(self.EditDialogueDataList.Dialogue, i)
        end
    end
    self:UpdateEditDialogueList()
end

function XUiPicComposition:OnBtnSaveClick(cb)
    local dialogueList = {}
    local IsCanSave = true
    local IsNotEmpty = false
    for _,dialogueData in pairs(self.EditDialogueDataList.Dialogue or {}) do
        local tmpData = {}
        if dialogueData.CharacterId then
            tmpData.CharacterId = dialogueData.CharacterId
        end
        if dialogueData.Content and #dialogueData.Content > 0 and (not string.match(dialogueData.Content, "^[%s]+$"))then
            tmpData.Content = dialogueData.Content
            IsCanSave = IsCanSave and true
        else
            IsCanSave = IsCanSave and false
        end
        IsNotEmpty = true
        tableInsert(dialogueList,tmpData)
    end

    if IsCanSave and IsNotEmpty then
        XDataCenter.MarketingActivityManager.SaveMemoDialogue(self.EditDialogueDataList.Dialogue,self.EditDialogueDataList.MemoId,function ()
                self.MyDialogueDataAllList = XDataCenter.MarketingActivityManager.GetMyCompositionDataList()
                self:UpdateMyDialogueList()
                self:OnBtnBackClick()
                if cb then cb() end
        end)
    else
        if not IsNotEmpty then
            XUiManager.TipText("PicCompositionAllEmpty")
        else
            XUiManager.TipText("PicCompositionHaveEmpty")
        end
    end

end

function XUiPicComposition:OnBtnUpLoadClick()
    local dialogueList = {}

    local IsCanUpLoad = true
    local IsNotEmpty = false

    local upLoadTimeType = XDataCenter.MarketingActivityManager.CheckIsCanUpLoad()

    if upLoadTimeType == XMarketingActivityConfigs.TimeType.Out then
        XUiManager.TipText("PicCompositionTimeOut")
        return
    end

    if upLoadTimeType == XMarketingActivityConfigs.TimeType.Before then
        XUiManager.TipText("PicCompositionUpLoadTimeBefor")
        return
    end

    if upLoadTimeType == XMarketingActivityConfigs.TimeType.After then
        XUiManager.TipText("PicCompositionUpLoadTimeAfter")
        return
    end

    local upLoadMaxCount = XDataCenter.MarketingActivityManager.GetUpLoadMaxCount()
    if upLoadMaxCount == 0 then
        XUiManager.TipText("PicCompositionMaxUpLoad")
        return
    end

    local upLoadDayCount = XDataCenter.MarketingActivityManager.GetUpLoadDayCount()
    if upLoadDayCount == 0 then
        XUiManager.TipText("PicCompositionDayUpLoad")
        return
    end

    for _,dialogueData in pairs(self.EditDialogueDataList.Dialogue or {}) do
        local tmpData = {}
        if dialogueData.CharacterId then
            tmpData.CharacterId = dialogueData.CharacterId
        end
        if dialogueData.Content and #dialogueData.Content > 0 and (not string.match(dialogueData.Content, "^[%s]+$"))then
            tmpData.Content = dialogueData.Content
            IsCanUpLoad = IsCanUpLoad and true
        else
            IsCanUpLoad = IsCanUpLoad and false
        end
        IsNotEmpty = true
        tableInsert(dialogueList,tmpData)
    end

    if IsCanUpLoad and IsNotEmpty then
        self:TipDialog(nil,function ()
                XDataCenter.MarketingActivityManager.GiveUploadComment(dialogueList, function ()
                        XDataCenter.MarketingActivityManager.DelectMemoDialogue(self.EditDialogueDataList.MemoId)
                        self.MyDialogueDataAllList = XDataCenter.MarketingActivityManager.GetMyCompositionDataList()
                        self:UpdateMyDialogueList()
                        self:OnBtnBackClick()
                    end)
        end,"PicCompositionUpLoadRead")
    else
        if not IsNotEmpty then
            XUiManager.TipText("PicCompositionAllEmpty")
        else
            XUiManager.TipText("PicCompositionHaveEmpty")
        end
    end
end

function XUiPicComposition:TipDialog(cancelCb, confirmCb,TextKey)
    CsXUiManager.Instance:Open("UiDialog", CSTextManagerGetText("TipTitle"), CSTextManagerGetText(TextKey),
    XUiManager.DialogType.Normal, cancelCb, confirmCb)
end
------------------------------EditPhone--------------------------------






