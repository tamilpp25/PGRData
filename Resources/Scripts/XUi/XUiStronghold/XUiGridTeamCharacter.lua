local handler = handler
local tableInsert = table.insert
local tableRemove = table.remove
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiGridTeamCharacter = XClass(nil, "XUiGridTeamCharacter")

function XUiGridTeamCharacter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
end

function XUiGridTeamCharacter:Refresh(characterId)
    self.CharacterId = characterId

    if not XTool.IsNumberValid(characterId) then
        self.ImgTianJia.gameObject:SetActiveEx(true)
        self.PanelTouXiang.gameObject:SetActiveEx(false)
    else
        local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId)
        self.ImgTouXiang:SetRawImage(icon)

        self.TxtAbility.text = XDataCenter.CharacterManager.GetCharacterAbilityById(characterId)

        self.ImgTianJia.gameObject:SetActiveEx(false)
        self.PanelTouXiang.gameObject:SetActiveEx(true)
    end
end

function XUiGridTeamCharacter:OnClickBtnClick()
    local characterId = nil
    local supportData = {
        OldCharacterId = self.CharacterId,
        CanSupportCancel = true,
        CheckLockSupportCb = function(characterId)
            return XDataCenter.StrongholdManager.CheckInTeamList(characterId)
        end,
        CheckInSupportCb = function(characterId)
            return XDataCenter.StrongholdManager.CheckInElectricTeam(characterId)
        end,
        GetCharacters = function(characterType)
            return XDataCenter.StrongholdManager.GetCanElectricCharacters(characterType)
        end,
        SetCharacterCb = function(characterId, cb, oldCharacterId)
            if XDataCenter.StrongholdManager.CheckInElectricTeam(characterId) then
                XUiManager.TipText("StrongholdElectricSupportInElectricTeam")
                return
            end

            if XDataCenter.StrongholdManager.CheckInTeamList(characterId) then
                XUiManager.TipText("StrongholdElectricSupportInTeamList")
                return
            end

            local characterIds = XDataCenter.StrongholdManager.GetElectricCharacterIds()
            if XDataCenter.StrongholdManager.CheckElectricMaxNum(characterId) then
                if oldCharacterId then
                    for index, inCharacterId in ipairs(characterIds) do
                        if inCharacterId == oldCharacterId then
                            tableRemove(characterIds, index)
                            break
                        end
                    end
                else
                    XUiManager.TipText("StrongholdElectricTeamMaxNum")
                    return
                end
            end
            tableInsert(characterIds, characterId)

            XDataCenter.StrongholdManager.SetStrongholdElectricTeamRequest(characterIds, cb)

            return true
        end,
        CancelCharacterCb = function(characterId, cb)
            local callFunc = function()
                local characterIds = XDataCenter.StrongholdManager.GetElectricCharacterIds()
                for index, inCharacterId in pairs(characterIds) do
                    if inCharacterId == characterId then
                        tableRemove(characterIds, index)
                        break
                    end
                end
                XDataCenter.StrongholdManager.SetStrongholdElectricTeamRequest(characterIds)

                XLuaUiManager.Close("UiCharacter")
            end

            if XDataCenter.StrongholdManager.CheckElectricOverLimit(characterId) then
                local title = CSXTextManagerGetText("ElectricTeamCancelTipTitle")
                local content = CSXTextManagerGetText("ElectricTeamCancelTipContent")
                XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
            else
                callFunc()
            end

        end,
    }
    XLuaUiManager.Open("UiCharacter", characterId, nil, nil, nil, nil, nil, supportData)
end

return XUiGridTeamCharacter