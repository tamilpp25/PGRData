local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveEmail = XClass(XUiNode, "XUiGridArchiveEmail")

local GridState = {Close = false ,Open = true}
local TabState = {
    Normal = 0,
    Press = 1,
    Select = 2,
    Disable = 3,
}
function XUiGridArchiveEmail:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchiveEmail:SetButtonCallBack()
    self.BtnSelect.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchiveEmail:OnBtnSelect()

end

function XUiGridArchiveEmail:UpdateGrid(chapter,stateList)
    if chapter then
        self:SetMonsterData(chapter,stateList)
    end
end

function XUiGridArchiveEmail:SetMonsterData(chapter,stateList)
    if chapter:GetNpcHandIcon() then
        self.RawImage:SetRawImage(chapter:GetNpcHandIcon())
    end
    self.TitleText.text = chapter:GetTitle() or ""
    self.EmailSender.text = chapter:GetSendName() or ""
    self.ContentsText.text = string.gsub(chapter:GetContent(), "\\n", "\n")

    local state = stateList and stateList[chapter:GetId()] or false
    if state == GridState.Close then
        self.EmailContent.gameObject:SetActiveEx(false)
        self.BtnSelect:SetButtonState(TabState.Normal)
    elseif state == GridState.Open then
        self.EmailContent.gameObject:SetActiveEx(true)
        self.BtnSelect:SetButtonState(TabState.Select)
    end

    self.EmailContentNote:SetDirty()
    self.EmalItemNode:SetDirty()
    self.Contents.sizeDelta = CS.UnityEngine.Vector2(self.EmailTitle.sizeDelta.x, self.Contents.sizeDelta.y)
end



return XUiGridArchiveEmail