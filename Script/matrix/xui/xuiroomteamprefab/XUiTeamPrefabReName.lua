local XUiTeamPrefabReName = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabReName")

local CSXTextManagerGetText = CS.XTextManager.GetText
local MaxNameLength = CS.XGame.Config:GetInt("TeamPrefabNameLength")

function XUiTeamPrefabReName:OnAwake()
    self:AddListener()
end

function XUiTeamPrefabReName:OnStart(confirmCb, title, customMaxLen)
    self.ConfirmCb = confirmCb
    if title and self.Txt then
        self.Txt.text = title
    end
    if XTool.IsNumberValid(customMaxLen) then
        MaxNameLength = customMaxLen
    end
end

function XUiTeamPrefabReName:OnEnable()

end

function XUiTeamPrefabReName:OnDisable()

end

function XUiTeamPrefabReName:AddListener()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnNameCancel.CallBack = function()
        self:Close()
    end
    self.BtnNameSure.CallBack = function()
        self:OnBtnNameSure()
    end
end

function XUiTeamPrefabReName:OnBtnNameSure()
    local editName = string.gsub(self.InFSigm.text, "^%s*(.-)%s*$", "%1")

    if string.len(editName) > 0 then
        local utf8Count = self.InFSigm.textComponent.cachedTextGenerator.characterCount - 1
        if utf8Count > MaxNameLength then
            XUiManager.TipError(CSXTextManagerGetText("MaxNameLengthTips", MaxNameLength))
            return
        end
        self.ConfirmCb(editName, function()
            XUiManager.TipText("TeamPrefabRenameSuc")
            self:Close()
        end)
    else
        XUiManager.TipError(CSXTextManagerGetText("TeamPrefabWithoutName"))
    end
end