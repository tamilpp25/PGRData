--虚像地平线角色留言板
local XUiExpeditionGuesBook = XLuaUiManager.Register(XLuaUi, "UiExpeditionGuesBook")
local XUiExpeditionMessageItemList = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/MessageBoard/XUiExpeditionMessageItemList")

function XUiExpeditionGuesBook:OnAwake()
    XTool.InitUiObject(self)
    self.GridGuestbook.gameObject:SetActiveEx(false)
    self.MessageItemList = XUiExpeditionMessageItemList.New(self.PanelSelectList, self)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnClose)
    self:RegisterClickEvent(self.BtnSend, self.OnBtnSend)
end

function XUiExpeditionGuesBook:OnStart(eCharaCfg, hadCommented)
    self.HadCommented = hadCommented
    self:RefreshData(eCharaCfg)
end

function XUiExpeditionGuesBook:OnEnable()
    self.MessageItemList:OnEnable()
end

function XUiExpeditionGuesBook:OnBtnSend()
    if not self.ECharaCfg then return end
    if self.HadCommented then
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionHaveCommented"))
    end
    XDataCenter.ExpeditionManager.SendComment(self.ECharaCfg.Id, self.InputFieldMsg.text)
    self:ResetInput()
end

function XUiExpeditionGuesBook:OnBtnClose()
    self.MessageItemList:OnDisable()
    self:Close()
end

function XUiExpeditionGuesBook:RefreshData(eCharaCfg)
    self.ECharaCfg = eCharaCfg
    self.EBaseCharaCfg = XExpeditionConfig.GetBaseCharacterCfgById(eCharaCfg.BaseId)
    self.CharacterId = self.EBaseCharaCfg.CharacterId
    self:RefreshRoleInfo()
    self:RefreshMessageList()
end

function XUiExpeditionGuesBook:RefreshRoleInfo()
    if not self.ECharaCfg then return end
    local jobType = XRobotManager.GetRobotJobType(self.ECharaCfg.RobotId)
    self.RImgRole:SetRawImage(XDataCenter.CharacterManager.GetCharHalfBodyImage(self.CharacterId))
    self.RImgIconCharacter:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(jobType))
    self.TxtName.text = XCharacterConfigs.GetCharacterName(self.CharacterId)
    self.TxtNameOther.text = XCharacterConfigs.GetCharacterTradeName(self.CharacterId)
    local elementList = XExpeditionConfig.GetCharacterElementByBaseId(self.ECharaCfg.BaseId)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.transform.parent.gameObject:SetActive(true)
            local elementConfig = XExpeditionConfig.GetCharacterElementById(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.transform.parent.gameObject:SetActive(false)
        end
    end
end

function XUiExpeditionGuesBook:RefreshMessageList()
    self.MessageItemList:UpdateData(self.ECharaCfg.Id)
end

function XUiExpeditionGuesBook:ResetInput()
    self.InputFieldMsg.text = ""
end