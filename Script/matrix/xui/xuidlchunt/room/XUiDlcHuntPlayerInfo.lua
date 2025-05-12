local XUiDlcHuntPersonalSupportGrid = require("XUi/XUiDlcHunt/Room/XUiDlcHuntPersonalSupportGrid")

---@class XUiDlcHuntPlayerInfo:XLuaUi
local XUiDlcHuntPlayerInfo = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPlayerInfo")

function XUiDlcHuntPlayerInfo:Ctor()
    ---@type XDlcHuntPlayerDetail
    self._Data = false
    ---@type XUiDlcHuntBagGridChip
    self._UiChip = false
    ---@type XUiDlcHuntBagGridChip
    self._UiChipAssistant = false
end

function XUiDlcHuntPlayerInfo:OnAwake()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnCopy, self.OnBtnCopyClick)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick)
    self:RegisterClickEvent(self.BtnReport, self.OnBtnReportClick)
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnDlcBlueS, self.OnBtnDetailClick)
    --self:RegisterClickEvent(self.BtnLike, self.OnBtnLikeClick)
    self._UiChip = XUiDlcHuntPersonalSupportGrid.New(self.GridChip)
    self._UiChip:SetClickDisable()
    self._UiChipAssistant = XUiDlcHuntPersonalSupportGrid.New(self.GridChipHelp)
    self._UiChipAssistant:SetClickDisable()
end

---@param data XDlcHuntPlayerDetail
function XUiDlcHuntPlayerInfo:OnStart(data)
    self._Data = data
    local headPortraitId, headFrameId = data:GetHeadInfo()
    XUiPlayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)
    self.TxtLevel.text = data:GetLevel()
    self.TxtName.text = data:GetPlayerName()
    self.TxtId.text = data:GetPlayerId()
    self.TxtSign.text = data:GetSign()
    self.PanelChipHelp = self.PanelChip
    self.RawImage:SetRawImage(data:GetCharacterIcon())
    self.Text.text = data:GetCharacterName()
    self:UpdateLikeNum()
    self.TextAbility.text = XUiHelper.GetText("DlcHuntFightingPower", data:GetFightingPower())

    local mainChip = self._Data:GetMainChip()
    if mainChip and not mainChip:IsEmpty() then
        self._UiChip:Update(mainChip)
        self._UiChip.GameObject:SetActiveEx(true)
    else
        self._UiChip.GameObject:SetActiveEx(false)
    end

    local assistantChip = self._Data:GetAssistantChip()
    if assistantChip and not assistantChip:IsEmpty() then
        self._UiChipAssistant:Update(assistantChip)
        self._UiChipAssistant.GameObject:SetActiveEx(true)
    else
        self._UiChipAssistant.GameObject:SetActiveEx(false)
    end

    if XDataCenter.SocialManager.CheckIsFriend(data:GetPlayerId()) then
        self.BtnChat.gameObject:SetActiveEx(true)
    else
        self.BtnChat.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntPlayerInfo:OnBtnCopyClick()
    XTool.CopyToClipboard(self.TxtId.text)
end

function XUiDlcHuntPlayerInfo:OnBtnChatClick()
    XLuaUiManager.Close("UiChatServeMain")

    if XLuaUiManager.IsUiShow("UiSocial") then
        XLuaUiManager.CloseWithCallback("UiPlayerInfo", function()
            XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self._Data:GetPlayerId())
        end)
    else
        XLuaUiManager.Open("UiSocial", function()
            XEventManager.DispatchEvent(XEventId.EVENT_FRIEND_OPEN_PRIVATE_VIEW, self._Data:GetPlayerId())
        end)
    end
end

function XUiDlcHuntPlayerInfo:OnBtnReportClick()
    local data = { Id = self._Data:GetPlayerId(), TitleName = self._Data:GetPlayerName(), PlayerLevel = self._Data:GetLevel() }
    XLuaUiManager.Open("UiReport", data)
end

--拉黑
function XUiDlcHuntPlayerInfo:OnBtnBlockClick()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialFriend) then
        XUiManager.TipText("FunctionNotOpen")
        return
    end

    if XDataCenter.SocialManager.GetBlackData(self._Data:GetPlayerId()) then
        XUiManager.TipText("SocialBlackEnterOver")
        return
    end

    local content = CS.XTextManager.GetText("SocialBlackTipsDesc")
    local sureCallback = function()
        local cb = function()
            --self:UpdateInfo(self.Tab.BaseInfo)
        end
        XDataCenter.SocialManager.RequestBlackPlayer(self.Data.Id, cb)
    end
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiDlcHuntPlayerInfo:OnBtnDetailClick()
    XLuaUiManager.Open("UiDlcHuntAttrDialog", { ChipGroup = self._Data:GetChipGroup() })
end

--function XUiDlcHuntPlayerInfo:OnBtnLikeClick()
--XDataCenter.DlcRoomManager.AddLike(self._Data:GetPlayerId())
--self._Data:AddLike()
--self:UpdateLikeNum()
--end

function XUiDlcHuntPlayerInfo:UpdateLikeNum()
    self.TxtLikeNum.text = self._Data:GetLike()
end

return XUiDlcHuntPlayerInfo