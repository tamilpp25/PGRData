local XUiEquipResonanceSelectCharacterV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectCharacterV2P6")

function XUiEquipResonanceSelectCharacterV2P6:OnAwake()
    self:InitAutoScript()
    self.GridCharacter.gameObject:SetActive(false)
end

function XUiEquipResonanceSelectCharacterV2P6:OnStart(equipId, confirmCb)
    self.EquipId = equipId
    self.ConfirmCb = confirmCb
end

function XUiEquipResonanceSelectCharacterV2P6:OnEnable(equipId)
    self.EquipId = equipId or self.EquipId
    self.SelectCharacterId = nil
    self:InitCharacterList()
    self:RefreshList()
end

function XUiEquipResonanceSelectCharacterV2P6:InitCharacterList()
    self.CharacterGridDic = self.CharacterGridDic or { }
    local clickCallback = function(character)
        self.SelectCharacterId = character.Id
        self:RefreshList(self.SelectCharacterId)
    end

    for i, v in pairs(self.CharacterGridDic) do
        v.GameObject:SetActiveEx(false)
    end
    local noCharacter = true
    local canResonanceCharacterList = self._Control:GetCanResonanceCharacterList(self.EquipId)
    for _, character in pairs(canResonanceCharacterList) do
        if not self.CharacterGridDic[character.Id] then
            local item = CS.UnityEngine.Object.Instantiate(self.GridCharacter)
            local grid = XUiGridCharacter.New(item, self, character, clickCallback)
            grid.GameObject:SetActive(true)
            grid.Transform:SetParent(self.PanelCharacterContent, false)
            self.CharacterGridDic[character.Id] = grid
        else
            local grid = self.CharacterGridDic[character.Id]
            grid.GameObject:SetActive(true)
            grid:UpdateGrid(character)
        end
        noCharacter = false
    end
    self.PanelNoCharacter.gameObject:SetActive(noCharacter)
end

function XUiEquipResonanceSelectCharacterV2P6:RefreshList(selectCharacterId)
    self.BtnConfirm:SetDisable(not selectCharacterId, true)

    for characterId, characterGridDic in pairs(self.CharacterGridDic) do
        characterGridDic:UpdateGrid(nil, selectCharacterId)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiEquipResonanceSelectCharacterV2P6:InitAutoScript()
    self:AutoAddListener()
end

function XUiEquipResonanceSelectCharacterV2P6:AutoAddListener()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.Btncancel, self.OnBtnCloseClick)
end
-- auto
function XUiEquipResonanceSelectCharacterV2P6:OnBtnCloseClick()
    self:Close()
end

function XUiEquipResonanceSelectCharacterV2P6:OnBtnConfirmClick()
    if self.ConfirmCb and self.SelectCharacterId then
        self.ConfirmCb(self.SelectCharacterId)
        self:Close()
    end
end