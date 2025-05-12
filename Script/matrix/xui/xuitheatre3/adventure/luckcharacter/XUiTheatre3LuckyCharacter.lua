---@class XUiTheatre3LuckyCharacter : XLuaUi
---@field CharGroup XUiButtonGroup
---@field _Control XTheatre3Control
local XUiTheatre3LuckyCharacter = XLuaUiManager.Register(XLuaUi, "UiTheatre3LuckyCharacter")

function XUiTheatre3LuckyCharacter:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3LuckyCharacter:OnStart()
    self:InitCharacter()
end

function XUiTheatre3LuckyCharacter:OnEnable()
    self.TxtTitle1.text = self._Control:GetClientConfigTxtByConvertLine("TxtLuckCharacterTitle1")
    self.TxtTitle2.text = self._Control:GetClientConfigTxtByConvertLine("TxtLuckCharacterTitle2")
    self:AddEventListener()
end

function XUiTheatre3LuckyCharacter:OnDisable()
    self:RemoveEventListener()
end

--region Ui - Character
function XUiTheatre3LuckyCharacter:InitCharacter()
    local XUiTheatre3GridLuckyCharacter = require("XUi/XUiTheatre3/Adventure/LuckCharacter/XUiTheatre3GridLuckyCharacter")
    self._BeSelectCharList = self._Control:GetAdventureLuckCharacterSelectList()
    self._BtnCharList = {
        self.BtnChar1,
        self.BtnChar2,
        self.BtnChar3,
    }
    ---@type XUiTheatre3GridLuckyCharacter[]
    self._CharGridList = {
        XUiTheatre3GridLuckyCharacter.New(self.BtnChar1.transform, self),
        XUiTheatre3GridLuckyCharacter.New(self.BtnChar2.transform, self), 
        XUiTheatre3GridLuckyCharacter.New(self.BtnChar3.transform, self),
    }
    for i, characterId in ipairs(self._BeSelectCharList) do
        self._CharGridList[i]:Refresh(characterId)
    end
    self.CharGroup:Init(self._BtnCharList, function(index) self:_SelectCharacter(index)  end)
    self.BtnCharacterSelect.gameObject:SetActiveEx(false)
end

function XUiTheatre3LuckyCharacter:_SelectCharacter(index)
    self.BtnCharacterSelect.gameObject:SetActiveEx(true)
    if self._CurSelectIndex == index then
        return
    end
    self._CurSelectIndex = index
end
--endregion

--region Ui - BtnListener
function XUiTheatre3LuckyCharacter:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnCharacterDetail, self.OnBtnCharacterDetail)
    self._Control:RegisterClickEvent(self, self.BtnCharacterSelect, self.OnBtnCharacterSelect)
end

function XUiTheatre3LuckyCharacter:OnBtnBackClick()
    self._Control:OpenTextTip(handler(self, self.Close), XUiHelper.ReadTextWithNewLineWithNotNumber("TipTitle"), XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EquipBackTip"))
end

function XUiTheatre3LuckyCharacter:OnBtnCharacterSelect()
    if not XTool.IsNumberValid(self._CurSelectIndex) then
        XUiManager.TipErrorWithKey("WhiteValentineNoSelectChara")
        return
    end
    self._Control:RequestSelectLuckCharacter(self._BeSelectCharList[self._CurSelectIndex])
end

function XUiTheatre3LuckyCharacter:OnBtnCharacterDetail()
    local characterId = self._BeSelectCharList[self._CurSelectIndex]
    if not XTool.IsNumberValid(characterId) then
        return
    end
    XLuaUiManager.Open("UiTheatre3RoleRoomDetail", 1, characterId, true)
end
--endregion

--region Event
function XUiTheatre3LuckyCharacter:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_SELECT_LUCK_CHARACTER, self.OnAfterSelect, self)
end

function XUiTheatre3LuckyCharacter:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_SELECT_LUCK_CHARACTER, self.OnAfterSelect, self)
end

function XUiTheatre3LuckyCharacter:OnAfterSelect()
    self._Control:CheckAndOpenAdventureNextStep(true, true)
end
--endregion

return XUiTheatre3LuckyCharacter