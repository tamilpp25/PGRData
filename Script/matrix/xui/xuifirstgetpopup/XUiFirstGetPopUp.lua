local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local tableRemove = table.remove

local AnimBegin = "AniFirstGetBegin"

local XUiFirstGetPopUp = XLuaUiManager.Register(XLuaUi, "UiFirstGetPopUp")

function XUiFirstGetPopUp:OnAwake()
    self:InitAutoScript()
end

function XUiFirstGetPopUp:OnStart(waitToShowList)
    self.WaitToShowList = waitToShowList
    self.GridCommon.gameObject:SetActive(false)
    self.PanelCharacter.gameObject:SetActive(false)
end

function XUiFirstGetPopUp:OnEnable()
    local data = tableRemove(self.WaitToShowList)
    if not data then
        self:Close()
        return
    end

    self:Refresh(data)

    -- local onEnd = function ()
    --     self:OnEnable()
    -- end

end

function XUiFirstGetPopUp:Refresh(data)
    self.TempateId = data.Id
    self.Type = data.Type

    if self.Type == XArrangeConfigs.Types.Character then
        local character = XMVCA.XCharacter:GetCharacter(self.TempateId)
        self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(self.TempateId)
        self.RImgCharacterQualityIcon:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(character.Quality))
        self.RImgCharacter:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(self.TempateId))
        self.PanelCharacter.gameObject:SetActive(true)
    elseif self.Type == XArrangeConfigs.Types.Weapon then
        self.CommonGrid = self.CommonGrid or XUiGridCommon.New(self, self.GridCommon)
        self.CommonGrid:Refresh(self.TempateId)
        self.TxtName.text = XMVCA.XEquip:GetEquipName(self.TempateId)
        self.GridCommon.gameObject:SetActive(true)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiFirstGetPopUp:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiFirstGetPopUp:AutoInitUi()
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent("Button")
    self.PanelFirstGet = self.Transform:Find("SafeAreaContentPane/PanelFirstGet")
    self.PanelCharacter = self.Transform:Find("SafeAreaContentPane/PanelFirstGet/PaneContent/PanelCharacter")
    self.RImgCharacterQualityIcon = self.Transform:Find("SafeAreaContentPane/PanelFirstGet/PaneContent/PanelCharacter/RImgCharacterQualityIcon"):GetComponent("RawImage")
    self.RImgCharacter = self.Transform:Find("SafeAreaContentPane/PanelFirstGet/PaneContent/PanelCharacter/RImgCharacter"):GetComponent("RawImage")
    self.GridCommon = self.Transform:Find("SafeAreaContentPane/PanelFirstGet/PaneContent/GridCommon")
    self.TxtName = self.Transform:Find("SafeAreaContentPane/PanelFirstGet/TxtName"):GetComponent("Text")
end

function XUiFirstGetPopUp:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto
function XUiFirstGetPopUp:OnBtnCloseClick()
    XUiHelper.StopAnimation(self, AnimBegin)

end