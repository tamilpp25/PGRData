--白色情人节约会邀约界面
local XUiWhiteValentineInvite = XLuaUiManager.Register(XLuaUi, "UiWhitedayInvite")

function XUiWhiteValentineInvite:OnAwake()
    XTool.InitUiObject(self)
    self.CharaManager = XDataCenter.WhiteValentineManager.GetCharaManager()
    self:InitMemberList()
    self:InitDropDown()
    self:InitButtons()
    self:OnDropDownValueChanged(0)
end

function XUiWhiteValentineInvite:InitMemberList()
    self.GridChara.gameObject:SetActiveEx(false)
    local XDTable = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenInviteMemberDynamicTable")
    self.CharaDynamicTable = XDTable.New(self, self.MemberList)
end

function XUiWhiteValentineInvite:InitDropDown()
    local attrs = XWhiteValentineConfig.GetAllWhiteValentineAttr()
    for id, attr in pairs(attrs) do
        self.DropDownSort.options[id].text = attr.Name
    end
    self.DropDownSort.onValueChanged:AddListener(function(value) self:OnDropDownValueChanged(value) end)
end

function XUiWhiteValentineInvite:InitButtons()
    self.BtnCancel.CallBack = function() self:OnBtnClose() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnClose() end
    self.BtnStartWork.CallBack = function() self:OnBtnInvite() end
end

function XUiWhiteValentineInvite:OnDropDownValueChanged(value)
    if value == 0 then
        local allChara = self.CharaManager:GetAllOutTeamChara()
        self.CharaDynamicTable:UpdateData(allChara)
    else
        local charaList = self.CharaManager:GetOutTeamCharaByAttrType(value)
        if charaList == nil or #charaList == 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineAttrCharaComplete"))
        end
        self.CharaDynamicTable:UpdateData(charaList)
    end
end

function XUiWhiteValentineInvite:OnBtnClose()
    self:Close()
end

function XUiWhiteValentineInvite:OnBtnInvite()
    if self.InviteChara then
        XDataCenter.WhiteValentineManager.InviteChara(self.InviteChara, function() self:OnBtnClose() end)
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineNoInviteChara"))
    end
end

function XUiWhiteValentineInvite:SetInviteChara(chara)
    self.InviteChara = chara
end