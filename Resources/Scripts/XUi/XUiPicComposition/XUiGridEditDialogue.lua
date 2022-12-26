XUiGridEditDialogue = XClass(nil, "XUiGridEditDialogue")
local EditIcon = CS.XGame.ClientConfig:GetString("PicCompositionEditIcon")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridEditDialogue:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base

    XTool.InitUiObject(self)
    self:Init()
    self:SetButtonCallBack()

end

function XUiGridEditDialogue:Init()
    local picCompositionCfg = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
    local activityId = XDataCenter.MarketingActivityManager.GetNowActivityId()
    self.TxtEdit.characterLimit = picCompositionCfg[activityId] and picCompositionCfg[activityId].ContentMaxLength or 0
end

function XUiGridEditDialogue:AddListener()
    XEventManager.AddEventListener(XEventId.EVENT_PICCOMPOSITION_GET_WORD,self.SetTrueWord,self)
end

function XUiGridEditDialogue:RemoveListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_PICCOMPOSITION_GET_WORD,self.SetTrueWord,self)
end

function XUiGridEditDialogue:SetButtonCallBack()
    self.BtnEdit.CallBack = function()
        self:OnBtnEditClick()
    end

    self.BtnView.CallBack = function()
        self:OnBtnViewClick()
    end

    self.BtnClear.CallBack = function()
        self:OnBtnClearClick()
    end

    self.TxtEdit.onValueChanged:AddListener(function()
            self:OnTextChange()
        end)

    self.TxtEdit.onEndEdit:AddListener(function()
            self:OnTextInputEnd()
        end)
end

function XUiGridEditDialogue:Update(index,IsCanEdit)
    self.DialogueIndex = index
    self.TxtEdit.text = ""
    self.TxtWord.text = ""
    self.ImgHead:SetRawImage(EditIcon)
    self.PanelMsg.gameObject:SetActiveEx(false)
    self.BtnClear.gameObject:SetActiveEx(false)

    self:ShowEditText(true)
    if self.Base.EditDialogueDataList.Dialogue[index] then
        if self.Base.EditDialogueDataList.Dialogue[index].CharacterId then
            local info = XMarketingActivityConfigs.GetCompositionCharacterConfigById(self.Base.EditDialogueDataList.Dialogue[index].CharacterId)
            if info then
                self.PanelMsg.gameObject:SetActiveEx(true)
                self.BtnClear.gameObject:SetActiveEx(true)
                self.ImgHead:SetRawImage(info.Icon)
                self.TxtName.text = info.Name
            end
        end
        local content = self.Base.EditDialogueDataList.Dialogue[index].Content
        if content and #content > 0 then
            self:ShowEditText(false)
            self.TxtWord.text = content
        end
        self.GameObject:SetActiveEx(true)
        self:AddListener()
    else
        self.GameObject:SetActiveEx(IsCanEdit)
        self:RemoveListener()
    end
end

function XUiGridEditDialogue:OnBtnEditClick()
    self:ShowEditText(true)
    self.TxtEdit.text = self.TxtWord.text
    self.TxtEdit:ActivateInputField()
end

function XUiGridEditDialogue:OnBtnViewClick()
    if not self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex] then
        self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex] = {}
    end
    self.Base.HeadPortraitSelect:PreviewHeadPortrait(self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex],function ()
        self.Base:UpdateEditDialogueList()
    end,function ()
        local content = self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex].Content
        if not content or #content == 0 then
            self:OnBtnClearClick()
        end
    end)
end

function XUiGridEditDialogue:OnBtnClearClick()
    self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex].IsClear = true
    self.Base:CheckEditDialogueClear()
end

function XUiGridEditDialogue:OnTextChange()

end

function XUiGridEditDialogue:OnTextInputEnd()
    if #self.TxtEdit.text > 0 then
        self:ShowEditText(false)
    end
    --self.TxtWord.text = self.TxtEdit.text
    self.TxtWord.text = CSTextManagerGetText("PicCompositionWaitWord")
    self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex].Content = self.TxtWord.text
    self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex].StartIndex = self.DialogueIndex
    XDataCenter.MarketingActivityManager.GetTrueWord(self.TxtEdit.text,nil,nil,self.DialogueIndex)
    --self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex].Content = self.TxtWord.text
end

function XUiGridEditDialogue:SetTrueWord(IsGet,trueWord,index)
    local dialogue = self.Base.EditDialogueDataList.Dialogue[self.DialogueIndex]
    if dialogue and index == dialogue.StartIndex then
        if IsGet then
            self.TxtWord.text = trueWord
            dialogue.Content = self.TxtWord.text
        else
            self:ErrorExit()
        end
        dialogue.StartIndex = self.DialogueIndex
    end
end

function XUiGridEditDialogue:ShowEditText(IsShowEdit)
    self.TxtEdit.gameObject:SetActiveEx(IsShowEdit)
    self.TxtWord.gameObject:SetActiveEx(not IsShowEdit)
end

function XUiGridEditDialogue:ErrorExit()
    XUiManager.TipText("PicCompositionNetError")
    XLuaUiManager.RunMain()
end

