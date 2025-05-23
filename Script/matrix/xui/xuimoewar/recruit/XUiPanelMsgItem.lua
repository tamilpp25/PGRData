local MoeWarRecruitAnimaContentShowTime = CS.XGame.ClientConfig:GetInt("MoeWarRecruitAnimaContentShowTime")
local UObjIsNil = XTool.UObjIsNil
local IsNumberValid = XTool.IsNumberValid

local XUiPanelMsgItem = XClass(nil, "XUiPanelMsgItem")

function XUiPanelMsgItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelMsgItem:Refresh(data, helperId)
    local questionId = data.QuestionId
    local desc = data.Desc
    local recruitMsgType = data.RecruitMsgType
    local IsPlayMsgAnima = data.IsPlayMsgAnima
    local IsOverPlayMsgAnima = data.IsOverPlayMsgAnima

    self:StopTimer()
    
    if self.TxtWord then
        self.TxtWord.text = desc
    end

    local name
    local headRawImage = XUiHelper.TryGetComponent(self.Head.transform, "StandIcon", "RawImage")
    local isCheckAnima = false 
    if recruitMsgType == XMoeWarConfig.RecruitMsgType.OtherMsg then
        local questionType = XMoeWarConfig.GetPreparationQuestionType(questionId)
        local questionIsRight = XDataCenter.MoeWarManager.GetRecruitQuestionIsRight(helperId, questionId)
        local answerId = XDataCenter.MoeWarManager.GetRecruitAnswerId(helperId, questionId)
        local headIcon = XMoeWarConfig.GetPreparationQuestionHelperIcon(questionId)

        --回答错误或招募失败，播放完动画才显示内容
        if not IsOverPlayMsgAnima and IsPlayMsgAnima then
            isCheckAnima = true
        end

        headRawImage:SetRawImage(headIcon)
        name = XMoeWarConfig.GetPreparationQuestionHelperName(questionId)
    elseif recruitMsgType == XMoeWarConfig.RecruitMsgType.GiftThank then
        local headIcon = XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(helperId)
        local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
        name = XEntityHelper.GetCharacterName(robotId)
        headRawImage:SetRawImage(headIcon)
    else
        name = XPlayer.Name
        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    end
    if self.TxtName then
        self.TxtName.text = name
    end

    self:CheckSwitchAnimaContent(isCheckAnima)
    data.IsOverPlayMsgAnima = true
end

function XUiPanelMsgItem:CheckSwitchAnimaContent(isCheck)
    self:SwitchAnimaContentIsShow(isCheck)
    if isCheck then
        if self.PauseInsertDynamicTimer then
            self.PauseInsertDynamicTimer()
        end
        self.Timer = XScheduleManager.ScheduleOnce(function()
            self:SwitchAnimaContentIsShow(false)
            if self.CancelPauseInsertDynamicTimer then
                self.CancelPauseInsertDynamicTimer(true)
            end
        end, MoeWarRecruitAnimaContentShowTime)
    end
end

function XUiPanelMsgItem:SwitchAnimaContentIsShow(isShow)
    if not UObjIsNil(self.AnimaContent) then
        self.AnimaContent.gameObject:SetActiveEx(isShow)
    end
    if not UObjIsNil(self.Content) then
        self.Content.alpha = isShow and 0 or 1
    end
end

function XUiPanelMsgItem:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiPanelMsgItem