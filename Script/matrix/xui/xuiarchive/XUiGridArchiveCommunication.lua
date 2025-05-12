local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveCommunication = XClass(XUiNode, "XUiGridArchiveCommunication")

function XUiGridArchiveCommunication:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchiveCommunication:SetButtonCallBack()
    self.BtnPlay.CallBack = function()
        self:OnBtnPlay()
    end
end

function XUiGridArchiveCommunication:OnBtnPlay()
    XLuaUiManager.Open("UiFunctionalOpen", self.Chapter:GetCfg(), true, false)
end

function XUiGridArchiveCommunication:UpdateGrid(chapter)
    if chapter then
        self.Chapter = chapter
        self:SetMonsterData(chapter)
    end
end

function XUiGridArchiveCommunication:SetMonsterData(chapter)
    if chapter:GetCommunicationIcon() then
        self.RawImage:SetRawImage(chapter:GetCommunicationIcon())
    end
    self.CommunicationText.text = chapter:GetName() or ""
end

return XUiGridArchiveCommunication