local XUiGridCharacterNew = XClass(nil, "XUiGridCharacterNew")

function XUiGridCharacterNew:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.RectTransform = ui:GetComponent("RectTransform")
    self:InitAutoScript()
end

function XUiGridCharacterNew:Init(rootUi, isShowStamina)
    self.RootUi = rootUi
    self.IsShowStamina = isShowStamina
end
-- auto
-- Automatic generation of code, forbid to edit
function XUiGridCharacterNew:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()

    if self.PanelSupportLock then
        self.PanelSupportLock.gameObject:SetActiveEx(false)
    end

    if self.PanelSupportIn then
        self.PanelSupportIn.gameObject:SetActiveEx(false)
    end

    if self.PanelHighPriority then
        self.PanelHighPriority.gameObject:SetActiveEx(false)
    end
end

function XUiGridCharacterNew:AutoInitUi()
    self.PanelHead = self.Transform:Find("PanelHead")
    self.RImgHeadIcon = self.Transform:Find("PanelHead/RImgHeadIcon"):GetComponent("RawImage")
    self.PanelLevel = self.Transform:Find("PanelLevel")
    self.TxtLevel = self.Transform:Find("PanelLevel/TxtLevel"):GetComponent("Text")
    self.PanelGrade = self.Transform:Find("PanelGrade")
    self.RImgGrade = self.Transform:Find("PanelGrade/RImgGrade"):GetComponent("RawImage")
    self.RImgQuality = self.Transform:Find("RImgQuality"):GetComponent("RawImage")
    self.PanelFragment = self.Transform:Find("PanelFragment")
    self.TxtCurCount = self.Transform:Find("PanelFragment/TxtCurCount"):GetComponent("Text")
    self.TxtNeedCount = self.Transform:Find("PanelFragment/TxtNeedCount"):GetComponent("Text")
    self.ImgLock = self.Transform:Find("ImgLock"):GetComponent("Image")
    self.BtnCharacter = self.Transform:Find("BtnCharacter"):GetComponent("Button")
    self.ImgInTeam = self.Transform:Find("ImgInTeam"):GetComponent("Image")
    self.PanelSelected = self.Transform:Find("PanelSelected")
    self.ImgSelected = self.Transform:Find("PanelSelected/ImgSelected"):GetComponent("Image")
    self.ImgRedPoint = self.Transform:Find("ImgRedPoint"):GetComponent("Image")
    self.TxtCur = self.Transform:Find("TxtCur"):GetComponent("Text")
    self.IconEquipGuide = self.Transform:Find("IconEquipGuide")
end

function XUiGridCharacterNew:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnCharacter, function() self:OnBtnCharacterClick() end)
end

function XUiGridCharacterNew:OnBtnCharacterClick()

end

function XUiGridCharacterNew:UpdateOwnInfo()
    self.TxtLevel.text = self.Character.Level
    self.RImgGrade:SetRawImage(XCharacterConfigs.GetCharGradeIcon(self.Character.Id, self.Character.Grade or XDataCenter.CharacterManager.GetCharacterGrade(self.Character.Id)))
    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(XDataCenter.CharacterManager.GetCharacterQuality(self.Character.Id)))
    self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.Character.Id))
    if self.IconEquipGuide then
        self.IconEquipGuide.gameObject:SetActiveEx(XDataCenter.EquipGuideManager.IsEquipGuideCharacter(self.Character.Id))
    end
end

function XUiGridCharacterNew:UpdateUnOwnInfo()
    local characterId = self.Character.Id
    self.TxtCurCount.text = XDataCenter.CharacterManager.GetCharUnlockFragment(characterId)
    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    self.TxtNeedCount.text = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId))
    if self.IconEquipGuide then
        self.IconEquipGuide.gameObject:SetActiveEx(false)
    end
    
end

function XUiGridCharacterNew:UpdateGrid(character)
    if character then
        self.Character = character
    end

    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(self.Character.Id)
    XRedPointManager.CheckOnce(self.OnCheckCharacterRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER }, self.Character.Id)
    self.PanelLevel.gameObject:SetActiveEx(isOwn)
    self.PanelGrade.gameObject:SetActiveEx(isOwn)
    self.RImgQuality.gameObject:SetActiveEx(isOwn)
    self.ImgLock.gameObject:SetActiveEx(not isOwn)
    self.PanelFragment.gameObject:SetActiveEx(not isOwn)

    if isOwn then
        self:UpdateOwnInfo()
    else
        self:UpdateUnOwnInfo()
    end
end

function XUiGridCharacterNew:OnCheckCharacterRedPoint(count)
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
    end
end

function XUiGridCharacterNew:SetSelect(isSelect)
    self.ImgSelected.gameObject:SetActiveEx(isSelect)
    if isSelect then
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_TOWER_CONDITION_LISTENING, XFubenCharacterTowerConfigs.ListeningType.Character, { CharacterId = self.Character.Id })
    end
end

function XUiGridCharacterNew:HideRedPoint()
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(false)
    end
end

function XUiGridCharacterNew:SetInTeam(isInTeam)
    if self.ImgInTeam then
        self.ImgInTeam.gameObject:SetActiveEx(isInTeam)
    end
end

function XUiGridCharacterNew:UpdateSupport(supportData)
    if XTool.IsTableEmpty(supportData) then return end

    self:SetInTeam(false)

    local characterId = self.Character.Id

    if self.PanelSupportLock then
        local lockSupport = supportData.CheckLockSupportCb and supportData.CheckLockSupportCb(characterId)
        self.PanelSupportLock.gameObject:SetActiveEx(lockSupport)
    end

    if self.PanelSupportIn then
        local showSupport = supportData.CheckInSupportCb(characterId)
        self.PanelSupportIn.gameObject:SetActiveEx(showSupport)
    end

    if self.PanelHighPriority and supportData.CheckHighPriority then
        local showHighPriority = false
        local icon = false
        if supportData.CheckHighPriority then
            showHighPriority, icon = supportData.CheckHighPriority(characterId)
        end
        self.PanelHighPriority.gameObject:SetActiveEx(showHighPriority)
        if icon then
            local tran = self.PanelHighPriority.transform:Find("UpTag/RImgGuildWarUP")
            local rawImage = tran:GetComponent("RawImage")
            rawImage:SetRawImage(icon)
        end
    end
end

function XUiGridCharacterNew:SetCurSignState(state)
    self.TxtCur.gameObject:SetActiveEx(state)
end

function XUiGridCharacterNew:Reset()
    self:SetSelect(false)
    self:SetInTeam(false)
    self.TxtCur.gameObject:SetActiveEx(false)
end

function XUiGridCharacterNew:SetPosition(x, y)
    self.RectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
end

return XUiGridCharacterNew