local XUiNierCharacterSel = XLuaUiManager.Register(XLuaUi, "UiNierCharacterSel")

local MAX_CHAR_COUNT = 3
function XUiNierCharacterSel:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.BtnCharList = {}
    for index = 1, MAX_CHAR_COUNT do
        local btn = self["Btn"..index]
        if btn then
            self.BtnCharList[index] = btn
            btn.CallBack = function() self:OnRealBtnCharClick(index) end
        end
    end
end

function XUiNierCharacterSel:OnStart()
    local uiModelRoot = self.UiModelGo.transform
    self.NierCharacters = XDataCenter.NieRManager.GetCurDevelopCharacterIds()
    self.CharacterList = {}
    for _, characterId in ipairs(self.NierCharacters) do
        local nieRCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(characterId)
        if nieRCharacter then
            self.CharacterList[nieRCharacter:GetNieRClientPos()] = nieRCharacter
        end
    end
    self:AddRedPointEvent()
end

function XUiNierCharacterSel:OnEnable()
    self:InitPanelNierCharacter()
end

function XUiNierCharacterSel:OnDisable()

end

function XUiNierCharacterSel:OnDestroy()

end


function XUiNierCharacterSel:InitPanelNierCharacter()
    local sortList = {}
    for key, nieRCharacter in pairs(self.CharacterList) do
        local characterBtn = self.BtnCharList[key]
        local charName = nieRCharacter:GetNieRCharName()
        characterBtn:SetNameByGroup(0, charName)
        characterBtn:SetRawImage(nieRCharacter:GetNieRCharacterIcon())
        local condit, desc = nieRCharacter:CheckNieRCharacterCondition()
        if condit then
            local charLevel = "Lv." .. nieRCharacter:GetNieRCharacterLevel()
            characterBtn:SetNameByGroup(1, charLevel)
            characterBtn:SetDisable(false, true)
            if nieRCharacter:CheckNieRCharacterMaxLevel() then
                self["BtnMAX"..key].gameObject:SetActiveEx(true)
            else
                self["BtnMAX"..key].gameObject:SetActiveEx(false)
            end
        else
            characterBtn:SetNameByGroup(2, desc)
            characterBtn:SetDisable(true, true)
        end
        local tmp = {}
        tmp.key = key
        tmp.condit = condit
        table.insert(sortList, tmp)
    end
    local sortRule = {
        [2] = 1,
        [1] = 2,
        [3] = 3
    }
    table.sort(sortList, function(a, b)
        return sortRule[a.key] < sortRule[b.key]
    end)
    for __, info in ipairs(sortList) do
        local characterBtn = self.BtnCharList[info.key]
        if info.condit then
            characterBtn.transform:SetAsLastSibling()
        end
    end
end
--添加点事件
function XUiNierCharacterSel:AddRedPointEvent()
    if self.CharacterList[1] then
        XRedPointManager.AddRedPointEvent(self.BtnCharList[1], self.RefreshCharRed1, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = self.CharacterList[1]:GetNieRCharacterId(), IsInfor = true, IsTeach = true})
    end
    if self.CharacterList[2] then
        XRedPointManager.AddRedPointEvent(self.BtnCharList[2], self.RefreshCharRed2, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = self.CharacterList[2]:GetNieRCharacterId(), IsInfor = true, IsTeach = true})
    end
    if self.CharacterList[3] then
        XRedPointManager.AddRedPointEvent(self.BtnCharList[3], self.RefreshCharRed3, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = self.CharacterList[3]:GetNieRCharacterId(), IsInfor = true, IsTeach = true})
    end
    
end

--按钮红点
function XUiNierCharacterSel:RefreshCharRed1(count)
    self.BtnRed1.gameObject:SetActiveEx(count >= 0)
end

--按钮红点
function XUiNierCharacterSel:RefreshCharRed2(count)
    self.BtnRed2.gameObject:SetActiveEx(count >= 0)
end

--按钮红点
function XUiNierCharacterSel:RefreshCharRed3(count)
    self.BtnRed3.gameObject:SetActiveEx(count >= 0)
end

function XUiNierCharacterSel:OnBtnBackClick()
    self:Close()
end

function XUiNierCharacterSel:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNierCharacterSel:OnRealBtnCharClick(index)
    if not self.CharacterList[index] then
        return 
    end
    local nieRCharacter = self.CharacterList[index]
    local condit, desc = nieRCharacter:CheckNieRCharacterCondition()
    if condit then
        XDataCenter.NieRManager.SetSelCharacterId(nieRCharacter:GetNieRCharacterId())
        XLuaUiManager.Open("UiNierCharacter")
    else
        XUiManager.TipMsg(desc)
    end
end