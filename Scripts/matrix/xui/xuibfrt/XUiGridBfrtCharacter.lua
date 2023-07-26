local XUiGridBfrtCharacter = XClass(nil, "XUiGridBfrtCharacter")

function XUiGridBfrtCharacter:Ctor(rootUi, ui, character)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
    XTool.InitUiObject(self)
    self:InitComponentState()
    self:Refresh(character)
end

function XUiGridBfrtCharacter:InitComponentState()
    self.PanelTeam.gameObject:SetActiveEx(false)
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiGridBfrtCharacter:Refresh(character)
    self:UpdateViewData(character)
    self:UpdateGameObject()
    self:UpdateCharacterInfo()
end

function XUiGridBfrtCharacter:UpdateViewData(character)
    self.Character = character
end

function XUiGridBfrtCharacter:UpdateGameObject()
    self.GameObject.name = self.Character.Id
    self.GameObject:SetActiveEx(true)
end

function XUiGridBfrtCharacter:UpdateCharacterInfo()
    self.TxtFight.text = math.floor(self.Character.Ability)
    self.TxtLevel.text = self.Character.Level
    self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.Character.Id))
    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(self.Character.Quality))

    if self.PanelCharElement then
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(self.Character.Id)
        local elementList = detailConfig.ObtainElementList
        for i = 1, 3 do
            local rImg = self["RImgCharElement" .. i]
            if elementList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
                rImg:SetRawImage(elementConfig.Icon)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiGridBfrtCharacter:SetInTeam(inEchelonIndex, inEchelonType)
    if inEchelonIndex then
        if inEchelonType == XDataCenter.BfrtManager.EchelonType.Fight then
            self.TxtEchelonIndex.text = CS.XTextManager.GetText("BfrtFightEchelonTitleSimple", inEchelonIndex)
            self.PanelTeam.gameObject:SetActiveEx(true)
            self.PanelTeamSupport.gameObject:SetActiveEx(false)
        elseif inEchelonType == XDataCenter.BfrtManager.EchelonType.Logistics then
            self.TxtEchelonIndexA.text = CS.XTextManager.GetText("BfrtLogisticEchelonTitleSimple", inEchelonIndex)
            self.PanelTeamSupport.gameObject:SetActiveEx(true)
            self.PanelTeam.gameObject:SetActiveEx(false)
        end
    else
        self.PanelTeam.gameObject:SetActiveEx(false)
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end
end

function XUiGridBfrtCharacter:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridBfrtCharacter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridBfrtCharacter:AutoInitUi()
    self.PanelSelected = self.Transform:Find("PanelSelected")
    self.TxtFight = self.Transform:Find("PaneFight/TxtFight"):GetComponent("Text")
    self.TxtLevel = self.Transform:Find("PaneLevel/TxtLevel"):GetComponent("Text")
    self.RImgQuality = self.Transform:Find("RImgQuality"):GetComponent("RawImage")
    self.RImgHeadIcon = self.Transform:Find("PaneHead/RImgHeadIcon"):GetComponent("RawImage")
    self.BtnCharacter = self.Transform:Find("BtnCharacter"):GetComponent("Button")
    self.PanelTeam = self.Transform:Find("PanelTeam")
    self.TxtEchelonIndex = self.Transform:Find("PanelTeam/TxtEchelonIndex"):GetComponent("Text")
    self.PanelTeamSupport = self.Transform:Find("PanelTeamSupport")
    self.TxtEchelonIndexA = self.Transform:Find("PanelTeamSupport/TxtEchelonIndex"):GetComponent("Text")
end

function XUiGridBfrtCharacter:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridBfrtCharacter:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridBfrtCharacter:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridBfrtCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnCharacter, self.OnBtnCharacterClick)
end
-- auto
function XUiGridBfrtCharacter:OnBtnCharacterClick()
    self.RootUi:OnSelectCharacter(self.Character.Id)
end

return XUiGridBfrtCharacter